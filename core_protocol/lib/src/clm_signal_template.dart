import 'dart:convert';
import 'dart:typed_data';

enum SignalOpCode {
  joinRequest(10),
  joinAccepted(11),
  voiceJoin(20),
  voiceLeave(21),
  deltaSync(30),
  webrtc(40),
  topologyMetrics(50);

  final int value;
  const SignalOpCode(this.value);

  static SignalOpCode fromValue(int value) {
    return values.firstWhere((e) => e.value == value);
  }
}

abstract class ClmSignal {
  final SignalOpCode opCode;
  ClmSignal({required this.opCode});

  Uint8List toBytes();

  static ClmSignal fromBytes(Uint8List bytes) {
    if (bytes.isEmpty) throw Exception('Sinal vazio');
    final map = jsonDecode(utf8.decode(bytes));
    final opCode = SignalOpCode.fromValue(map['opCode']);

    switch (opCode) {
      case SignalOpCode.joinRequest:
        return JoinRequestSignal(serverId: map['serverId'], friendPub: map['friendPub'], friendName: map['friendName']);
      case SignalOpCode.joinAccepted:
        return JoinAcceptedSignal(serverData: base64Decode(map['serverData']));
      case SignalOpCode.voiceJoin:
        return VoiceJoinSignal(serverId: map['serverId'], channelId: map['channelId'], memberId: map['memberId'], memberName: map['memberName'], isAdmin: map['isAdmin']);
      case SignalOpCode.voiceLeave:
        return VoiceLeaveSignal(serverId: map['serverId'], channelId: map['channelId'], memberId: map['memberId']);
      case SignalOpCode.deltaSync:
        return DeltaSyncSignal(serverId: map['serverId'], deltaBytes: base64Decode(map['deltaBytes']));
      case SignalOpCode.webrtc:
        return WebrtcSignal(fromPeerId: map['fromPeerId'], type: WebrtcMessageType.values[map['type']], payload: map['payload']);
      case SignalOpCode.topologyMetrics:
        return TopologyMetricsSignal(peerId: map['peerId'], channelId: map['channelId'], platformScore: map['platformScore'], avgRttMs: map['avgRttMs']);
    }
  }
}

class JoinRequestSignal extends ClmSignal {
  final String serverId;
  final String friendPub;
  final String friendName;
  JoinRequestSignal({required this.serverId, required this.friendPub, required this.friendName}) : super(opCode: SignalOpCode.joinRequest);

  @override
  Uint8List toBytes() => utf8.encode(jsonEncode({'opCode': opCode.value, 'serverId': serverId, 'friendPub': friendPub, 'friendName': friendName})) as Uint8List;
}

class JoinAcceptedSignal extends ClmSignal {
  final Uint8List serverData;
  JoinAcceptedSignal({required this.serverData}) : super(opCode: SignalOpCode.joinAccepted);

  @override
  Uint8List toBytes() => utf8.encode(jsonEncode({'opCode': opCode.value, 'serverData': base64Encode(serverData)})) as Uint8List;
}

class VoiceJoinSignal extends ClmSignal {
  final String serverId;
  final String channelId;
  final String memberId;
  final String memberName;
  final bool isAdmin;
  VoiceJoinSignal({required this.serverId, required this.channelId, required this.memberId, required this.memberName, required this.isAdmin}) : super(opCode: SignalOpCode.voiceJoin);

  @override
  Uint8List toBytes() => utf8.encode(jsonEncode({'opCode': opCode.value, 'serverId': serverId, 'channelId': channelId, 'memberId': memberId, 'memberName': memberName, 'isAdmin': isAdmin})) as Uint8List;
}

class VoiceLeaveSignal extends ClmSignal {
  final String serverId;
  final String channelId;
  final String memberId;
  VoiceLeaveSignal({required this.serverId, required this.channelId, required this.memberId}) : super(opCode: SignalOpCode.voiceLeave);

  @override
  Uint8List toBytes() => utf8.encode(jsonEncode({'opCode': opCode.value, 'serverId': serverId, 'channelId': channelId, 'memberId': memberId})) as Uint8List;
}

class DeltaSyncSignal extends ClmSignal {
  final String serverId;
  final Uint8List deltaBytes;
  DeltaSyncSignal({required this.serverId, required this.deltaBytes}) : super(opCode: SignalOpCode.deltaSync);

  @override
  Uint8List toBytes() => utf8.encode(jsonEncode({'opCode': opCode.value, 'serverId': serverId, 'deltaBytes': base64Encode(deltaBytes)})) as Uint8List;
}

enum WebrtcMessageType { offer, answer, iceCandidate }

class WebrtcSignal extends ClmSignal {
  final String fromPeerId;
  final WebrtcMessageType type;
  final String payload;
  WebrtcSignal({required this.fromPeerId, required this.type, required this.payload}) : super(opCode: SignalOpCode.webrtc);

  @override
  Uint8List toBytes() => utf8.encode(jsonEncode({'opCode': opCode.value, 'fromPeerId': fromPeerId, 'type': type.index, 'payload': payload})) as Uint8List;
}

class TopologyMetricsSignal extends ClmSignal {
  final String peerId;
  final String channelId;
  final int platformScore;
  final int avgRttMs;
  TopologyMetricsSignal({required this.peerId, required this.channelId, required this.platformScore, required this.avgRttMs}) : super(opCode: SignalOpCode.topologyMetrics);

  @override
  Uint8List toBytes() => utf8.encode(jsonEncode({'opCode': opCode.value, 'peerId': peerId, 'channelId': channelId, 'platformScore': platformScore, 'avgRttMs': avgRttMs})) as Uint8List;
}
