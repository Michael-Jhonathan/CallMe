import 'package:flutter/material.dart';
import '../theme.dart';
import 'package:app/l10n/app_localizations.dart';

class HomeFooter extends StatelessWidget {
  final VoidCallback onCreateServer;
  final VoidCallback onJoinServer;

  const HomeFooter({
    super.key,
    required this.onCreateServer,
    required this.onJoinServer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: CallMeTheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: CallMeTheme.outlineVariant, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(child: _buildFooterButton(Icons.add, AppLocalizations.of(context)!.createServer, true, onCreateServer)),
            Expanded(child: _buildFooterButton(Icons.login, AppLocalizations.of(context)!.join, false, onJoinServer)),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterButton(IconData icon, String label, bool isActive, VoidCallback onTap) {
    final contentColor = isActive ? CallMeTheme.onSecondaryContainer : CallMeTheme.onSurfaceVariant;
    final textColor = isActive ? CallMeTheme.onSurface : CallMeTheme.outline;
    final bgColor = isActive ? CallMeTheme.secondaryContainer : Colors.transparent;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          hoverColor: CallMeTheme.surfaceContainerHighest,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: contentColor, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: CallMeTheme.textTheme.labelSmall?.copyWith(
                    color: textColor,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
