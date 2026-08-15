import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import 'package:core_protocol/core_protocol.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cryptography/cryptography.dart';
import '../webrtc/voice_manager.dart';
import '../webrtc/topology_manager.dart';
import '../theme.dart';

class AppState extends ChangeNotifier {
  ClmFile? currentServer;
  String currentUserName = "CallmeUser"; // Nome padrão

  SimpleKeyPair? identity;
  String? publicKeyHex;

  late ClmRelay relay;

  // Variáveis de Aparência
  Color? appColor;
  String? appBackgroundImagePath;
  String? notifBackgroundImagePath;
  String appFontFamily = 'Inter';
  Color? speakingColor;
  bool enableNeonEffect = true;

  // Idioma
  Locale currentLocale = const Locale('pt');

  // Variáveis de Processamento de Áudio (WebRTC)
  bool enableEchoCancellation = true;
  bool enableNoiseSuppression = true;
  bool enableAutoGainControl = true;

  // Cache anti-loop para não responder múltiplos VoiceJoinSignals (Ping-Pong) seguidos
  final Set<String> _recentPingPongs = {};

  List<ClmFile> savedServers = [];
  Map<String, List<ClmMember>> pendingRequests = {};
  Map<String, String> _pendingInvitesKeys = {}; // Armazena chaves AES temporárias de servidores que estamos tentando entrar

  Map<String, List<ClmMember>> connectedVoiceMembers = {
    '1': [
      ClmMember(id: 'mock1', name: 'John Doe', isAdmin: false),
      ClmMember(id: 'mock2', name: 'Jane Smith', isAdmin: false),
    ],
  };

  /// ID do canal de voz em que o usuário local está no momento
  String? activeVoiceChannelId;

  /// Motor WebRTC de áudio
  VoiceManager? voiceManager;

  /// Renderers de áudio para a Web (widgets ocultos)
  List<dynamic> get webAudioRenderers => voiceManager?.webRenderers ?? [];

  bool get isCurrentUserAdmin {
    if (currentServer == null || publicKeyHex == null) return false;
    return currentServer!.members.any((m) => m.id == publicKeyHex && m.isAdmin);
  }

  void _updateServer(ClmFile updatedServer) {
    final index = savedServers.indexWhere(
      (s) => s.serverId == updatedServer.serverId,
    );
    if (index != -1) {
      savedServers[index] = updatedServer;
      if (currentServer?.serverId == updatedServer.serverId) {
        currentServer = updatedServer;
      }
      _persistServers();
      notifyListeners();
    }
  }

  Future<void> renameServer(String newName) async {
    if (currentServer == null) return;
    final delta = RenameServerDelta(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      newName: newName,
    );
    dispatchDelta(delta);
  }

  List<ClmMember> getPendingRequests() {
    if (currentServer == null) return [];
    if (!pendingRequests.containsKey(currentServer!.serverId)) {
      pendingRequests[currentServer!.serverId] = [];
    }
    return pendingRequests[currentServer!.serverId]!;
  }

  void dispatchDeltaForServer(ClmDelta delta, ClmFile targetServer) {
    if (publicKeyHex == null) return;

    // Broadcast using the OLD member list so kicked members receive the signal!
    final signal = DeltaSyncSignal(
      serverId: targetServer.serverId,
      deltaBytes: delta.toBytes(),
    );
    final bytes = signal.toBytes();
    for (var member in targetServer.members) {
      if (member.id != publicKeyHex) {
        _sendEncryptedSignaling(member.id, bytes, targetServer.serverAesKey);
      }
    }

    // Apply locally
    final updatedServer = delta.applyTo(targetServer);
    _updateServer(updatedServer);
  }

  void dispatchDelta(ClmDelta delta) {
    if (currentServer == null) return;
    dispatchDeltaForServer(delta, currentServer!);
  }

  Future<void> approveJoinRequest(ClmMember requestMember) async {
    if (currentServer == null) return;

    final delta = AddMemberDelta(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      member: requestMember,
    );
    dispatchDelta(delta);

    pendingRequests[currentServer!.serverId]?.removeWhere(
      (m) => m.id == requestMember.id,
    );
    notifyListeners();

    // Send JOIN_ACCEPTED to the friend via Relay
    if (publicKeyHex != null) {
      final signal = JoinAcceptedSignal(serverData: currentServer!.toBytes());
      _sendEncryptedSignaling(requestMember.id, signal.toBytes(), currentServer!.serverAesKey);
    }
  }

  void denyJoinRequest(String memberId) {
    if (currentServer == null) return;
    pendingRequests[currentServer!.serverId]?.removeWhere(
      (m) => m.id == memberId,
    );
    notifyListeners();
  }

  void kickMember(String memberId) {
    if (currentServer == null || !isCurrentUserAdmin) return;
    final delta = RemoveMemberDelta(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      memberId: memberId,
    );
    dispatchDelta(delta);
  }

  void leaveServer(String serverId) {
    if (publicKeyHex == null) return;
    final targetServer = savedServers.firstWhere((s) => s.serverId == serverId);

    final delta = RemoveMemberDelta(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      memberId: publicKeyHex!,
    );
    // Broadcast before we delete it locally
    final signal = DeltaSyncSignal(
      serverId: targetServer.serverId,
      deltaBytes: delta.toBytes(),
    );
    final bytes = signal.toBytes();
    for (var member in targetServer.members) {
      if (member.id != publicKeyHex) {
        _sendEncryptedSignaling(member.id, bytes, targetServer.serverAesKey);
      }
    }

    // Apaga do disco
    savedServers.removeWhere((s) => s.serverId == serverId);
    if (currentServer?.serverId == serverId) {
      currentServer = savedServers.isNotEmpty ? savedServers.last : null;
    }
    _persistServers();
    notifyListeners();
  }

  Future<void> updateTextChannel(
    String id,
    String newTitle,
    String newContent,
  ) async {
    if (currentServer == null) return;
    final delta = SetTextChannelDelta(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      channel: ClmTextChannel(id: id, title: newTitle, content: newContent),
    );
    dispatchDelta(delta);
  }

  Future<void> updateVoiceChannel(String id, String newName) async {
    if (currentServer == null) return;
    // Opcodes future implementation. For now, fallback to local rewrite (não é chamado na UI)
  }

  Future<void> addVoiceChannel(String name) async {
    if (currentServer == null) return;
    final delta = AddChannelDelta(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      channel: ClmChannel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
      ),
    );
    dispatchDelta(delta);
  }

  void _broadcastSignaling(ClmSignal signal) {
    if (currentServer == null || publicKeyHex == null) return;
    final bytes = signal.toBytes();
    for (var member in currentServer!.members) {
      if (member.id != publicKeyHex) {
        _sendEncryptedSignaling(member.id, bytes, currentServer!.serverAesKey);
      }
    }
  }

  Future<void> _sendEncryptedSignaling(String targetPeerId, Uint8List payload, String? aesKey) async {
    var finalPayload = payload;
    if (aesKey != null) {
      finalPayload = await ClmCypher.encryptPayload(payload, aesKey);
    }
    await relay.sendSignaling(targetPeerId, finalPayload);
  }

  Future<void> joinVoiceChannel(String channelId) async {
    if (publicKeyHex == null || currentServer == null) return;

    // Remove do antigo (se houver) localmente e avisa a rede
    String? oldChannel;
    connectedVoiceMembers.forEach((key, list) {
      if (list.any((m) => m.id == publicKeyHex)) {
        oldChannel = key;
      }
      list.removeWhere((m) => m.id == publicKeyHex);
    });

    if (oldChannel != null) {
      _broadcastSignaling(
        VoiceLeaveSignal(
          serverId: currentServer!.serverId,
          channelId: oldChannel!,
          memberId: publicKeyHex!,
        ),
      );
    }

    // Adiciona no novo
    if (!connectedVoiceMembers.containsKey(channelId)) {
      connectedVoiceMembers[channelId] = [];
    }
    connectedVoiceMembers[channelId]!.add(
      ClmMember(
        id: publicKeyHex!,
        name: currentUserName,
        isAdmin: isCurrentUserAdmin,
      ),
    );

    // Avisa a rede
    _broadcastSignaling(
      VoiceJoinSignal(
        serverId: currentServer!.serverId,
        channelId: channelId,
        memberId: publicKeyHex!,
        memberName: currentUserName,
        isAdmin: isCurrentUserAdmin,
      ),
    );

    // Inicia o motor WebRTC: primeiro captura o mic, depois conecta com peers
    activeVoiceChannelId = channelId;
    if (voiceManager != null) {
      // Injeta o channelId para o fallback MQTT saber qual canal usar
      voiceManager!.currentChannelId = channelId;
      voiceManager!.currentAesKey = currentServer?.serverAesKey;

      final existingPeers = (connectedVoiceMembers[channelId] ?? [])
          .where(
            (m) => m.id != publicKeyHex && m.id != 'mock1' && m.id != 'mock2',
          )
          .map((m) => m.id)
          .toList();
      await voiceManager!.joinCallAndConnect(existingPeers);

      // Mostra a notificação persistente da chamada
      NotificationService().showCallNotification(
        backgroundImagePath: notifBackgroundImagePath,
      );
    }

    notifyListeners();
  }

  void leaveVoiceChannel(String channelId) {
    if (publicKeyHex == null || currentServer == null) return;
    if (connectedVoiceMembers.containsKey(channelId)) {
      connectedVoiceMembers[channelId]!.removeWhere(
        (m) => m.id == publicKeyHex,
      );

      // Avisa a rede
      _broadcastSignaling(
        VoiceLeaveSignal(
          serverId: currentServer!.serverId,
          channelId: channelId,
          memberId: publicKeyHex!,
        ),
      );

      // Encerra WebRTC e background
      activeVoiceChannelId = null;
      if (voiceManager != null) {
        voiceManager!.leaveCall();
        // Remove a notificação da chamada
        NotificationService().cancelCallNotification();
      }
      notifyListeners();
    }
  }

  AppState() {
    _loadServers();
    _initIdentity();
  }

  Future<void> _initIdentity() async {
    final prefs = await SharedPreferences.getInstance();

    // Carrega preferências de aparência
    final colorVal = prefs.getInt('app_color');
    if (colorVal != null) {
      appColor = Color(colorVal);
      CallMeTheme.updatePrimaryColor(appColor!);
    }
    appBackgroundImagePath = prefs.getString('app_bg_image');
    notifBackgroundImagePath = prefs.getString('notif_bg_image');
    appFontFamily = prefs.getString('app_font') ?? 'Inter';

    final savedLocale = prefs.getString('app_locale');
    if (savedLocale != null) {
      currentLocale = Locale(savedLocale);
    }

    final speakingColorVal = prefs.getInt('speaking_color');
    if (speakingColorVal != null) {
      speakingColor = Color(speakingColorVal);
    }
    enableNeonEffect = prefs.getBool('enable_neon') ?? true;

    // Configurações de áudio
    enableEchoCancellation = prefs.getBool('enable_aec') ?? true;
    enableNoiseSuppression = prefs.getBool('enable_ns') ?? true;
    enableAutoGainControl = prefs.getBool('enable_agc') ?? true;

    CallMeTheme.updateFontFamily(appFontFamily);
    final savedPriv = prefs.getString('identity_priv');
    final savedPub = prefs.getString('identity_pub');

    if (savedPriv != null && savedPub != null) {
      identity = SimpleKeyPairData(
        base64Decode(savedPriv),
        publicKey: SimplePublicKey(
          base64Decode(savedPub),
          type: KeyPairType.ed25519,
        ),
        type: KeyPairType.ed25519,
      );
    } else {
      identity = await ClmIdentity.generateKeyPair();
      final privBytes = await identity!.extractPrivateKeyBytes();
      final pubKey = await identity!.extractPublicKey();
      await prefs.setString('identity_priv', base64Encode(privBytes));
      await prefs.setString('identity_pub', base64Encode(pubKey.bytes));
    }

    publicKeyHex = await ClmIdentity.getPublicKeyHex(identity!);

    // Carrega o nickname salvo
    final savedName = prefs.getString('user_name');
    if (savedName != null && savedName.isNotEmpty) {
      currentUserName = savedName;
    }

    // Initialize Relay for Signaling
    relay = ClmRelay(publicKeyHex!); // Use our pubkey as the MQTT client ID
    relay.onMessageReceived = _handleMqttMessage;

    // Initialize Notification Service
    await NotificationService().init(this);
    final connected = await relay.connect();
    if (connected) {
      relay.listenToSignaling(publicKeyHex!);
      for (final server in savedServers) {
        relay.listenToServerDeltas(server.serverId);
      }
    }

    // Inicializa o VoiceManager
    voiceManager = VoiceManager(
      localPeerId: publicKeyHex!,
      onSendSignal: (targetPeerId, signal) async {
        await _sendEncryptedSignaling(targetPeerId, signal.toBytes(), currentServer?.serverAesKey);
      },
      onStateChanged: () {
        notifyListeners();
        // Atualiza a notificação persistente sempre que o estado de mute muda
        NotificationService().showCallNotification(
          isUpdate: true,
          backgroundImagePath: notifBackgroundImagePath,
        );
      },
      echoCancellation: enableEchoCancellation,
      noiseSuppression: enableNoiseSuppression,
      autoGainControl: enableAutoGainControl,
    );
    // Injeta o relay no VoiceManager para o fallback MQTT
    voiceManager!.mqttRelay = relay;

    // Inicializa o TopologyManager para a transição dinâmica Mesh/SFU
    voiceManager!.topologyManager = TopologyManager(
      localPeerId: publicKeyHex!,
      onBroadcastMetrics: (signal) async {
        _broadcastSignaling(signal);
      },
      onTopologyChanged: (topology, supernodes, assignedSupernodeId) {
        voiceManager?.applyTopology(topology, supernodes, assignedSupernodeId);
      },
      onGetLocalRtt: () async {
        return (await voiceManager?.measureLocalRtt()) ?? 999;
      },
    );
  }

  /// Dispatcher central de mensagens MQTT.
  /// Separa tópicos de áudio de voz dos tópicos de sinalização.
  void _handleMqttMessage(String topic, Uint8List payload) {
    if (topic.startsWith('callme/voice/')) {
      // Formato: callme/voice/{channelId}/{senderId}
      final parts = topic.split('/');
      if (parts.length >= 4) {
        final senderId = parts[3];
        // O voiceManager será responsável por tentar descriptografar o áudio (pois ele tem acesso à chave)
        voiceManager?.handleMqttVoiceChunk(senderId, payload);
      }
      return;
    }
    // Qualquer outra mensagem é sinalização
    _handleSignalingMessage(topic, payload);
  }

  void _handleSignalingMessage(String topic, Uint8List payload) async {
    Uint8List? decryptedPayload;

    // Tenta descriptografar usando as chaves dos servidores conhecidos
    for (var server in savedServers) {
      if (server.serverAesKey != null) {
        final attempt = await ClmCypher.decryptPayload(payload, server.serverAesKey!);
        if (attempt != null) {
          decryptedPayload = attempt;
          break; // Sucesso!
        }
      }
    }

    // Se falhou, tenta com as chaves temporárias (convites pendentes)
    if (decryptedPayload == null) {
      for (var key in _pendingInvitesKeys.values) {
        final attempt = await ClmCypher.decryptPayload(payload, key);
        if (attempt != null) {
          decryptedPayload = attempt;
          break;
        }
      }
    }

    // Se não conseguiu descriptografar com nenhuma chave conhecida (ou se o pacote não tem E2EE - legado)
    final finalPayload = decryptedPayload ?? payload;

    try {
      final signal = ClmSignal.fromBytes(finalPayload);

      if (signal is JoinRequestSignal) {
        debugPrint(
          'Recebido JoinRequestSignal para o servidor: ${signal.serverId} de ${signal.friendPub}',
        );
        final serverId = signal.serverId;
        final friendPub = signal.friendPub;
        final friendName = signal.friendName;

        // Ensure the server exists
        if (!savedServers.any((s) => s.serverId == serverId)) {
          throw Exception('Server not found');
        }

        if (!pendingRequests.containsKey(serverId)) {
          pendingRequests[serverId] = [];
        }

        // Add to pending requests if not already there
        if (!pendingRequests[serverId]!.any((m) => m.id == friendPub)) {
          pendingRequests[serverId]!.add(
            ClmMember(id: friendPub, name: friendName, isAdmin: false),
          );
          notifyListeners();
        }
      } else if (signal is JoinAcceptedSignal) {
        try {
          final joinedServer = ClmFile.fromBytes(signal.serverData);

          final existingIdx = savedServers.indexWhere(
            (s) => s.serverId == joinedServer.serverId,
          );
          if (existingIdx >= 0) {
            savedServers[existingIdx] = joinedServer;
          } else {
            savedServers.add(joinedServer);
          }
          currentServer = joinedServer;
          _persistServers();
          relay.listenToServerDeltas(joinedServer.serverId);
          _pendingInvitesKeys.remove(joinedServer.serverId);
          notifyListeners();
        } catch (e) {
          debugPrint('Error parsing JoinAcceptedSignal: $e');
        }
      } else if (signal is VoiceJoinSignal) {
        if (currentServer != null &&
            currentServer!.serverId == signal.serverId) {
          if (!connectedVoiceMembers.containsKey(signal.channelId)) {
            connectedVoiceMembers[signal.channelId] = [];
          }
          // Verifica se o peer já estava na lista

          connectedVoiceMembers[signal.channelId]!.removeWhere(
            (m) => m.id == signal.memberId,
          );
          connectedVoiceMembers[signal.channelId]!.add(
            ClmMember(
              id: signal.memberId,
              name: signal.memberName,
              isAdmin: signal.isAdmin,
            ),
          );

          // Se o peer local está no mesmo canal ativo, responde com o sinal local (ping-pong)
          // Usamos um cache temporário (_recentPingPongs) para evitar loop infinito,
          // ao invés de usar wasAlreadyInList, o que causava bugs com usuários "fantasmas" (crash/reconnect).
          if (activeVoiceChannelId == signal.channelId &&
              voiceManager != null &&
              publicKeyHex != null) {
            if (!_recentPingPongs.contains(signal.memberId)) {
              _recentPingPongs.add(signal.memberId);
              // Limpa o cache após 3 segundos
              Future.delayed(const Duration(seconds: 3), () {
                _recentPingPongs.remove(signal.memberId);
              });

              // Responde diretamente ao peer com o estado local
              final response = VoiceJoinSignal(
                serverId: currentServer!.serverId,
                channelId: signal.channelId,
                memberId: publicKeyHex!,
                memberName: currentUserName,
                isAdmin: isCurrentUserAdmin,
              );
              _sendEncryptedSignaling(signal.memberId, response.toBytes(), currentServer!.serverAesKey);
            }
          }

          // A conexão WebRTC é iniciada localmente, independente do Ping-Pong,
          // para garantir que o Polido e o Impolido estabeleçam as ofertas (Prevenção de Deadlock)
          if (activeVoiceChannelId == signal.channelId &&
              voiceManager != null) {
            voiceManager!.connectToPeer(signal.memberId);
            final activeMembers =
                connectedVoiceMembers[signal.channelId]
                    ?.map((m) => m.id)
                    .toList() ??
                [];
            voiceManager!.topologyManager?.onMemberCountChanged(
              signal.channelId,
              activeMembers,
            );
          }
          notifyListeners();
        }
      } else if (signal is VoiceLeaveSignal) {
        if (currentServer != null &&
            currentServer!.serverId == signal.serverId) {
          if (connectedVoiceMembers.containsKey(signal.channelId)) {
            connectedVoiceMembers[signal.channelId]!.removeWhere(
              (m) => m.id == signal.memberId,
            );

            // Desconecta o peer do WebRTC
            voiceManager?.disconnectFromPeer(signal.memberId);

            if (activeVoiceChannelId == signal.channelId) {
              final activeMembers =
                  connectedVoiceMembers[signal.channelId]
                      ?.map((m) => m.id)
                      .toList() ??
                  [];
              voiceManager?.topologyManager?.onMemberCountChanged(
                signal.channelId,
                activeMembers,
              );
            }

            notifyListeners();
          }
        }
      } else if (signal is WebrtcSignal) {
        // Roteia para o VoiceManager processar (async para não bloquear)
        voiceManager?.handleSignal(signal);
      } else if (signal is TopologyMetricsSignal) {
        voiceManager?.topologyManager?.onMetricsReceived(signal);
      } else if (signal is DeltaSyncSignal) {
        try {
          final serverToUpdate = savedServers.firstWhere(
            (s) => s.serverId == signal.serverId,
          );
          final delta = ClmDelta.fromBytes(signal.deltaBytes);
          final updatedServer = delta.applyTo(serverToUpdate);

          final idx = savedServers.indexOf(serverToUpdate);
          savedServers[idx] = updatedServer;

          if (currentServer?.serverId == updatedServer.serverId) {
            currentServer = updatedServer;
          }

          // Auto-Expulsão (Kicked)
          if (delta is RemoveMemberDelta && delta.memberId == publicKeyHex) {
            savedServers.removeAt(idx);
            if (currentServer?.serverId == signal.serverId) {
              currentServer = savedServers.isNotEmpty
                  ? savedServers.last
                  : null;
            }
          }

          _persistServers();
          notifyListeners();
        } catch (e) {
          debugPrint('Server not found for delta sync or invalid delta: $e');
        }
      }
    } catch (e) {
      debugPrint('Error processing signaling message: $e');
    }
  }

  Future<void> requestJoinServer(String inviteCode) async {
    if (publicKeyHex == null) return;

    // The inviteCode is now "{serverId}@{aesKeyBase64}"
    final split = inviteCode.split('@');
    final serverId = split[0];
    final aesKey = split.length > 1 ? split[1] : null;

    if (aesKey != null) {
      _pendingInvitesKeys[serverId] = aesKey;
    }

    // The serverId is usually "{creatorPub}_timestamp". We extract the pubkey.
    final parts = serverId.split('_');
    if (parts.isEmpty) return;
    final creatorPub = parts[0];

    final signal = JoinRequestSignal(
      serverId: serverId,
      friendPub: publicKeyHex!,
      friendName: currentUserName,
    );

    debugPrint(
      'Enviando JoinRequestSignal E2EE para o criador: $creatorPub, servidor: $serverId',
    );
    await _sendEncryptedSignaling(creatorPub, signal.toBytes(), aesKey);
  }

  Future<void> _loadServers() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList('saved_servers_list');

    if (savedList != null) {
      savedServers.clear();
      for (var base64Data in savedList) {
        try {
          final bytes = base64Decode(base64Data);
          savedServers.add(ClmFile.fromBytes(bytes));
        } catch (e) {
          // Ignora arquivos corrompidos
        }
      }
      // if (savedServers.isNotEmpty) {
      //   currentServer = savedServers.last; // Foca no último adicionado ou criado
      // }
    }
    notifyListeners();
  }

  Future<void> _persistServers() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedList = savedServers
        .map((s) => base64Encode(s.toBytes()))
        .toList();
    await prefs.setStringList('saved_servers_list', encodedList);
  }

  void switchServer(ClmFile server) {
    // Compara por serverId, não por referência de objeto (objetos desserializados são diferentes)
    final match = savedServers.firstWhere(
      (s) => s.serverId == server.serverId,
      orElse: () => server,
    );
    currentServer = match;
    notifyListeners();
  }

  Future<void> createServer(String name) async {
    if (identity == null) {
      await _initIdentity();
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final serverId = '${publicKeyHex}_$timestamp';

    final creator = ClmMember(
      id: publicKeyHex!,
      name: currentUserName,
      isAdmin: true,
    );

    final generalVoice = ClmChannel(id: 'voice_$timestamp', name: 'Geral');
    final welcomeText = ClmTextChannel(
      id: 'text_$timestamp',
      title: 'Boas-vindas',
      content: 'Bem-vindo ao nosso servidor P2P Seguro!',
    );

    // E2EE: Gera uma chave AES exclusiva para este servidor
    final serverAesKey = await ClmCypher.generateAesKeyBase64();

    final newServer = ClmFile(
      serverId: serverId,
      timestamp: timestamp,
      serverName: name,
      serverAesKey: serverAesKey,
      members: [creator],
      channels: [generalVoice],
      textChannels: [welcomeText],
    );

    savedServers.add(newServer);
    currentServer = newServer;

    relay.listenToServerDeltas(newServer.serverId);

    await _persistServers();
    notifyListeners();
  }

  void setUserName(String newName) {
    currentUserName = newName;

    // Persiste o nickname no disco
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('user_name', newName);
    });

    // Atualiza o nome em todos os servidores do qual eu faço parte
    if (publicKeyHex != null) {
      final serversToUpdate = List<ClmFile>.from(savedServers);
      for (var server in serversToUpdate) {
        final myMember = server.members
            .where((m) => m.id == publicKeyHex)
            .firstOrNull;
        if (myMember != null) {
          final delta = UpdateMemberDelta(
            timestamp: DateTime.now().millisecondsSinceEpoch,
            member: ClmMember(
              id: publicKeyHex!,
              name: newName,
              isAdmin: myMember.isAdmin,
            ),
          );
          dispatchDeltaForServer(delta, server);
        }
      }
    }
    notifyListeners();
  }

  /// Gera os bytes do backup usando a senha fornecida
  Future<Uint8List?> exportBackup(String password) async {
    if (identity == null || publicKeyHex == null) return null;

    final privBytes = await identity!.extractPrivateKeyBytes();
    final pubKey = await identity!.extractPublicKey();

    final backup = ClmBackup(
      userName: currentUserName,
      privateKeyBase64: base64Encode(privBytes),
      publicKeyBase64: base64Encode(pubKey.bytes),
      savedServers: savedServers,
    );

    return await backup.toBytes(password);
  }

  /// Restaura o backup a partir dos bytes lidos e da senha fornecida
  Future<void> importBackup(Uint8List bytes, String password) async {
    final backup = await ClmBackup.fromBytes(bytes, password);

    final prefs = await SharedPreferences.getInstance();

    // Sobrescreve SharedPreferences
    await prefs.setString('user_name', backup.userName);
    await prefs.setString('identity_priv', backup.privateKeyBase64);
    await prefs.setString('identity_pub', backup.publicKeyBase64);

    final encodedList = backup.savedServers
        .map((s) => base64Encode(s.toBytes()))
        .toList();
    await prefs.setStringList('saved_servers_list', encodedList);

    // O ideal seria reiniciar o app para re-instanciar o Relay, Identity e WebRTC,
    // mas tenta recarregar o estado local
    currentUserName = backup.userName;
    savedServers = backup.savedServers;
    if (savedServers.isNotEmpty) {
      currentServer = savedServers.last;
    } else {
      currentServer = null;
    }

    // Recria identidade
    final privBytes = base64Decode(backup.privateKeyBase64);
    final pubBytes = base64Decode(backup.publicKeyBase64);
    identity = SimpleKeyPairData(
      privBytes,
      publicKey: SimplePublicKey(pubBytes, type: KeyPairType.ed25519),
      type: KeyPairType.ed25519,
    );
    publicKeyHex = await ClmIdentity.getPublicKeyHex(identity!);

    // Precisamos recriar a conexão MQTT com o novo ID
    relay.disconnect();
    relay = ClmRelay(publicKeyHex!);
    relay.onMessageReceived = _handleMqttMessage;
    final connected = await relay.connect();
    if (connected) {
      relay.listenToSignaling(publicKeyHex!);
      for (final server in savedServers) {
        relay.listenToServerDeltas(server.serverId);
      }
    }

    // Reinicia VoiceManager
    if (voiceManager != null) {
      voiceManager!.dispose();
    }
    voiceManager = VoiceManager(
      localPeerId: publicKeyHex!,
      onSendSignal: (targetPeerId, signal) async {
        await _sendEncryptedSignaling(targetPeerId, signal.toBytes(), currentServer?.serverAesKey);
      },
      onStateChanged: () {
        NotificationService().showCallNotification(
          isUpdate: true,
          backgroundImagePath: notifBackgroundImagePath,
        );
        notifyListeners();
      },
    );

    notifyListeners();
  }

  // --- Métodos de Aparência ---
  Future<void> setAppColor(Color color) async {
    appColor = color;
    CallMeTheme.updatePrimaryColor(color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_color', color.toARGB32());
    notifyListeners();
  }

  Future<void> setAppBackgroundImage(String? path) async {
    appBackgroundImagePath = path;
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove('app_bg_image');
    } else {
      await prefs.setString('app_bg_image', path);
    }
    notifyListeners();
  }

  Future<void> setNotifBackgroundImage(String? path) async {
    notifBackgroundImagePath = path;
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove('notif_bg_image');
    } else {
      await prefs.setString('notif_bg_image', path);
    }
    notifyListeners();
  }

  Future<void> setAppFontFamily(String font) async {
    appFontFamily = font;
    CallMeTheme.updateFontFamily(font);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_font', font);
    notifyListeners();
  }

  Future<void> setSpeakingColor(Color color) async {
    speakingColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('speaking_color', color.toARGB32());
    notifyListeners();
  }

  Future<void> setEnableNeonEffect(bool enable) async {
    enableNeonEffect = enable;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_neon', enable);
    notifyListeners();
  }

  Future<void> setAudioFilters({
    required bool echo,
    required bool noise,
    required bool agc,
  }) async {
    enableEchoCancellation = echo;
    enableNoiseSuppression = noise;
    enableAutoGainControl = agc;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_aec', echo);
    await prefs.setBool('enable_ns', noise);
    await prefs.setBool('enable_agc', agc);

    // Se o voiceManager estiver criado, atualizamos as flags nele
    if (voiceManager != null) {
      voiceManager!.echoCancellation = echo;
      voiceManager!.noiseSuppression = noise;
      voiceManager!.autoGainControl = agc;
    }

    notifyListeners();
  }

  Future<void> setLocale(Locale newLocale) async {
    currentLocale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', newLocale.languageCode);
    notifyListeners();
  }
}
