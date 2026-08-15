import 'dart:typed_data';
import 'dart:convert';
import 'clm_file.dart'; // import the original or template clm_file

enum DeltaOpCode {
  renameServer(1),
  addMember(2),
  removeMember(3),
  addChannel(4),
  removeChannel(5),
  setTextChannel(6),
  updateMember(7);

  final int value;
  const DeltaOpCode(this.value);

  static DeltaOpCode fromValue(int value) {
    return values.firstWhere((e) => e.value == value);
  }
}

abstract class ClmDelta {
  final DeltaOpCode opCode;
  final int timestamp;

  ClmDelta({required this.opCode, required this.timestamp});

  Uint8List toBytes();
  ClmFile applyTo(ClmFile current);

  static ClmDelta fromBytes(Uint8List bytes) {
    final map = jsonDecode(utf8.decode(bytes));
    final opCode = DeltaOpCode.fromValue(map['opCode']);
    final timestamp = map['timestamp'];
    
    switch (opCode) {
      case DeltaOpCode.renameServer:
        return RenameServerDelta(timestamp: timestamp, newName: map['newName']);
      case DeltaOpCode.addMember:
        return AddMemberDelta(timestamp: timestamp, member: ClmMember.fromJson(map['member']));
      case DeltaOpCode.removeMember:
        return RemoveMemberDelta(timestamp: timestamp, memberId: map['memberId']);
      case DeltaOpCode.addChannel:
        return AddChannelDelta(timestamp: timestamp, channel: ClmChannel.fromJson(map['channel']));
      case DeltaOpCode.removeChannel:
        return RemoveChannelDelta(timestamp: timestamp, channelId: map['channelId']);
      case DeltaOpCode.setTextChannel:
        return SetTextChannelDelta(timestamp: timestamp, channel: ClmTextChannel.fromJson(map['channel']));
      case DeltaOpCode.updateMember:
        return UpdateMemberDelta(timestamp: timestamp, member: ClmMember.fromJson(map['member']));
      default:
        throw UnimplementedError('Operação não implementada: $opCode');
    }
  }
}

class RenameServerDelta extends ClmDelta {
  final String newName;
  RenameServerDelta({required int timestamp, required this.newName}) : super(opCode: DeltaOpCode.renameServer, timestamp: timestamp);

  @override
  Uint8List toBytes() => utf8.encode(jsonEncode({'opCode': opCode.value, 'timestamp': timestamp, 'newName': newName})) as Uint8List;

  @override
  ClmFile applyTo(ClmFile current) {
    final newTimestamp = timestamp > current.timestamp ? timestamp : current.timestamp;
    return ClmFile(serverId: current.serverId, timestamp: newTimestamp, serverName: newName, members: current.members, channels: current.channels, textChannels: current.textChannels);
  }
}

class AddMemberDelta extends ClmDelta {
  final ClmMember member;
  AddMemberDelta({required int timestamp, required this.member}) : super(opCode: DeltaOpCode.addMember, timestamp: timestamp);

  @override
  Uint8List toBytes() => utf8.encode(jsonEncode({'opCode': opCode.value, 'timestamp': timestamp, 'member': member.toJson()})) as Uint8List;

  @override
  ClmFile applyTo(ClmFile current) {
    final newTimestamp = timestamp > current.timestamp ? timestamp : current.timestamp;
    final newMembers = List<ClmMember>.from(current.members);
    if (!newMembers.any((m) => m.id == member.id)) newMembers.add(member);
    return ClmFile(serverId: current.serverId, timestamp: newTimestamp, serverName: current.serverName, members: newMembers, channels: current.channels, textChannels: current.textChannels);
  }
}

class AddChannelDelta extends ClmDelta {
  final ClmChannel channel;
  AddChannelDelta({required int timestamp, required this.channel}) : super(opCode: DeltaOpCode.addChannel, timestamp: timestamp);

  @override
  Uint8List toBytes() => utf8.encode(jsonEncode({'opCode': opCode.value, 'timestamp': timestamp, 'channel': channel.toJson()})) as Uint8List;

  @override
  ClmFile applyTo(ClmFile current) {
    final newTimestamp = timestamp > current.timestamp ? timestamp : current.timestamp;
    final newChannels = List<ClmChannel>.from(current.channels);
    if (!newChannels.any((c) => c.id == channel.id)) newChannels.add(channel);
    return ClmFile(serverId: current.serverId, timestamp: newTimestamp, serverName: current.serverName, members: current.members, channels: newChannels, textChannels: current.textChannels);
  }
}

class SetTextChannelDelta extends ClmDelta {
  final ClmTextChannel channel;
  SetTextChannelDelta({required int timestamp, required this.channel}) : super(opCode: DeltaOpCode.setTextChannel, timestamp: timestamp);

  @override
  Uint8List toBytes() => utf8.encode(jsonEncode({'opCode': opCode.value, 'timestamp': timestamp, 'channel': channel.toJson()})) as Uint8List;

  @override
  ClmFile applyTo(ClmFile current) {
    final newTimestamp = timestamp > current.timestamp ? timestamp : current.timestamp;
    final newTextChannels = List<ClmTextChannel>.from(current.textChannels);
    final index = newTextChannels.indexWhere((c) => c.id == channel.id);
    if (index >= 0) newTextChannels[index] = channel;
    else newTextChannels.add(channel);
    return ClmFile(serverId: current.serverId, timestamp: newTimestamp, serverName: current.serverName, members: current.members, channels: current.channels, textChannels: newTextChannels);
  }
}

class RemoveMemberDelta extends ClmDelta {
  final String memberId;
  RemoveMemberDelta({required int timestamp, required this.memberId}) : super(opCode: DeltaOpCode.removeMember, timestamp: timestamp);

  @override
  Uint8List toBytes() => utf8.encode(jsonEncode({'opCode': opCode.value, 'timestamp': timestamp, 'memberId': memberId})) as Uint8List;

  @override
  ClmFile applyTo(ClmFile current) {
    final newTimestamp = timestamp > current.timestamp ? timestamp : current.timestamp;
    final newMembers = List<ClmMember>.from(current.members)..removeWhere((m) => m.id == memberId);
    return ClmFile(serverId: current.serverId, timestamp: newTimestamp, serverName: current.serverName, members: newMembers, channels: current.channels, textChannels: current.textChannels);
  }
}

class RemoveChannelDelta extends ClmDelta {
  final String channelId;
  RemoveChannelDelta({required int timestamp, required this.channelId}) : super(opCode: DeltaOpCode.removeChannel, timestamp: timestamp);

  @override
  Uint8List toBytes() => utf8.encode(jsonEncode({'opCode': opCode.value, 'timestamp': timestamp, 'channelId': channelId})) as Uint8List;

  @override
  ClmFile applyTo(ClmFile current) {
    final newTimestamp = timestamp > current.timestamp ? timestamp : current.timestamp;
    final newChannels = List<ClmChannel>.from(current.channels)..removeWhere((c) => c.id == channelId);
    return ClmFile(serverId: current.serverId, timestamp: newTimestamp, serverName: current.serverName, members: current.members, channels: newChannels, textChannels: current.textChannels);
  }
}

class UpdateMemberDelta extends ClmDelta {
  final ClmMember member;
  UpdateMemberDelta({required int timestamp, required this.member}) : super(opCode: DeltaOpCode.updateMember, timestamp: timestamp);

  @override
  Uint8List toBytes() => utf8.encode(jsonEncode({'opCode': opCode.value, 'timestamp': timestamp, 'member': member.toJson()})) as Uint8List;

  @override
  ClmFile applyTo(ClmFile current) {
    final newTimestamp = timestamp > current.timestamp ? timestamp : current.timestamp;
    final newMembers = List<ClmMember>.from(current.members);
    final index = newMembers.indexWhere((m) => m.id == member.id);
    if (index >= 0) newMembers[index] = member;
    return ClmFile(serverId: current.serverId, timestamp: newTimestamp, serverName: current.serverName, members: newMembers, channels: current.channels, textChannels: current.textChannels);
  }
}
