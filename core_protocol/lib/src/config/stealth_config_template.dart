import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Configuração do Stealth Mode (Modo Furtivo) para o CallMe.
/// Este arquivo é um TEMPLATE. Para rodar o projeto localmente,
/// copie este arquivo para `stealth_config.dart`.
class StealthConfig {
  /// Lista de Brokers Públicos MQTT (O "Pool").
  /// O aplicativo usará esses brokers de forma rotativa ou via Hash
  /// para não sobrecarregar um único servidor e evitar bloqueios.
  static const List<String> brokers = [
    'broker.emqx.io',
    'broker.hivemq.com',
    'test.mosquitto.org',
  ];

  static const List<String> webSockets = [
    'wss://broker.emqx.io:8084/mqtt',
    'wss://broker.hivemq.com:8443/mqtt',
    'wss://test.mosquitto.org:8081',
  ];

  /// Salt secreto usado para ofuscar os tópicos. 
  /// Em produção, mude este valor para qualquer string aleatória!
  static const String _secretSalt = 'callme_open_source_salt_v1';

  static String getBrokerUrl(String id) {
    final hash = sha256.convert(utf8.encode(id)).bytes;
    final index = hash[0] % brokers.length;
    return brokers[index];
  }

  static String getWebSocketUrl(String id) {
    final hash = sha256.convert(utf8.encode(id)).bytes;
    final index = hash[0] % webSockets.length;
    return webSockets[index];
  }

  /// Gera um tópico ofuscado usando SHA-256 para não chamar atenção
  /// dos administradores dos brokers públicos.
  static String getObfuscatedTopic(String baseTopic) {
    final bytes = utf8.encode(_secretSalt + baseTopic);
    final digest = sha256.convert(bytes);
    // Retorna os primeiros 16 caracteres do hash para o tópico
    return 'c/${digest.toString().substring(0, 16)}';
  }

  /// Retorna o tópico de sinalização (WebRTC Handshake) para um peer
  static String getSignalingTopic(String peerId) {
    return getObfuscatedTopic('signaling_$peerId');
  }

  /// Retorna o tópico de canal de voz (MQTT Audio Fallback)
  static String getVoiceTopic(String channelId) {
    return getObfuscatedTopic('voice_$channelId');
  }

  /// Retorna o tópico de Deltas do Servidor (Eventos do Grupo)
  static String getServerTopic(String serverId) {
    return getObfuscatedTopic('server_$serverId');
  }
}
