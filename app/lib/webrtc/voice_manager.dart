import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:core_protocol/core_protocol.dart';
import 'mqtt_voice_channel.dart';
import 'topology_manager.dart';

enum VoiceConnectionType { connecting, webrtcP2p, mqttRelay }

/// Gerencia o ciclo completo de conexões WebRTC P2P para chamadas de voz.
/// Opera em Topologia Mesh: todos os membros do canal se conectam entre si.
class VoiceManager {
  /// PubKey do usuário local
  final String localPeerId;

  /// Callback para enviar sinais de sinalização pela rede MQTT
  final Future<void> Function(String targetPeerId, WebrtcSignal signal)
  onSendSignal;

  /// Callback para notificar a UI sobre mudanças de estado
  final void Function() onStateChanged;

  /// Conexões WebRTC abertas: peerPubKey → RTCPeerConnection
  final Map<String, RTCPeerConnection> _connections = {};

  /// Renderers para Web: chaveados pelo track.id para suportar múltiplas tracks simultâneas (SFU)
  final Map<String, RTCVideoRenderer> _renderers = {};

  /// Tracks remotas recebidas (para forwarding SFU a novos peers)
  final Map<String, MediaStreamTrack> _remoteTracks = {};

  /// Estado de conexão de cada peer para diagnóstico (P2P vs MQTT)
  final Map<String, VoiceConnectionType> peerConnectionTypes = {};

  /// Fila de candidatos ICE que chegaram antes do RemoteDescription
  final Map<String, List<RTCIceCandidate>> _queuedCandidates = {};

  /// Mapa que diz se o peer está falando no momento
  final Map<String, bool> speakingStates = {};

  Timer? _statsTimer;

  // --- Topology Manager (Mesh <-> SFU) ---
  TopologyManager? topologyManager;

  /// IDs dos Supernodes atualmente eleitos (vazio no modo Mesh)
  List<String> _supernodeIds = [];
  List<String> get supernodeIds => List.unmodifiable(_supernodeIds);

  /// Topologia atual
  CallTopology _callTopology = CallTopology.fullMesh;
  CallTopology get callTopology => _callTopology;

  /// Indica se o peer local é um Supernode
  bool get isLocalSupernode => _supernodeIds.contains(localPeerId);

  // --- MQTT Voice Relay (fallback quando ICE falha) ---

  /// Canal de voz MQTT (ativo somente quando WebRTC não consegue conectar)
  MqttVoiceChannel? _mqttVoice;

  /// Relay MQTT — injetado pelo AppState
  ClmRelay? mqttRelay;

  /// Canal atual — injetado pelo AppState no momento do join
  String? currentChannelId;
  String? currentAesKey;

  /// Timers de fallback por peer: se ICE não conectar em 6s, ativa MQTT
  final Map<String, Timer> _iceFailureTimers = {};

  /// Stream de áudio local do microfone
  MediaStream? _localStream;

  bool _isInCall = false;
  bool get isInCall => _isInCall;

  bool _isMicMuted = false;
  bool get isMicMuted => _isMicMuted;

  bool _isSpeakerMuted = false;
  bool get isSpeakerMuted => _isSpeakerMuted;

  /// Configuração ICE com múltiplas camadas de fallback:
  /// 1. IPv6 Host (automático pelo WebRTC)
  /// 2. STUN Google + Cloudflare (Holepunching para IPv4/NAT moderado)
  /// 3. TURN público gratuito (fallback para CGNAT simétrico rígido)
  static const _iceConfiguration = {
    'iceServers': [
      // STUN servers - tentativa de Holepunching direto
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun.cloudflare.com:3478'},
      // TURN server público (fallback para CGNAT simétrico)
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
    ],
    'iceTransportPolicy': 'all', // Tenta tudo: host, srflx, relay
    'sdpSemantics': 'unified-plan',
  };

  // Configurações de áudio controladas pelo usuário
  bool echoCancellation;
  bool noiseSuppression;
  bool autoGainControl;

  VoiceManager({
    required this.localPeerId,
    required this.onSendSignal,
    required this.onStateChanged,
    this.echoCancellation = true,
    this.noiseSuppression = true,
    this.autoGainControl = true,
  });

  /// Entra na chamada: captura o microfone e prepara para receber conexões.
  Future<void> joinCall() async {
    if (_isInCall) return;
    try {
      // Configura o AudioManager do Android para modo VoIP
      // Isso faz o sistema usar STREAM_VOICE_CALL (volume de chamada)
      // em vez de STREAM_MUSIC (volume de mídia), igual ao WhatsApp/Discord
      if (!kIsWeb) {
        await Helper.setAndroidAudioConfiguration(
          AndroidAudioConfiguration.communication,
        );
        Helper.setSpeakerphoneOn(true);
      }

      final mediaConstraints = {
        'audio': {
          'echoCancellation': echoCancellation,
          'noiseSuppression': noiseSuppression,
          'autoGainControl': autoGainControl,
        },
        'video': false,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(
        mediaConstraints,
      );
      _isInCall = true;
      _isMicMuted = false;
      _isSpeakerMuted = false;

      // Inicia monitoramento de nível de voz para efeito Neon
      _startAudioLevelMonitoring();

      debugPrint(
        '[VoiceManager] Microfone capturado. Em call. Modo VoIP ativo.',
      );
      onStateChanged();
    } catch (e) {
      debugPrint('[VoiceManager] Erro ao capturar microfone: $e');
    }
  }

  void _startAudioLevelMonitoring() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(milliseconds: 300), (
      timer,
    ) async {
      bool changed = false;

      for (final entry in _connections.entries) {
        final peerId = entry.key;
        final pc = entry.value;

        try {
          final stats = await pc.getStats();
          double audioLevel = 0.0;

          for (final report in stats) {
            // Em diferentes navegadores/plataformas o report pode ter tipos diferentes
            if (report.type == 'inbound-rtp' &&
                report.values['kind'] == 'audio') {
              if (report.values.containsKey('audioLevel')) {
                audioLevel = (report.values['audioLevel'] as num).toDouble();
              }
            } else if (report.type == 'track' &&
                report.values['kind'] == 'audio') {
              if (report.values.containsKey('audioLevel')) {
                audioLevel = (report.values['audioLevel'] as num).toDouble();
              }
            }

            // Detecta o microfone local
            if (report.type == 'media-source' &&
                report.values['kind'] == 'audio') {
              if (report.values.containsKey('audioLevel')) {
                double localLevel = (report.values['audioLevel'] as num)
                    .toDouble();
                final localSpeaking = localLevel > 0.02;
                if (speakingStates[localPeerId] != localSpeaking) {
                  speakingStates[localPeerId] = localSpeaking;
                  changed = true;
                }
              }
            }
          }

          final isSpeaking = audioLevel > 0.02; // Threshold sensível
          if (speakingStates[peerId] != isSpeaking) {
            speakingStates[peerId] = isSpeaking;
            changed = true;
          }
        } catch (e) {
          // stats falhou
        }
      }

      if (changed) {
        onStateChanged();
      }
    });
  }

  /// Entra na chamada e conecta imediatamente com uma lista de peers já presentes.
  Future<void> joinCallAndConnect(List<String> existingPeerIds) async {
    await joinCall();
    if (!_isInCall) return; // Se o mic falhou, não faz nada
    for (final peerId in existingPeerIds) {
      await connectToPeer(peerId);
    }
  }

  /// Inicia a conexao com um novo peer que acabou de entrar no canal.
  /// Na topologia Mesh: conecta diretamente.
  /// Na topologia SFU: clientes comuns so conectam aos Supernodes.
  Future<void> connectToPeer(String remotePeerId) async {
    if (!_isInCall || _localStream == null) return;
    if (_connections.containsKey(remotePeerId)) return;

    // Se a topologia ditar que nao devemos nos conectar (SFU Sharding), ignoramos
    if (topologyManager != null &&
        !topologyManager!.shouldConnectTo(remotePeerId)) {
      debugPrint(
        '[VoiceManager] SFU: ignorando conexao com $remotePeerId (fora do meu shard)',
      );
      return;
    }

    // Regra do Polido/Impolito: quem tem PubKey "maior" cria a Offer.
    final bool isPolite = localPeerId.compareTo(remotePeerId) < 0;

    final pc = await _createPeerConnection(remotePeerId);
    _connections[remotePeerId] = pc;
    peerConnectionTypes[remotePeerId] = VoiceConnectionType.connecting;
    onStateChanged();

    if (!isPolite) {
      debugPrint(
        '[VoiceManager] Impolido ($localPeerId) → criando Offer para $remotePeerId',
      );
      await _createAndSendOffer(remotePeerId, pc);
    } else {
      debugPrint(
        '[VoiceManager] Polido ($localPeerId) → aguardando Offer de $remotePeerId',
      );
    }
  }

  /// Processa um sinal WebRTC recebido pela rede MQTT.
  Future<void> handleSignal(WebrtcSignal signal) async {
    if (!_isInCall) return;
    final remotePeerId = signal.fromPeerId;

    debugPrint(
      '[VoiceManager] Sinal recebido de $remotePeerId: ${signal.type}',
    );

    // Garante que a conexão existe (o "polido" cria a conexão ao receber a Offer)
    if (!_connections.containsKey(remotePeerId)) {
      final pc = await _createPeerConnection(remotePeerId);
      _connections[remotePeerId] = pc;
      peerConnectionTypes[remotePeerId] = VoiceConnectionType.connecting;
      onStateChanged();
    }

    final pc = _connections[remotePeerId]!;

    switch (signal.type) {
      case WebrtcMessageType.offer:
        final sdp = RTCSessionDescription(signal.payload, 'offer');
        await pc.setRemoteDescription(sdp);
        final answer = await pc.createAnswer({'offerToReceiveAudio': 1});
        await pc.setLocalDescription(answer);
        onSendSignal(
          remotePeerId,
          WebrtcSignal(
            fromPeerId: localPeerId,
            type: WebrtcMessageType.answer,
            payload: answer.sdp!,
          ),
        );
        debugPrint('[VoiceManager] Answer enviado para $remotePeerId');
        _drainQueuedCandidates(remotePeerId, pc);

      case WebrtcMessageType.answer:
        final sdp = RTCSessionDescription(signal.payload, 'answer');
        await pc.setRemoteDescription(sdp);
        debugPrint(
          '[VoiceManager] Answer recebido e aplicado de $remotePeerId',
        );
        _drainQueuedCandidates(remotePeerId, pc);

      case WebrtcMessageType.iceCandidate:
        try {
          final json = jsonDecode(signal.payload) as Map<String, dynamic>;
          final candidate = RTCIceCandidate(
            json['candidate'] as String,
            json['sdpMid'] as String?,
            json['sdpMLineIndex'] as int?,
          );

          final remoteDesc = await pc.getRemoteDescription();
          if (remoteDesc != null) {
            await pc.addCandidate(candidate);
          } else {
            _queuedCandidates
                .putIfAbsent(remotePeerId, () => [])
                .add(candidate);
            debugPrint(
              '[VoiceManager] ICE Candidate enfileirado para $remotePeerId',
            );
          }
        } catch (e) {
          debugPrint('[VoiceManager] Erro ao processar ICE Candidate: $e');
        }
    }
  }

  /// Desconecta de um peer específico (ex: quando ele sai do canal).
  Future<void> disconnectFromPeer(String remotePeerId) async {
    _iceFailureTimers[remotePeerId]?.cancel();
    _iceFailureTimers.remove(remotePeerId);
    _mqttVoice?.removePeer(remotePeerId);
    peerConnectionTypes.remove(remotePeerId);
    // Limpa a track remota que esse peer enviava
    final removedTrack = _remoteTracks.remove(remotePeerId);

    final pc = _connections.remove(remotePeerId);
    speakingStates.remove(remotePeerId);
    if (pc != null) {
      await pc.close();
      debugPrint('[VoiceManager] Desconectado de $remotePeerId');
    }

    // Web: limpa o renderer específico dessa track
    if (kIsWeb && removedTrack != null) {
      final renderer = _renderers.remove(removedTrack.id);
      if (renderer != null) {
        await renderer.dispose();
      }
    }

    // Se somos Supernode, avisamos os outros clientes que essa track sumiu (removeTrack)
    if (isLocalSupernode && removedTrack != null) {
      for (final targetPc in _connections.values) {
        try {
          // Busca o sender correspondente a esta track e remove
          final senders = await targetPc.getSenders();
          final senderToRemove = senders
              .where((s) => s.track?.id == removedTrack.id)
              .firstOrNull;
          if (senderToRemove != null) {
            await targetPc.removeTrack(senderToRemove);
          }
        } catch (_) {}
      }
    }

    onStateChanged();
  }

  /// Alterna o mute do microfone (usuários não ouvem você).
  void toggleMicMute() {
    _isMicMuted = !_isMicMuted;
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !_isMicMuted;
    });
    if (_isMicMuted) {
      _mqttVoice?.setMicMuted(true);
    } else {
      _mqttVoice?.setMicMuted(false);
    }
    debugPrint('[VoiceManager] Mic muted: $_isMicMuted');
    onStateChanged();
  }

  /// Alterna o mute completo (mic + speaker — modo silêncio total).
  void toggleSpeakerMute() {
    _isSpeakerMuted = !_isSpeakerMuted;
    // Muta também o mic quando muta tudo
    if (_isSpeakerMuted) {
      _isMicMuted = true;
      _localStream?.getAudioTracks().forEach((track) {
        track.enabled = false;
      });
      _mqttVoice?.setMicMuted(true);
      if (!kIsWeb) {
        Helper.setSpeakerphoneOn(false);
      }
    } else {
      _isMicMuted = false;
      _localStream?.getAudioTracks().forEach((track) {
        track.enabled = true;
      });
      _mqttVoice?.setMicMuted(false);
      if (!kIsWeb) {
        Helper.setSpeakerphoneOn(true);
      }
    }
    debugPrint('[VoiceManager] Speaker muted: $_isSpeakerMuted');
    onStateChanged();
  }

  /// Sai da chamada: desconecta de todos e libera o microfone.
  Future<void> leaveCall() async {
    _isInCall = false;
    _statsTimer?.cancel();

    // Cancela todos os timers de fallback
    for (final t in _iceFailureTimers.values) {
      t.cancel();
    }
    _iceFailureTimers.clear();

    // Para o canal MQTT se estiver ativo
    await _mqttVoice?.stop();
    _mqttVoice = null;

    final peers = List<String>.from(_connections.keys);
    for (final peer in peers) {
      await disconnectFromPeer(peer);
    }

    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream = null;
    debugPrint('[VoiceManager] Saiu da call. Microfone liberado.');
    onStateChanged();
  }

  /// Lista de renderers para montar widgets ocultos de áudio na Web.
  List<MapEntry<String, RTCVideoRenderer>> get webRenderers =>
      _renderers.entries.toList();

  // --- Métodos Privados ---

  Future<void> _drainQueuedCandidates(
    String remotePeerId,
    RTCPeerConnection pc,
  ) async {
    final candidates = _queuedCandidates.remove(remotePeerId);
    if (candidates != null) {
      debugPrint(
        '[VoiceManager] Drenando ${candidates.length} ICE candidates enfileirados para $remotePeerId',
      );
      for (final candidate in candidates) {
        try {
          await pc.addCandidate(candidate);
        } catch (e) {
          debugPrint(
            '[VoiceManager] Erro ao aplicar ICE candidate enfileirado: $e',
          );
        }
      }
    }
  }

  Future<RTCPeerConnection> _createPeerConnection(String remotePeerId) async {
    final pc = await createPeerConnection(_iceConfiguration);

    // Adiciona as tracks de áudio do microfone local
    _localStream!.getTracks().forEach((track) {
      pc.addTrack(track, _localStream!);
    });

    // Se somos Supernode, repassa as tracks já recebidas de outros clientes para este novo peer
    if (isLocalSupernode) {
      for (final entry in _remoteTracks.entries) {
        if (entry.key != remotePeerId) {
          // Não envia de volta
          debugPrint(
            '[VoiceManager] [SFU] Repassando track existente de ${entry.key} para $remotePeerId',
          );
          // Cria uma nova stream para essa track, forçando o navegador destino a tratá-la como stream independente
          final uniqueStream = await createLocalMediaStream(
            'fwd_${entry.value.id}',
          );
          uniqueStream.addTrack(entry.value);
          await pc.addTrack(entry.value, uniqueStream);
        }
      }
    }

    // Renegotiation necessária quando novas tracks são adicionadas (ex: Forwarding SFU)
    pc.onRenegotiationNeeded = () async {
      debugPrint('[VoiceManager] Renegotiation needed for $remotePeerId');
      // Apenas o impolido (quem adicionou a track/Supernode) envia a oferta para evitar Glare constante
      final bool isPolite = localPeerId.compareTo(remotePeerId) < 0;
      if (!isPolite || isLocalSupernode) {
        await _createAndSendOffer(remotePeerId, pc);
      }
    };

    // Quando o ICE gera um candidato, enviamos via MQTT
    pc.onIceCandidate = (candidate) async {
      if (candidate.candidate != null) {
        final payload = jsonEncode({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
        await onSendSignal(
          remotePeerId,
          WebrtcSignal(
            fromPeerId: localPeerId,
            type: WebrtcMessageType.iceCandidate,
            payload: payload,
          ),
        );
      }
    };

    // A conexao ICE gerencia conexoes UDP/TCP. Se falhar por causa de NAT, 
    // faremos fallback pro MQTT TCP (que agora terá payload criptografado via AES-GCM)
    // EIS AQUI O SERVIDOR TURN DE POBRE

    pc.onIceConnectionState = (state) {
      debugPrint('[VoiceManager] ICE[$remotePeerId]: $state');

      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        // ICE bem-sucedido — cancela o timer de fallback se existir
        _iceFailureTimers[remotePeerId]?.cancel();
        _iceFailureTimers.remove(remotePeerId);
        // Remove do canal MQTT se estava lá
        _mqttVoice?.removePeer(remotePeerId);
        peerConnectionTypes[remotePeerId] = VoiceConnectionType.webrtcP2p;
        onStateChanged();
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        // ICE falhou — aciona timer para fallback MQTT em 2s
        _iceFailureTimers[remotePeerId]?.cancel();
        _iceFailureTimers[remotePeerId] = Timer(const Duration(seconds: 2), () {
          debugPrint(
            '[VoiceManager] ICE falhou para $remotePeerId → ativando MQTT relay',
          );
          _activateMqttRelayForPeer(remotePeerId);
        });
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateChecking) {
        // Ainda tentando — cancela fallback pendente se houver
        _iceFailureTimers[remotePeerId]?.cancel();
        _iceFailureTimers.remove(remotePeerId);
      }
    };

    // Ao receber stream remoto de áudio
    pc.onTrack = (event) async {
      if (event.streams.isNotEmpty) {
        debugPrint('[VoiceManager] Track de áudio recebida de $remotePeerId');

        // Na Web, precisamos de um RTCVideoRenderer para que o Chrome toque o áudio.
        // Importante: chaveado pelo track.id para que clientes do SFU consigam ouvir múltiplos remetentes
        if (kIsWeb) {
          final renderer = RTCVideoRenderer();
          await renderer.initialize();
          renderer.srcObject = event.streams.first;
          _renderers[event.track.id!] = renderer;
          onStateChanged(); // Notifica a UI para montar o widget oculto
        } else {
          // No nativo (Android), forçamos o speakerphone e modo VoIP
          if (!kIsWeb) {
            await Helper.setAndroidAudioConfiguration(
              AndroidAudioConfiguration.communication,
            );
            Helper.setSpeakerphoneOn(true);
          }
        }

        // === Lógica de SFU Forwarding ===
        // Armazena a track para repassar a clientes que conectarem depois
        _remoteTracks[remotePeerId] = event.track;

        // Se somos o Supernode, devemos retransmitir (forward) esta track
        if (isLocalSupernode) {
          final isFromAnotherSupernode = _supernodeIds.contains(remotePeerId);
          debugPrint(
            '[VoiceManager] [SFU] Encaminhando track de $remotePeerId...',
          );

          for (final entry in _connections.entries) {
            final targetPeerId = entry.key;
            final targetPc = entry.value;

            // Regras de Roteamento SFU Cascading
            if (targetPeerId == remotePeerId) continue; // Não envia de volta

            // Regra B: Se veio de um Supernode, só repassa para os NOSSOS clientes (não para outros Supernodes)
            if (isFromAnotherSupernode &&
                _supernodeIds.contains(targetPeerId)) {
              continue;
            }

            try {
              final fwdStream = await createLocalMediaStream(
                'fwd_${event.track.id}',
              );
              fwdStream.addTrack(event.track);
              await targetPc.addTrack(event.track, fwdStream);
            } catch (e) {
              debugPrint(
                '[VoiceManager] [SFU] Erro ao encaminhar track para $targetPeerId: $e',
              );
            }
          }
        }
      }
    };

    // Quando o Supernode avisa que uma track foi removida (um peer saiu da sala)
    pc.onRemoveTrack = (stream, track) async {
      debugPrint('[VoiceManager] Track removida pelo peer $remotePeerId');
      if (kIsWeb && track.id != null) {
        final renderer = _renderers.remove(track.id!);
        if (renderer != null) {
          await renderer.dispose();
          onStateChanged();
        }
      }
    };

    return pc;
  }

  Future<void> _createAndSendOffer(
    String remotePeerId,
    RTCPeerConnection pc,
  ) async {
    final offer = await pc.createOffer({'offerToReceiveAudio': 1});
    await pc.setLocalDescription(offer);
    onSendSignal(
      remotePeerId,
      WebrtcSignal(
        fromPeerId: localPeerId,
        type: WebrtcMessageType.offer,
        payload: offer.sdp!,
      ),
    );
    debugPrint('[VoiceManager] Offer enviado para $remotePeerId');
  }

  Future<void> dispose() async {
    await leaveCall();
    topologyManager?.dispose();
    topologyManager = null;
  }

  /// Mede o RTT medio das conexoes WebRTC ativas (para eleicao de Supernode).
  Future<int> measureLocalRtt() async {
    if (_connections.isEmpty) return 999;
    int totalRtt = 0;
    int count = 0;
    for (final pc in _connections.values) {
      try {
        final stats = await pc.getStats();
        for (final report in stats) {
          if (report.type == 'candidate-pair' &&
              report.values['state'] == 'succeeded' &&
              report.values.containsKey('currentRoundTripTime')) {
            final rttSec = (report.values['currentRoundTripTime'] as num)
                .toDouble();
            totalRtt += (rttSec * 1000).round();
            count++;
          }
        }
      } catch (_) {}
    }
    return count > 0 ? (totalRtt ~/ count) : 999;
  }

  /// Atualiza a topologia local (chamado pelo TopologyManager via AppState).
  Future<void> applyTopology(
    CallTopology topology,
    List<String> supernodeIds,
    String? assignedSupernodeId,
  ) async {
    final previousTopology = _callTopology;
    _callTopology = topology;
    _supernodeIds = supernodeIds;

    if (topologyManager == null) return;

    // Desconecta de peers que não pertencem mais ao Shard local
    final toDisconnect = _connections.keys
        .where((peerId) => !topologyManager!.shouldConnectTo(peerId))
        .toList();
    for (final peerId in toDisconnect) {
      disconnectFromPeer(peerId);
      debugPrint(
        '[VoiceManager] Sharding: fechando conexao redundante com $peerId',
      );
    }

    if (topology == CallTopology.sfu &&
        previousTopology == CallTopology.fullMesh) {
      // Correção B: Se viramos Supernode, precisamos repassar todas as tracks que já tinhamos (Mesh->SFU)
      if (isLocalSupernode) {
        for (final remotePeerId in _remoteTracks.keys) {
          final trackToForward = _remoteTracks[remotePeerId]!;
          final isFromAnotherSupernode = _supernodeIds.contains(remotePeerId);

          for (final entry in _connections.entries) {
            final targetPeerId = entry.key;
            final targetPc = entry.value;

            if (targetPeerId == remotePeerId) continue;
            if (isFromAnotherSupernode && _supernodeIds.contains(targetPeerId))
              continue;

            try {
              final fwdStream = await createLocalMediaStream(
                'fwd_${trackToForward.id}',
              );
              fwdStream.addTrack(trackToForward);
              await targetPc.addTrack(trackToForward, fwdStream);
            } catch (_) {}
          }
        }
      }
    } else if (topology == CallTopology.fullMesh &&
        previousTopology == CallTopology.sfu) {
      // Correção C: O Efeito Fantasma. Se era SFU e caiu para Mesh, ex-Supernodes devem parar de retransmitir.
      debugPrint(
        '[VoiceManager] Downgrade para Mesh — limpando retransmissoes.',
      );
      for (final targetPc in _connections.values) {
        try {
          final senders = await targetPc.getSenders();
          for (final sender in senders) {
            // Remove todos os senders que contêm tracks remotas repassadas
            if (sender.track != null &&
                _remoteTracks.values.any((t) => t.id == sender.track!.id)) {
              await targetPc.removeTrack(sender);
            }
          }
        } catch (_) {}
      }
    }
    onStateChanged();
  }

  // ======================================================================
  // MQTT Voice Relay — fallback automático quando WebRTC falha por CGNAT
  // ======================================================================

  void _activateMqttRelayForPeer(String peerId) {
    if (!_isInCall) return;
    final relay = mqttRelay;
    final channelId = currentChannelId;
    if (relay == null || channelId == null) {
      debugPrint('[VoiceManager] MQTT relay não configurado — ignora fallback');
      return;
    }

    // Cria o canal MQTT se ainda não existe
    if (_mqttVoice == null) {
      _mqttVoice = MqttVoiceChannel(
        channelId: channelId,
        localPeerId: localPeerId,
        relay: relay,
        aesKey: currentAesKey,
        onStateChanged: onStateChanged,
      );
      // Inicia captura mas sem peers ainda (addPeer é chamado abaixo)
      _mqttVoice!.start([]);
    }

    // Adiciona o peer ao canal MQTT
    _mqttVoice!.addPeer(peerId);
    peerConnectionTypes[peerId] = VoiceConnectionType.mqttRelay;
    debugPrint('[VoiceManager] Peer $peerId agora usando MQTT relay');
    onStateChanged();
  }

  /// Processa chunk de áudio MQTT recebido — delega ao canal MQTT.
  void handleMqttVoiceChunk(String senderId, Uint8List data) {
    _mqttVoice?.handleReceivedChunk(senderId, data);
    // Propaga speakingState do canal MQTT para o mapa geral
    if (_mqttVoice != null) {
      final mqttSpeaking = _mqttVoice!.speakingStates[senderId];
      if (mqttSpeaking != null && speakingStates[senderId] != mqttSpeaking) {
        speakingStates[senderId] = mqttSpeaking;
      }
    }
  }
}
