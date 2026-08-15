import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../state/app_state.dart';

const String actionMuteMic = 'action_mute_mic';
const String actionMuteSpeaker = 'action_mute_speaker';
const String actionDisconnect = 'action_disconnect';

/// Nome do porto de comunicação entre o isolate de background e o principal.
const String _kPortName = 'callme_notification_port';

/// Handler chamado pelo sistema quando o app está em background.
/// Roda em um isolate separado — não tem acesso ao AppState.
/// Envia a ação via IsolateNameServer para o isolate principal.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  final actionId = notificationResponse.actionId;
  if (actionId == null) return;

  final SendPort? sendPort = IsolateNameServer.lookupPortByName(_kPortName);
  sendPort?.send(actionId);
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  AppState? _appState;
  ReceivePort? _receivePort;

  Future<void> init(AppState appState) async {
    _appState = appState;
    if (kIsWeb) return;

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    }

    // Registra o porto de comunicação com o isolate de background
    _ensurePortRegistered();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // App em foreground — chamado diretamente
        _handleAction(response.actionId);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  void _handleAction(String? actionId) {
    if (actionId == null) return;
    if (_appState == null || _appState!.voiceManager == null) return;

    final vm = _appState!.voiceManager!;

    switch (actionId) {
      case actionMuteMic:
        vm.toggleMicMute();
        // onStateChanged já vai chamar showCallNotification(isUpdate: true)
        break;
      case actionMuteSpeaker:
        vm.toggleSpeakerMute();
        // onStateChanged já vai chamar showCallNotification(isUpdate: true)
        break;
      case actionDisconnect:
        if (_appState!.activeVoiceChannelId != null) {
          _appState!.leaveVoiceChannel(_appState!.activeVoiceChannelId!);
        }
        break;
    }
  }

  /// Garante que o porto de comunicação entre isolates está ativo.
  /// Sempre recria o porto para evitar portos fechados de calls anteriores.
  void _ensurePortRegistered() {
    _receivePort?.close();
    _receivePort = ReceivePort();
    IsolateNameServer.removePortNameMapping(_kPortName);
    IsolateNameServer.registerPortWithName(_receivePort!.sendPort, _kPortName);
    _receivePort!.listen((message) {
      if (message is String) {
        _handleAction(message);
      }
    });
  }

  Future<void> showCallNotification({bool isUpdate = false, String? backgroundImagePath}) async {
    if (kIsWeb || _appState?.voiceManager == null) return;
    // Só atualiza se estiver em chamada ativa
    if (_appState?.activeVoiceChannelId == null) return;

    // Recria o canal de comunicacao apenas ao iniciar uma nova call
    // (não a cada update de estado de mute)
    if (!isUpdate) {
      _ensurePortRegistered();
    }
    final vm = _appState!.voiceManager!;

    final serverName = _appState?.currentServer?.serverName ?? 'Desconhecido';

    String channelName = 'Voz';
    if (_appState?.currentServer != null && _appState?.activeVoiceChannelId != null) {
      final channels = _appState!.currentServer!.channels;
      final idx = channels.indexWhere((c) => c.id == _appState!.activeVoiceChannelId);
      if (idx != -1) channelName = channels[idx].name;
    }

    StyleInformation styleInformation = const MediaStyleInformation();
    
    // Se o usuário tiver um background local configurado, exibe-o como fundo (Large Icon/Big Picture)
    if (backgroundImagePath != null && backgroundImagePath.isNotEmpty && !backgroundImagePath.startsWith('http')) {
      styleInformation = BigPictureStyleInformation(
        FilePathAndroidBitmap(backgroundImagePath),
        contentTitle: 'CallMe - Em Chamada',
        summaryText: '$serverName • $channelName',
        hideExpandedLargeIcon: true,
      );
    }

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'call_channel_id',
      'Chamada Ativa',
      channelDescription: 'Notificação persistente durante chamada de voz',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      category: AndroidNotificationCategory.call,
      styleInformation: styleInformation,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          actionMuteMic,
          vm.isMicMuted ? 'Desmutar' : 'Mutar Mic',
          icon: DrawableResourceAndroidBitmap(vm.isMicMuted ? 'ic_mic_off' : 'ic_mic'),
          showsUserInterface: false,
        ),
        const AndroidNotificationAction(
          'dummy_1',
          '',
          icon: DrawableResourceAndroidBitmap('ic_dummy'),
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          actionMuteSpeaker,
          vm.isSpeakerMuted ? 'Desmutar' : 'Mutar Fone',
          icon: DrawableResourceAndroidBitmap(vm.isSpeakerMuted ? 'ic_headset_off' : 'ic_headset'),
          showsUserInterface: false,
        ),
        const AndroidNotificationAction(
          'dummy_2',
          '',
          icon: DrawableResourceAndroidBitmap('ic_dummy'),
          showsUserInterface: false,
        ),
        const AndroidNotificationAction(
          actionDisconnect,
          'Desconectar',
          icon: DrawableResourceAndroidBitmap('ic_call_end'),
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    if (isUpdate) {
      await _flutterLocalNotificationsPlugin.show(
        id: 888,
        title: 'CallMe - Em Chamada',
        body: '$serverName • $channelName',
        notificationDetails: NotificationDetails(android: androidPlatformChannelSpecifics),
      );
    } else {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.startForegroundService(
            id: 888,
            title: 'CallMe - Em Chamada',
            body: '$serverName • $channelName',
            notificationDetails: androidPlatformChannelSpecifics,
            foregroundServiceTypes: {
              AndroidServiceForegroundType.foregroundServiceTypeMicrophone,
            },
          );
    }
  }

  Future<void> cancelCallNotification() async {
    if (kIsWeb) return;
    _receivePort?.close();
    IsolateNameServer.removePortNameMapping(_kPortName);
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.stopForegroundService();
  }
}