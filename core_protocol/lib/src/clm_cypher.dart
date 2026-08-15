import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Classe responsável pela Criptografia Ponta a Ponta (AES-GCM 256 bits)
class ClmCypher {
  static final _algorithm = AesGcm.with256bits();

  /// Gera uma nova chave AES-256 aleatória e a retorna em Base64Url
  static Future<String> generateAesKeyBase64() async {
    final key = await _algorithm.newSecretKey();
    final bytes = await key.extractBytes();
    // Removendo padding do base64 para o código de convite ficar mais limpo
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// Criptografa o payload
  /// Retorna: [12 bytes Nonce] + [16 bytes Mac] + [Ciphertext]
  static Future<Uint8List> encryptPayload(Uint8List plainText, String keyBase64) async {
    // Adiciona o padding devolta se necessário
    var paddedKey = keyBase64;
    while (paddedKey.length % 4 != 0) {
      paddedKey += '=';
    }
    
    final keyBytes = base64Url.decode(paddedKey);
    final secretKey = SecretKey(keyBytes);
    
    final secretBox = await _algorithm.encrypt(
      plainText,
      secretKey: secretKey,
    );
    
    final result = BytesBuilder();
    result.add(secretBox.nonce); // 12 bytes por padrão no AesGcm
    result.add(secretBox.mac.bytes); // 16 bytes por padrão
    result.add(secretBox.cipherText);
    
    return result.toBytes();
  }

  /// Descriptografa o payload
  static Future<Uint8List?> decryptPayload(Uint8List encryptedData, String keyBase64) async {
    try {
      if (encryptedData.length < 28) return null; // 12 nonce + 16 mac
      
      final nonce = encryptedData.sublist(0, 12);
      final macBytes = encryptedData.sublist(12, 28);
      final cipherText = encryptedData.sublist(28);
      
      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      );
      
      var paddedKey = keyBase64;
      while (paddedKey.length % 4 != 0) {
        paddedKey += '=';
      }
      
      final keyBytes = base64Url.decode(paddedKey);
      final secretKey = SecretKey(keyBytes);
      
      final plainText = await _algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      
      return Uint8List.fromList(plainText);
    } catch (e) {
      // Se falhar (chave errada ou corrompido), apenas retorna null
      return null;
    }
  }
}
