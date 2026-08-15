import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'package:core_protocol/core_protocol.dart';

class ChannelAdminDialog extends StatefulWidget {
  final dynamic channel; // ClmTextChannel or ClmChannel

  const ChannelAdminDialog({super.key, required this.channel});

  @override
  State<ChannelAdminDialog> createState() => _ChannelAdminDialogState();
}

class _ChannelAdminDialogState extends State<ChannelAdminDialog> {
  late TextEditingController _nameController;
  late TextEditingController _contentController;
  late bool isTextChannel;

  @override
  void initState() {
    super.initState();
    isTextChannel = widget.channel is ClmTextChannel;
    _nameController = TextEditingController(
        text: isTextChannel ? (widget.channel as ClmTextChannel).title : (widget.channel as ClmChannel).name);
    _contentController = TextEditingController(
        text: isTextChannel ? (widget.channel as ClmTextChannel).content : '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CallMeTheme.surfaceLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: isTextChannel ? 600 : null,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: isTextChannel ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isTextChannel ? 'Editar Canal de Texto' : 'Editar Canal de Voz',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CallMeTheme.onSurface),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: CallMeTheme.onSurfaceVariant),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'NOME DO CANAL',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: CallMeTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: CallMeTheme.onSurface),
              decoration: InputDecoration(
                filled: true,
                fillColor: CallMeTheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            if (isTextChannel) ...[
              const SizedBox(height: 24),
              const Text(
                'CONTEÚDO (MARKDOWN)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: CallMeTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  style: const TextStyle(color: CallMeTheme.onSurface),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: CallMeTheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    hintText: 'Escreva suas regras ou avisos aqui...',
                    hintStyle: const TextStyle(color: CallMeTheme.onSurfaceVariant),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  final appState = context.read<AppState>();
                  if (isTextChannel) {
                    appState.updateTextChannel((widget.channel as ClmTextChannel).id, _nameController.text, _contentController.text);
                  } else {
                    appState.updateVoiceChannel((widget.channel as ClmChannel).id, _nameController.text);
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CallMeTheme.primaryContainer,
                  foregroundColor: CallMeTheme.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                child: const Text('Salvar Alterações', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
