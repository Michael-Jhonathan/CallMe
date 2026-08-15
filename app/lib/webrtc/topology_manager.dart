import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:core_protocol/core_protocol.dart';

/// Topologia ativa da chamada.
enum CallTopology {
  /// Todos se conectam a todos (ate 4 membros). Menor latencia.
  fullMesh,
  /// Supernodes recebem o audio de clientes e repassam. Economiza banda.
  sfu,
}

/// Metrica de performance de um peer para fins de eleicao de Supernode.
class PeerMetrics {
  final String peerId;
  final int platformScore; // 1 = desktop/web, 0 = mobile
  final int avgRttMs;      // RTT medio em ms (menor = melhor)
  final DateTime receivedAt;

  const PeerMetrics({
    required this.peerId,
    required this.platformScore,
    required this.avgRttMs,
    required this.receivedAt,
  });

  /// Score composto: plataforma tem peso maximo. Menor RTT desempata.
  /// Score numerico (maior = melhor): [1000 * platform] - rtt
  int get compositeScore => (platformScore * 1000) - avgRttMs;
}

/// Gerencia a topologia de chamada: elege Supernodes e coordena
/// a transicao entre Mesh (<=4 peers) e SFU dinamico (>4 peers).
class TopologyManager {
  static const int _meshThreshold = 4;
  static const Duration _metricsTimeout = Duration(seconds: 10);

  final String localPeerId;
  final Future<void> Function(TopologyMetricsSignal signal) onBroadcastMetrics;
  final void Function(CallTopology topology, List<String> supernodeIds, String? assignedSupernodeId) onTopologyChanged;
  final Future<int> Function() onGetLocalRtt;

  CallTopology _topology = CallTopology.fullMesh;
  CallTopology get topology => _topology;

  List<String> _supernodeIds = [];
  List<String> get supernodeIds => List.unmodifiable(_supernodeIds);

  bool get isLocalSupernode => _supernodeIds.contains(localPeerId);

  String? _assignedSupernodeId;
  String? get assignedSupernodeId => _assignedSupernodeId;

  final Map<String, PeerMetrics> _metricsMap = {};
  Timer? _electionTimer;
  List<String> _activeMembers = [];

  TopologyManager({
    required this.localPeerId,
    required this.onBroadcastMetrics,
    required this.onTopologyChanged,
    required this.onGetLocalRtt,
  });

  Future<void> onMemberCountChanged(String channelId, List<String> activeMembers) async {
    _activeMembers = activeMembers;
    final count = activeMembers.length;

    if (count <= _meshThreshold) {
      if (_topology != CallTopology.fullMesh) {
        _topology = CallTopology.fullMesh;
        _supernodeIds = [];
        _assignedSupernodeId = null;
        onTopologyChanged(_topology, _supernodeIds, _assignedSupernodeId);
        debugPrint('[Topology] Voltando para Full Mesh ($count membros)');
      }
      _electionTimer?.cancel();
    } else {
      await _publishLocalMetrics(channelId);
      _scheduleElection();
    }
  }

  void onMetricsReceived(TopologyMetricsSignal signal) {
    _metricsMap[signal.peerId] = PeerMetrics(
      peerId: signal.peerId,
      platformScore: signal.platformScore,
      avgRttMs: signal.avgRttMs,
      receivedAt: DateTime.now(),
    );
    debugPrint('[Topology] Metricas de ${signal.peerId}: platform=${signal.platformScore}, rtt=${signal.avgRttMs}ms');
    _scheduleElection();
  }

  Future<void> _publishLocalMetrics(String channelId) async {
    final rtt = await onGetLocalRtt();
    final platformScore = kIsWeb ? 1 : 0;
    _metricsMap[localPeerId] = PeerMetrics(
      peerId: localPeerId,
      platformScore: platformScore,
      avgRttMs: rtt,
      receivedAt: DateTime.now(),
    );
    final signal = TopologyMetricsSignal(
      peerId: localPeerId,
      channelId: channelId,
      platformScore: platformScore,
      avgRttMs: rtt,
    );
    await onBroadcastMetrics(signal);
    debugPrint('[Topology] Metricas publicadas: platform=$platformScore, rtt=${rtt}ms');
  }

  void _scheduleElection() {
    _electionTimer?.cancel();
    _electionTimer = Timer(const Duration(milliseconds: 1500), _runElection);
  }

  void _runElection() {
    if (_activeMembers.length <= _meshThreshold) return;

    final now = DateTime.now();
    _metricsMap.removeWhere((_, m) => now.difference(m.receivedAt) > _metricsTimeout);

    final sorted = _metricsMap.values.toList()
      ..sort((a, b) => b.compositeScore.compareTo(a.compositeScore));

    // Proporcao: 1 Supernode para cada 4 pessoas
    final supernodeCount = (_activeMembers.length / 4).ceil();
    final newSupernodes = sorted.take(supernodeCount).map((m) => m.peerId).toList()..sort();

    // Determina o Supernode assinalado caso este peer seja um cliente
    String? newAssignedSupernode;
    if (!newSupernodes.contains(localPeerId)) {
      final clients = _activeMembers.where((id) => !newSupernodes.contains(id)).toList()..sort();
      final myIndex = clients.indexOf(localPeerId);
      if (myIndex != -1 && newSupernodes.isNotEmpty) {
        newAssignedSupernode = newSupernodes[myIndex % newSupernodes.length];
      }
    }

    final topologyChanged = _topology != CallTopology.sfu || 
                            !_listsEqual(_supernodeIds, newSupernodes) || 
                            _assignedSupernodeId != newAssignedSupernode;

    _topology = CallTopology.sfu;
    _supernodeIds = newSupernodes;
    _assignedSupernodeId = newAssignedSupernode;

    if (topologyChanged) {
      onTopologyChanged(_topology, _supernodeIds, _assignedSupernodeId);
      debugPrint('[Topology] SFU eleito. Supernodes: $newSupernodes. Meu Supernode: $_assignedSupernodeId');
    }
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Indica se este peer local deve estabelecer ou manter conexao com o targetPeerId
  bool shouldConnectTo(String targetPeerId) {
    if (_topology == CallTopology.fullMesh) return true;
    
    if (isLocalSupernode) {
      // Como Supernode, conecta a: outros supernodes + seus proprios clientes
      if (_supernodeIds.contains(targetPeerId)) return true;
      
      final clients = _activeMembers.where((id) => !_supernodeIds.contains(id)).toList()..sort();
      final targetIndex = clients.indexOf(targetPeerId);
      if (targetIndex != -1 && _supernodeIds.isNotEmpty) {
        final assignedTo = _supernodeIds[targetIndex % _supernodeIds.length];
        return assignedTo == localPeerId;
      }
      return false;
    } else {
      // Como Cliente comum, conecta apenas ao seu Supernode assinalado
      return targetPeerId == _assignedSupernodeId;
    }
  }

  void dispose() {
    _electionTimer?.cancel();
    _metricsMap.clear();
  }
}
