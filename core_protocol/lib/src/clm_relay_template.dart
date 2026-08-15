import 'dart:async';
import 'dart:typed_data';

/// Classe responsável pela comunicação via fallback improvisado (MOCK)
/// Para usar o protocolo real, solicite os binários proprietários.
class ClmRelay {
  final String clientId;

  Function(String topic, Uint8List payload)? onMessageReceived;

  ClmRelay(this.clientId);

  Future<bool> connect() async {
    return true;
  }

  void disconnect() {}

  // =======================================================================
  // 1. SINCRONIZAÇÃO ASSÍNCRONA DE ARQUIVO (DELTAS)
  // =======================================================================

  Future<void> listenToServerDeltas(String serverId) async {}

  Future<void> publishDelta(String serverId, Uint8List payload) async {}

  // =======================================================================
  // 2. CONVITE E APERTO DE MÃO (WEBRTC SIGNALING)
  // =======================================================================

  Future<void> listenToSignaling(String myPublicKeyHex) async {}

  Future<void> sendSignaling(
    String targetPublicKeyHex,
    Uint8List payload,
  ) async {}

  // =======================================================================
  // 3. RELAY DE ÁUDIO VIA MQTT (Fallback quando WebRTC falha por CGNAT)
  // =======================================================================

  Future<void> listenToVoicePeer(String channelId, String peerId) async {}

  Future<void> unlistenVoicePeer(String channelId, String peerId) async {}

  Future<void> publishVoiceChunk(
    String channelId,
    String myPeerId,
    Uint8List audioData,
  ) async {}
}
