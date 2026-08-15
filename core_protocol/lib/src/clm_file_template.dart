import 'dart:typed_data';
import 'dart:convert';

class ClmMember {
  final String id;
  final String name;
  final bool isAdmin;

  ClmMember({required this.id, required this.name, required this.isAdmin});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isAdmin': isAdmin,
      };

  factory ClmMember.fromJson(Map<String, dynamic> json) => ClmMember(
        id: json['id'],
        name: json['name'],
        isAdmin: json['isAdmin'] ?? false,
      );
}

class ClmChannel {
  final String id;
  final String name;

  ClmChannel({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory ClmChannel.fromJson(Map<String, dynamic> json) => ClmChannel(
        id: json['id'],
        name: json['name'],
      );
}

class ClmTextChannel {
  final String id;
  final String title;
  final String content;

  ClmTextChannel({required this.id, required this.title, required this.content});

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'content': content};

  factory ClmTextChannel.fromJson(Map<String, dynamic> json) => ClmTextChannel(
        id: json['id'],
        title: json['title'],
        content: json['content'],
      );
}

/// Template Open Source de estrutura (usando JSON simples em vez de binário)
class ClmFile {
  final String serverId;
  final int timestamp;
  final String serverName;
  final String? serverAesKey;
  final List<ClmMember> members;
  final List<ClmChannel> channels;
  final List<ClmTextChannel> textChannels;

  ClmFile({
    required this.serverId,
    required this.timestamp,
    required this.serverName,
    this.serverAesKey,
    required this.members,
    required this.channels,
    this.textChannels = const [],
  });

  Uint8List toBytes() {
    final map = {
      'serverId': serverId,
      'timestamp': timestamp,
      'serverName': serverName,
      'serverAesKey': serverAesKey,
      'members': members.map((e) => e.toJson()).toList(),
      'channels': channels.map((e) => e.toJson()).toList(),
      'textChannels': textChannels.map((e) => e.toJson()).toList(),
    };
    return utf8.encode(jsonEncode(map)) as Uint8List;
  }

  static ClmFile fromBytes(Uint8List bytes) {
    final map = jsonDecode(utf8.decode(bytes));
    return ClmFile(
      serverId: map['serverId'],
      timestamp: map['timestamp'],
      serverName: map['serverName'],
      serverAesKey: map['serverAesKey'],
      members: (map['members'] as List).map((e) => ClmMember.fromJson(e)).toList(),
      channels: (map['channels'] as List).map((e) => ClmChannel.fromJson(e)).toList(),
      textChannels: (map['textChannels'] as List?)?.map((e) => ClmTextChannel.fromJson(e)).toList() ?? [],
    );
  }
}
