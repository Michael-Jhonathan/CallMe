import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class CallMeBackgroundWrapper extends StatelessWidget {
  final Widget child;

  const CallMeBackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();
    final imagePath = appState.appBackgroundImagePath;

    DecorationImage? decorationImage;
    
    if (imagePath != null && imagePath.isNotEmpty) {
      ImageProvider imageProvider;
      if (imagePath.startsWith('http')) {
        imageProvider = NetworkImage(imagePath);
      } else if (kIsWeb) {
        imageProvider = NetworkImage(imagePath);
      } else {
        imageProvider = FileImage(File(imagePath));
      }
      
      decorationImage = DecorationImage(
        image: imageProvider,
        fit: BoxFit.cover,
        // Aplica uma camada escura sobre a imagem para garantir que os textos do app fiquem legíveis
        colorFilter: ColorFilter.mode(
          theme.colorScheme.surface.withValues(alpha: 0.85),
          BlendMode.darken,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        image: decorationImage,
      ),
      child: child,
    );
  }
}
