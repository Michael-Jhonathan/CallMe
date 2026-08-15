import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import 'package:app/l10n/app_localizations.dart';

class DonationDialog extends StatelessWidget {
  const DonationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final pixKey = dotenv.env['DONATION_PIX_KEY'];
    final btc = dotenv.env['DONATION_CRYPTO_BTC'];
    final usdt = dotenv.env['DONATION_CRYPTO_USDT'];
    final liberapay = dotenv.env['DONATION_LIBERAPAY_URL'];

    return Dialog(
      backgroundColor: CallMeTheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.supportButton,
                  style: CallMeTheme.textTheme.titleLarge?.copyWith(
                    color: CallMeTheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: CallMeTheme.onSurfaceVariant,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.donationDesc,
              style: CallMeTheme.textTheme.bodyMedium?.copyWith(
                color: CallMeTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (pixKey != null && pixKey.isNotEmpty)
                      _buildCopyableOption(
                        context,
                        title: 'Pix (Brasil)',
                        icon: Icons.pix,
                        data: pixKey,
                        qrData:
                            pixKey, // Normally requires a BR Code Payload, but sending the key to generate a generic QR or just for display is okay, though for real Pix QR you need a Payload generator. We just show the key.
                      ),
                    if (btc != null && btc.isNotEmpty)
                      _buildCopyableOption(
                        context,
                        title: 'Bitcoin (BTC)',
                        icon: Icons.currency_bitcoin,
                        data: btc,
                        qrData: 'bitcoin:$btc',
                      ),
                    if (usdt != null && usdt.isNotEmpty)
                      _buildCopyableOption(
                        context,
                        title: 'Tether (USDT - Rede BEP20)',
                        icon: Icons.attach_money,
                        data: usdt,
                        qrData: usdt,
                      ),
                    if (liberapay != null && liberapay.isNotEmpty)
                      _buildLinkOption(
                        context,
                        title: 'Liberapay (Cartão)',
                        icon: Icons.favorite,
                        url: liberapay,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyableOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String data,
    required String qrData,
  }) {
    return Card(
      color: CallMeTheme.surfaceContainerHighest,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: CallMeTheme.primary),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: CallMeTheme.onSurface,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 150.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: CallMeTheme.surfaceLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            data,
                            style: const TextStyle(
                              color: CallMeTheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.copy,
                            size: 20,
                            color: CallMeTheme.primary,
                          ),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: data));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$title copiado!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String url,
  }) {
    return Card(
      color: CallMeTheme.surfaceContainerHighest,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: CallMeTheme.primary),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: CallMeTheme.onSurface,
          ),
        ),
        trailing: const Icon(
          Icons.open_in_new,
          size: 20,
          color: CallMeTheme.onSurfaceVariant,
        ),
        onTap: () async {
          final uri = Uri.parse(url);
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Não foi possível abrir o link.')),
              );
            }
          }
        },
      ),
    );
  }
}
