import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'clm_file.dart';

class ClmBackup {
  final String userName;
  final String privateKeyBase64;
  final String publicKeyBase64;
  final List<ClmFile> savedServers;

  ClmBackup({
    required this.userName,
    required this.privateKeyBase64,
    required this.publicKeyBase64,
    required this.savedServers,
  });

  static Future<List<int>> _hashPassword(String password) async {
    final bytes = utf8.encode(password);
    final algorithm = Sha256();
    final hash = await algorithm.hash(bytes);
    return hash.bytes;
  }

  Future<Uint8List> toBytes(String password) async {
    final hash = await _hashPassword(password);
    final map = {
      'hash': base64Encode(hash),
      'userName': userName,
      'privateKeyBase64': privateKeyBase64,
      'publicKeyBase64': publicKeyBase64,
      'savedServers': savedServers.map((s) => base64Encode(s.toBytes())).toList(),
    };
    return utf8.encode(jsonEncode(map)) as Uint8List;
  }

  static Future<ClmBackup> fromBytes(Uint8List bytes, String password) async {
    final map = jsonDecode(utf8.decode(bytes));
    
    final expectedHash = base64Decode(map['hash']);
    final actualHash = await _hashPassword(password);
    
    bool passwordMatch = true;
    for (int i = 0; i < 32; i++) {
      if (expectedHash[i] != actualHash[i]) {
        passwordMatch = false;
        break;
      }
    }
    
    if (!passwordMatch) {
      throw Exception('Senha incorreta.');
    }

    final savedServers = (map['savedServers'] as List).map((s) {
      final serverBytes = base64Decode(s);
      return ClmFile.fromBytes(serverBytes);
    }).toList();

    return ClmBackup(
      userName: map['userName'],
      privateKeyBase64: map['privateKeyBase64'],
      publicKeyBase64: map['publicKeyBase64'],
      savedServers: savedServers,
    );
  }
}
