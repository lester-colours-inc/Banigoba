// The link and its QR code, with every way to send it (K-9): WhatsApp (the
// shop picks the groups in WhatsApp itself), any other app, the QR as a
// picture, or a copied link. Also says who in Banigoba is being told.
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:banigoba/modules/shop/models/shop_link.dart';

class ShareShopLinkPanel extends StatelessWidget {
  const ShareShopLinkPanel({
    super.key,
    required this.link,
    required this.onWhatsApp,
    required this.onShareMore,
    required this.onShareQr,
    required this.onCopy,
  });

  final ShopLink link;
  final VoidCallback onWhatsApp;
  final VoidCallback onShareMore;
  final VoidCallback onShareQr;
  final VoidCallback onCopy;

  String get _inApp => switch (link.audience) {
    ShareAudience.linkOnly =>
      'Only people you send it to will see it. Nobody in Banigoba is told.',
    ShareAudience.friends => 'Your friends are being told in Banigoba.',
    ShareAudience.followers => 'Your followers are being told in Banigoba.',
    ShareAudience.public =>
      'Your followers are being told, and it shows to everyone in Community.',
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text(
          link.title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          link.scopeLabel,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: QrImageView(
              data: link.url,
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SelectableText(
          link.url,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.primary),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          key: const ValueKey('share_whatsapp'),
          onPressed: onWhatsApp,
          icon: const Icon(Icons.chat),
          label: const Text('Send on WhatsApp'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF128C7E),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'WhatsApp opens with the message ready: choose the groups and '
          'chats to send it to (WhatsApp allows a few at a time; send again '
          'for more groups).',
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('share_more'),
                onPressed: onShareMore,
                icon: const Icon(Icons.ios_share),
                label: const Text('Other apps'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('share_qr'),
                onPressed: onShareQr,
                icon: const Icon(Icons.qr_code),
                label: const Text('Send QR'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('copy_link'),
                onPressed: onCopy,
                icon: const Icon(Icons.link),
                label: const Text('Copy'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(_inApp),
        ),
      ],
    );
  }
}
