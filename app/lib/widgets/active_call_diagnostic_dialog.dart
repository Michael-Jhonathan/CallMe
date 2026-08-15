import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../webrtc/voice_manager.dart';
import 'package:core_protocol/core_protocol.dart';

class ActiveCallDiagnosticDialog extends StatelessWidget {
  final String channelId;
  final List<ClmMember> members;

  const ActiveCallDiagnosticDialog({
    super.key,
    required this.channelId,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final voiceManager = appState.voiceManager;

    if (voiceManager == null || !voiceManager.isInCall) {
      return AlertDialog(
        backgroundColor: CallMeTheme.surfaceContainer,
        title: Text('Diagnóstico da Chamada', style: TextStyle(color: CallMeTheme.onSurface)),
        content: Text('Você não está conectado a nenhuma chamada.', style: TextStyle(color: CallMeTheme.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar', style: TextStyle(color: CallMeTheme.primary)),
          ),
        ],
      );
    }

    final localId = appState.publicKeyHex;
    final otherMembers = members.where((m) => m.id != localId).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: CallMeTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CallMeTheme.outline.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart, color: CallMeTheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Diagnóstico da Chamada',
                    style: CallMeTheme.textTheme.titleMedium?.copyWith(
                      color: CallMeTheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: CallMeTheme.onSurfaceVariant),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Acompanhe como o áudio está sendo transferido entre você e cada participante desta chamada.',
              style: CallMeTheme.textTheme.bodyMedium?.copyWith(color: CallMeTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            if (otherMembers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Você está sozinho no canal.',
                    style: TextStyle(color: CallMeTheme.onSurfaceVariant.withValues(alpha: 0.7)),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: otherMembers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final member = otherMembers[index];
                    final connType = voiceManager.peerConnectionTypes[member.id];

                    IconData statusIcon;
                    Color statusColor;
                    String statusText;
                    String subText;

                    switch (connType) {
                      case VoiceConnectionType.webrtcP2p:
                        statusIcon = Icons.lan;
                        statusColor = Colors.greenAccent;
                        statusText = "Conexão Direta (P2P)";
                        subText = "WebRTC ativo (IPv6 ou Open IPv4). Atraso mínimo, melhor qualidade.";
                        break;
                      case VoiceConnectionType.mqttRelay:
                        statusIcon = Icons.cloud_sync;
                        statusColor = Colors.orangeAccent;
                        statusText = "MQTT Relay (Stealth)";
                        subText = "CGNAT detectado. Áudio roteado via infraestrutura Stealth.";
                        break;
                      case VoiceConnectionType.connecting:
                      default:
                        statusIcon = Icons.sync;
                        statusColor = CallMeTheme.primary;
                        statusText = "Conectando...";
                        subText = "Negociando rota ICE / Holepunching.";
                        break;
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CallMeTheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: CallMeTheme.primary.withValues(alpha: 0.2),
                            child: Text(
                              member.name.substring(0, 1).toUpperCase(),
                              style: TextStyle(color: CallMeTheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name,
                                  style: const TextStyle(color: CallMeTheme.onSurface, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(statusIcon, color: statusColor, size: 14),
                                    const SizedBox(width: 4),
                                    Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(subText, style: const TextStyle(color: CallMeTheme.onSurfaceVariant, fontSize: 11)),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),

          ],
        ),
      ),
    );
  }
}
