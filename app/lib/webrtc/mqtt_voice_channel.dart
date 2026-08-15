import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:core_protocol/core_protocol.dart';

/// Canal de voz via MQTT — fallback automático quando o WebRTC P2P falha por CGNAT.
///
/// Arquitetura:
///   1. Captura áudio do microfone como stream PCM (16kHz, 16-bit, mono)
///   2. Aplica noise gate para não publicar silêncio
///   3. Publica chunks de ~20ms no tópico MQTT do canal com QoS 0
///   4. Recebe chunks dos peers via tópico MQTT e reproduz com jitter buffer
class MqttVoiceChannel {
  final String channelId;
  final String localPeerId;
  final ClmRelay relay;
  final String? aesKey;
  final void Function() onStateChanged;

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _recordSub;

  final Map<String, AudioPlayer> _players = {};
  Timer? _localSpeakingTimer;
  final Map<String, List<Uint8List>> _jitterBuffers = {};
  static const int _jitterFrames = 2; // 2 × 100ms = 200ms de buffer
  
  final List<int> _audioBuffer = [];
  static const int _bytesPer100ms = 3200; // 16kHz * 2 bytes * 0.1s

  final Set<String> _activePeers = {};
  bool _isActive = false;
  bool get isActive => _isActive;

  bool _isMicMuted = false;

  final Map<String, bool> speakingStates = {};

  static const int _sampleRate = 16000;
  static const double _noiseGateThreshold = 0.008;

  MqttVoiceChannel({
    required this.channelId,
    required this.localPeerId,
    required this.relay,
    this.aesKey,
    required this.onStateChanged,
  });

  /// Inicia o canal: começa a capturar e publicar áudio, e escuta os peers.
  Future<void> start(List<String> peerIds) async {
    if (_isActive) return;
    _isActive = true;
    debugPrint('[MqttVoice] Iniciando para channelId=$channelId peers=$peerIds');
    for (final peerId in peerIds) {
      _addPeer(peerId);
    }
    await _startCapture();
  }

  /// Adiciona um novo peer ao canal em tempo real.
  void addPeer(String peerId) {
    if (!_isActive || _activePeers.contains(peerId)) return;
    _addPeer(peerId);
  }

  void _addPeer(String peerId) {
    _activePeers.add(peerId);
    relay.listenToVoicePeer(channelId, peerId);
    _players[peerId] = AudioPlayer();
    _jitterBuffers[peerId] = [];
    debugPrint('[MqttVoice] Peer adicionado: $peerId');
  }

  /// Remove um peer do canal.
  void removePeer(String peerId) {
    _activePeers.remove(peerId);
    relay.unlistenVoicePeer(channelId, peerId);
    _players[peerId]?.dispose();
    _players.remove(peerId);
    _jitterBuffers.remove(peerId);
    speakingStates.remove(peerId);
  }

  /// Processa chunk de áudio recebido via MQTT de um peer.
  void handleReceivedChunk(String senderId, Uint8List encryptedData) async {
    if (!_isActive || !_activePeers.contains(senderId)) return;

    var audioData = encryptedData;
    if (aesKey != null) {
      final decrypted = await ClmCypher.decryptPayload(encryptedData, aesKey!);
      if (decrypted == null) return; // Pacote inválido ou chave errada
      audioData = decrypted;
    }

    final amplitude = _computeAmplitude(audioData);
    final isSpeaking = amplitude > _noiseGateThreshold;
    if (speakingStates[senderId] != isSpeaking) {
      speakingStates[senderId] = isSpeaking;
      onStateChanged();
    }

    if (!isSpeaking) return;

    final buffer = _jitterBuffers[senderId];
    if (buffer == null) return;
    buffer.add(audioData);

    if (buffer.length >= _jitterFrames) {
      _flushJitterBuffer(senderId);
    }
  }

  void _flushJitterBuffer(String peerId) {
    final buffer = _jitterBuffers[peerId];
    final player = _players[peerId];
    if (buffer == null || player == null || buffer.isEmpty) return;

    final combined = _concatBytes(buffer);
    buffer.clear();

    final wav = _pcmToWav(combined);
    player.play(BytesSource(wav), volume: 1.0);
  }

  Future<void> _startCapture() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('[MqttVoice] Sem permissão de microfone');
        return;
      }

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
          echoCancel: true,      // AEC - elimina eco do alto-falante
          noiseSuppress: true,   // Supressão de ruído ambiente
          autoGain: true,        // Ganho automático de volume
        ),
      );

      _recordSub = stream.listen((data) {
        if (!_isActive || _isMicMuted) return;

        _audioBuffer.addAll(data);
        if (_audioBuffer.length < _bytesPer100ms) return; // Acumula até 100ms

        final chunkToProcess = Uint8List.fromList(_audioBuffer);
        _audioBuffer.clear();

        final amplitude = _computeAmplitude(chunkToProcess);
        if (amplitude < _noiseGateThreshold) return; // Noise gate
        
        // Atualiza estado local falando (com debounce)
        if (speakingStates[localPeerId] != true) {
          speakingStates[localPeerId] = true;
          onStateChanged();
        }
        _localSpeakingTimer?.cancel();
        _localSpeakingTimer = Timer(const Duration(milliseconds: 300), () {
          if (speakingStates[localPeerId] == true) {
            speakingStates[localPeerId] = false;
            onStateChanged();
          }
        });

        // Encripta antes de publicar
        if (aesKey != null) {
          ClmCypher.encryptPayload(chunkToProcess, aesKey!).then((encrypted) {
            if (_isActive) {
               relay.publishVoiceChunk(channelId, localPeerId, encrypted);
               // Log para verificação manual de que a criptografia está rolando (tamanho normal PCM é ~3200 bytes, encriptado vai ser maior/diferente e binário ilegível)
               // debugPrint('[MqttVoice] Enviando chunk E2EE: ${encrypted.length} bytes');
            }
          });
        } else {
          relay.publishVoiceChunk(channelId, localPeerId, chunkToProcess);
        }
      });

      debugPrint('[MqttVoice] Captura iniciada: PCM ${_sampleRate}Hz 16-bit mono');
    } catch (e) {
      debugPrint('[MqttVoice] Erro ao iniciar captura: $e');
    }
  }

  void setMicMuted(bool muted) {
    _isMicMuted = muted;
  }

  /// Amplitude RMS normalizada do PCM 16-bit (0.0 a 1.0)
  double _computeAmplitude(Uint8List data) {
    if (data.length < 2) return 0.0;
    double sumSq = 0.0;
    final view = data.buffer.asByteData(data.offsetInBytes, data.lengthInBytes);
    final count = data.length ~/ 2;
    for (int i = 0; i < count; i++) {
      final sample = view.getInt16(i * 2, Endian.little) / 32768.0;
      sumSq += sample * sample;
    }
    return count > 0 ? (sumSq / count) : 0.0;
  }

  Uint8List _concatBytes(List<Uint8List> chunks) {
    final total = chunks.fold<int>(0, (s, c) => s + c.length);
    final result = Uint8List(total);
    int offset = 0;
    for (final chunk in chunks) {
      result.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return result;
  }

  /// Converte PCM bruto para WAV — o AudioPlayer exige o header WAV.
  Uint8List _pcmToWav(Uint8List pcm) {
    const channels = 1;
    const bitsPerSample = 16;
    final byteRate = _sampleRate * channels * bitsPerSample ~/ 8;
    const blockAlign = channels * bitsPerSample ~/ 8;
    final dataSize = pcm.length;
    final header = ByteData(44);

    void writeStr(int offset, String s) {
      for (int i = 0; i < s.length; i++) {
        header.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeStr(0, 'RIFF');
    header.setUint32(4, 36 + dataSize, Endian.little);
    writeStr(8, 'WAVE');
    writeStr(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);   // PCM
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, _sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    writeStr(36, 'data');
    header.setUint32(40, dataSize, Endian.little);

    final result = Uint8List(44 + dataSize);
    result.setRange(0, 44, header.buffer.asUint8List());
    result.setRange(44, 44 + dataSize, pcm);
    return result;
  }

  /// Para o canal — libera microfone e cancela inscrições.
  Future<void> stop() async {
    if (!_isActive) return;
    _isActive = false;

    await _recordSub?.cancel();
    _recordSub = null;

    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }

    for (final peerId in _activePeers.toList()) {
      relay.unlistenVoicePeer(channelId, peerId);
      await _players[peerId]?.dispose();
    }

    _players.clear();
    _jitterBuffers.clear();
    _activePeers.clear();
    speakingStates.clear();
    _localSpeakingTimer?.cancel();

    debugPrint('[MqttVoice] Canal MQTT encerrado.');
  }
}
