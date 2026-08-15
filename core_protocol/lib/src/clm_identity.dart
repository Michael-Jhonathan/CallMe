import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Classe responsável pela Segurança e Identidade Criptográfica do usuário
class ClmIdentity {
  // Usamos Ed25519 porque é extremamente rápido, seguro e o padrão moderno para assinaturas P2P
  static final _algorithm = Ed25519();

  /// Gera um novo par de chaves invisível no aparelho do usuário (executado apenas 1x na instalação)
  static Future<SimpleKeyPair> generateKeyPair() async {
    return await _algorithm.newKeyPair();
  }

  /// Extrai a Chave Pública (que será usada como o ID público do usuário/servidor) no formato Hexadecimal
  static Future<String> getPublicKeyHex(SimpleKeyPair keyPair) async {
    final pubKey = await keyPair.extractPublicKey();
    return _bytesToHex(pubKey.bytes);
  }

  /// Assina um pacote de bytes puros (ex: o pacote do Delta) usando a Chave Privada do usuário
  static Future<Signature> signPayload(Uint8List payload, SimpleKeyPair keyPair) async {
    return await _algorithm.sign(payload, keyPair: keyPair);
  }

  /// Verifica matematicamente se uma assinatura é autêntica e se os dados não foram adulterados
  static Future<bool> verifySignature(List<int> payload, Signature signature, String publicKeyHex) async {
    final pubKeyBytes = _hexToBytes(publicKeyHex);
    final pubKey = SimplePublicKey(pubKeyBytes, type: KeyPairType.ed25519);
    
    return await _algorithm.verify(
      payload,
      signature: signature,
    );
  }

  // --- Funções Auxiliares (Hexadecimal <-> Bytes) ---
  
  static String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('').toUpperCase();
  }

  static List<int> _hexToBytes(String hex) {
    hex = hex.replaceAll(' ', '');
    final result = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      final byteString = hex.substring(i, i + 2);
      result.add(int.parse(byteString, radix: 16));
    }
    return result;
  }
}
