// Forwards a look anywhere: inside Banigoba to a hair salon, shop, designer,
// the community or friends, or outside it to WhatsApp and any other app on
// the phone.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/post.dart';
import '../../data/services/shop_chat_service.dart';
import '../screens/shop/shop_chat_page.dart';
import 'forward_recipient_sheet.dart';

enum ForwardDestination {
  salon,
  shop,
  designer,
  community,
  friends,
  whatsapp,
  otherApps,
}

const _shareSignature = 'Styled on Banigoba';

/// Opens the Forward sheet for a look and carries out the chosen forward.
///
/// [onShareToAudience] changes who can see the post; pass it only when the
/// current user owns the look; otherwise Community and Friends are shown
/// but disabled, since only the owner decides who sees their look.
Future<void> showForwardLookSheet(
  BuildContext context, {
  required String imageUrl,
  String caption = '',
  PostVisibility visibility = PostVisibility.private,
  Future<void> Function(PostVisibility audience)? onShareToAudience,
}) async {
  if (imageUrl.trim().isEmpty) {
    _showMessage(context, 'This look has no picture to forward.');
    return;
  }

  final destination = await showModalBottomSheet<ForwardDestination>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ForwardLookSheet(
      canShareToAudience: onShareToAudience != null,
      visibility: visibility,
    ),
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
    case ForwardDestination.community:
      await onShareToAudience?.call(PostVisibility.public);
    case ForwardDestination.friends:
      await onShareToAudience?.call(PostVisibility.friends);
    case ForwardDestination.whatsapp:
      await _forwardToWhatsapp(context, imageUrl: imageUrl, caption: caption);
    case ForwardDestination.otherApps:
      await _forwardToOtherApps(context, imageUrl: imageUrl, caption: caption);
  }
}

String _shareText(String caption, String imageUrl) {
  final lead = caption.trim().isEmpty ? 'Check out this look' : caption.trim();
  return '$lead\n$imageUrl\n\n$_shareSignature';
}

void _showMessage(
  BuildContext context,
  String message, {
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message), action: action));
}

Future<void> _forwardInApp(
  BuildContext context,
  ForwardRecipientKind kind, {
  required String imageUrl,
  required String caption,
}) async {
  final user = FirebaseAuth.instance.currentUser;
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
      action: SnackBarAction(
        label: 'Open chat',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ShopChatPage(
              chatId: chatId,
              title: recipient.name,
              asSeller: false,
            ),
          ),
        ),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    _showMessage(context, 'Unable to forward look: $error');
  }
}

Future<void> _forwardToWhatsapp(
  BuildContext context, {
  required String imageUrl,
  required String caption,
}) async {
  final text = _shareText(caption, imageUrl);
  final appUri = Uri(
    scheme: 'whatsapp',
    host: 'send',
    queryParameters: {'text': text},
  );
  final webUri = Uri.https('wa.me', '/', {'text': text});
  try {
    if (await launchUrl(appUri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {
    // WhatsApp is not installed; fall through to the web link.
  }
  try {
    if (await launchUrl(webUri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {
    // Reported below.
  }
  if (!context.mounted) return;
  _showMessage(context, 'Could not open WhatsApp.');
}

/// Shares the picture itself where possible (Instagram, Facebook, TikTok and
/// friends only take images), falling back to a link when it can't be
/// downloaded.
Future<void> _forwardToOtherApps(
  BuildContext context, {
  required String imageUrl,
  required String caption,
}) async {
  final box = context.findRenderObject() as RenderBox?;
  final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  final text = _shareText(caption, imageUrl);

  List<XFile> files = const [];
  try {
    final response = await http
        .get(Uri.parse(imageUrl))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
      final mimeType = response.headers['content-type'] ?? 'image/jpeg';
      files = [
        XFile.fromData(
          response.bodyBytes,
          mimeType: mimeType,
          name: 'banigoba_look.${mimeType.contains('png') ? 'png' : 'jpg'}',
        ),
      ];
    }
  } catch (_) {
    // Share the link instead.
  }

  try {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'A look from Banigoba',
        files: files.isEmpty ? null : files,
        sharePositionOrigin: origin,
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    _showMessage(context, 'Unable to share look: $error');
  }
}

class _ForwardLookSheet extends StatelessWidget {
  const _ForwardLookSheet({
    required this.canShareToAudience,
    required this.visibility,
  });

  final bool canShareToAudience;
  final PostVisibility visibility;

  @override
  Widget build(BuildContext context) {
    final communityNote = !canShareToAudience
        ? 'Only the owner can share this look with the community.'
        : visibility == PostVisibility.public
        ? 'Already shared with the community.'
        : 'Everyone on Banigoba can see it.';
    final friendsNote = !canShareToAudience
        ? 'Only the owner can share this look with friends.'
        : visibility != PostVisibility.private
        ? 'Your friends can already see it.'
        : 'Only your friends can see it.';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('Forward look', isTitle: true),
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
            _DestinationTile(
              destination: ForwardDestination.community,
              icon: Icons.public,
              title: 'Community',
              subtitle: communityNote,
              enabled:
                  canShareToAudience && visibility != PostVisibility.public,
            ),
            _DestinationTile(
              destination: ForwardDestination.friends,
              icon: Icons.people_alt_outlined,
              title: 'Friends',
              subtitle: friendsNote,
              enabled:
                  canShareToAudience && visibility == PostVisibility.private,
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
    this.enabled = true,
  });

  final ForwardDestination destination;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('forward_${destination.name}'),
      enabled: enabled,
      leading: Icon(icon, color: enabled ? iconColor : null),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () => Navigator.pop(context, destination),
    );
  }
}
