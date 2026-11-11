// "Send to": passes a look to someone specific: inside Banigoba a hair
// salon, shop or designer; outside it WhatsApp or any other app.
//
// Who sees a look in the feeds is a separate action, "Post" (share audience
// sheet). The two used to overlap here; the October 2026 review (P-4) kept
// both and separated them.
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:banigoba/core/services/look_image_share.dart';
import 'package:banigoba/modules/shop/services/shop_chat_service.dart';
import 'package:banigoba/modules/shop/views/shop_chat_page.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';
import 'package:banigoba/modules/social/widgets/forward_recipient_sheet.dart';

enum ForwardDestination { salon, shop, designer, whatsapp, otherApps }

/// The label for this action everywhere it appears.
const String kSendToLabel = 'Send to';

const _shareSignature = 'Styled on Banigoba';

/// Opens the Send to sheet for a look and carries out the chosen send.
Future<void> showForwardLookSheet(
  BuildContext context, {
  required String imageUrl,
  String caption = '',
}) async {
  if (imageUrl.trim().isEmpty) {
    _showMessage(context, 'This look has no picture to send.');
    return;
  }

  final destination = await showModalBottomSheet<ForwardDestination>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _ForwardLookSheet(),
  );
  if (destination == null || !context.mounted) return;

  switch (destination) {
    case ForwardDestination.salon:
      await _forwardInApp(
        context,
        ForwardRecipientKind.salon,
        imageUrl: imageUrl,
        caption: caption,
      );
    case ForwardDestination.shop:
      await _forwardInApp(
        context,
        ForwardRecipientKind.shop,
        imageUrl: imageUrl,
        caption: caption,
      );
    case ForwardDestination.designer:
      await _forwardInApp(
        context,
        ForwardRecipientKind.designer,
        imageUrl: imageUrl,
        caption: caption,
      );
    case ForwardDestination.whatsapp:
    case ForwardDestination.otherApps:
      await _forwardToOtherApps(context, imageUrl: imageUrl, caption: caption);
  }
}

/// The message sent with a look. The link is only added when the picture
/// itself couldn't be attached, so recipients never see a raw storage URL
/// alongside the image.
String shareLookText(String caption, {String? fallbackUrl}) {
  final lead = caption.trim().isEmpty ? 'Check out this look' : caption.trim();
  final link = fallbackUrl == null ? '' : '\n$fallbackUrl';
  return '$lead$link\n\n$_shareSignature';
}

void _showMessage(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  AppToast.show(
    message,
    kind: actionLabel == null ? AppToastKind.info : AppToastKind.success,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

Future<void> _forwardInApp(
  BuildContext context,
  ForwardRecipientKind kind, {
  required String imageUrl,
  required String caption,
}) async {
  final user = AppAuth.instance.currentUser;
  if (user == null) {
    _showMessage(context, 'Sign in to forward looks.');
    return;
  }
  final recipient = await showForwardRecipientSheet(context, kind);
  if (recipient == null || !context.mounted) return;

  final service = ShopChatService();
  try {
    final chatId = switch (kind) {
      ForwardRecipientKind.salon => await service.ensureSalonConversation(
        salonId: recipient.id,
        customerId: user.uid,
        salonName: recipient.name,
      ),
      ForwardRecipientKind.shop => await service.ensureConversation(
        sellerId: recipient.id,
        customerId: user.uid,
        shopName: recipient.name,
      ),
      ForwardRecipientKind.designer => await service.ensureDesignerConversation(
        designerId: recipient.id,
        customerId: user.uid,
        designerName: recipient.name,
      ),
    };
    await service.addLookReference(
      chatId: chatId,
      imageUrl: imageUrl,
      caption: caption,
    );
    if (!context.mounted) return;
    _showMessage(
      context,
      'Look forwarded to ${recipient.name}.',
      actionLabel: 'Open chat',
      onAction: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ShopChatPage(
            chatId: chatId,
            title: recipient.name,
            asSeller: false,
          ),
        ),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    _showMessage(context, 'Unable to forward look: $error');
  }
}

Rect? _shareOrigin(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
}

/// Shares the picture itself where possible (WhatsApp, Instagram, Facebook,
/// TikTok and friends take images, not links), falling back to a link when it
/// can't be downloaded.
Future<void> _forwardToOtherApps(
  BuildContext context, {
  required String imageUrl,
  required String caption,
}) async {
  final origin = _shareOrigin(context);
  final image = await downloadLookImage(imageUrl);
  if (!context.mounted) return;
  await _openShareSheet(
    context,
    text: shareLookText(caption, fallbackUrl: image == null ? imageUrl : null),
    image: image,
    origin: origin,
  );
}

Future<void> _openShareSheet(
  BuildContext context, {
  required String text,
  required LookImage? image,
  required Rect? origin,
}) async {
  try {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'A look from Banigoba',
        files: image == null
            ? null
            : [
                XFile.fromData(
                  image.bytes,
                  mimeType: image.mimeType,
                  name: image.fileName,
                ),
              ],
        sharePositionOrigin: origin,
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    _showMessage(context, 'Unable to share look: $error');
  }
}

class _ForwardLookSheet extends StatelessWidget {
  const _ForwardLookSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel(kSendToLabel, isTitle: true),
            const _SectionLabel('In Banigoba'),
            const _DestinationTile(
              destination: ForwardDestination.salon,
              icon: Icons.content_cut,
              title: 'Hair Salon',
              subtitle: 'Send it to a salon to book this hairstyle.',
            ),
            const _DestinationTile(
              destination: ForwardDestination.shop,
              icon: Icons.storefront_outlined,
              title: 'Shop',
              subtitle: 'Ask a boutique for these pieces.',
            ),
            const _DestinationTile(
              destination: ForwardDestination.designer,
              icon: Icons.design_services_outlined,
              title: 'Designer',
              subtitle: 'Have a designer make something like it.',
            ),
            const _SectionLabel('Other apps'),
            const _DestinationTile(
              destination: ForwardDestination.whatsapp,
              icon: Icons.chat_outlined,
              iconColor: Color(0xFF25D366),
              title: 'WhatsApp',
              subtitle: 'Send it to a chat or group.',
            ),
            const _DestinationTile(
              destination: ForwardDestination.otherApps,
              icon: Icons.ios_share,
              title: 'More apps',
              subtitle: 'Instagram, Facebook, TikTok, Messages, email…',
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.isTitle = false});

  final String text;
  final bool isTitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, isTitle ? 0 : 12, 16, 4),
      child: Text(
        text,
        style: isTitle
            ? const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            : TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: colors.onSurfaceVariant,
              ),
      ),
    );
  }
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({
    required this.destination,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
  });

  final ForwardDestination destination;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('forward_${destination.name}'),
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () => Navigator.pop(context, destination),
    );
  }
}
