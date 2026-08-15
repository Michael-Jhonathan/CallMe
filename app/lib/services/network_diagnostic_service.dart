import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

enum NatType {
  open,          // Sem NAT, IP Local == Público (ou IPv6 Direto)
  standardNat,   // NAT de Roteador Comum
  cgnat,         // Carrier-Grade NAT (Operadora Móvel)
  unknown
}

class NetworkDiagnosticResult {
  final String localIp;
  final String publicIpv4;
  final String publicIpv6;
  final NatType natType;
  final bool hasIpv6;

  NetworkDiagnosticResult({
    required this.localIp,
    required this.publicIpv4,
    required this.publicIpv6,
    required this.natType,
    required this.hasIpv6,
  });
}

class NetworkDiagnosticService {
  
  /// Tenta pegar o IPv6 público
  static Future<String?> getPublicIpv6() async {
    try {
      final response = await http.get(Uri.parse('https://api64.ipify.org?format=text'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final ip = response.body.trim();
        // Verifica se é mesmo um IPv6 (tem ':')
        if (ip.contains(':')) {
          return ip;
        }
      }
    } catch (e) {
      debugPrint('[NetworkDiag] IPv6 fetch error: $e');
    }
    return null;
  }

  /// Tenta pegar o IPv4 público
  static Future<String?> getPublicIpv4() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org?format=text'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final ip = response.body.trim();
        if (ip.contains('.')) {
          return ip;
        }
      }
    } catch (e) {
      debugPrint('[NetworkDiag] IPv4 fetch error: $e');
    }
    return null;
  }

  /// Tenta pegar o IP local da interface (na Web retorna N/A)
  static Future<String> getLocalIp() async {
    if (kIsWeb) return 'N/A (Web)';
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (var interface in interfaces) {
        for (var address in interface.addresses) {
          if (!address.isLoopback) {
            return address.address;
          }
        }
      }
    } catch (e) {
      debugPrint('[NetworkDiag] Local IP error: $e');
    }
    return 'Desconhecido';
  }

  /// Verifica se o IP é de bloco CGNAT (100.64.0.0/10)
  static bool _isCgnatIp(String ip) {
    if (ip == 'N/A (Web)' || ip == 'Desconhecido' || !ip.contains('.')) return false;
    try {
      final parts = ip.split('.');
      if (parts.length == 4) {
        int p1 = int.parse(parts[0]);
        int p2 = int.parse(parts[1]);
        if (p1 == 100 && p2 >= 64 && p2 <= 127) {
          return true;
        }
        // Algumas operadoras usam 10.x.x.x ou 172.16.x.x como CGNAT móvel.
        // É difícil diferenciar 10.x.x.x de um CGNAT ou de uma rede corporativa,
        // mas o padrão internacional de CGNAT é 100.64.x.x.
      }
    } catch (_) {}
    return false;
  }

  static Future<NetworkDiagnosticResult> runDiagnostics() async {
    final ipv6Future = getPublicIpv6();
    final ipv4Future = getPublicIpv4();
    final localIpFuture = getLocalIp();

    final results = await Future.wait([ipv6Future, ipv4Future, localIpFuture]);
    final ipv6 = results[0];
    final ipv4 = results[1];
    final localIp = results[2] as String;

    NatType type = NatType.unknown;
    
    if (ipv4 != null && localIp != 'N/A (Web)' && localIp != 'Desconhecido') {
      if (ipv4 == localIp) {
        type = NatType.open;
      } else if (_isCgnatIp(localIp)) {
        type = NatType.cgnat;
      } else {
        type = NatType.standardNat;
      }
    } else if (kIsWeb) {
      type = NatType.unknown;
    }

    return NetworkDiagnosticResult(
      localIp: localIp,
      publicIpv4: ipv4 ?? 'Inativo / Bloqueado',
      publicIpv6: ipv6 ?? 'Indisponível',
      natType: type,
      hasIpv6: ipv6 != null,
    );
  }
}
