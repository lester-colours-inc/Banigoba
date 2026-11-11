// An event as a card, its empty state, and the helpers that open its phone,
// WhatsApp and booking links.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:banigoba/core/supabase/rows.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.data,
    this.adminActions,
    this.statusLabel,
  });

  final Map<String, dynamic> data;
  final Widget? adminActions;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = (data['title'] ?? 'Event').toString();
    final flyerUrl = (data['flyerUrl'] ?? '').toString();
    final location = (data['location'] ?? '').toString();
    final price = (data['price'] ?? '').toString();
    final phoneNumber = (data['phoneNumber'] ?? '').toString();
    final whatsappNumber = (data['whatsappNumber'] ?? '').toString();
    final bookingLink = (data['bookingLink'] ?? '').toString();
    final description = (data['description'] ?? '').toString();
    final amenities = List<String>.from(data['amenities'] ?? const []);
    final eventDate = asDateTime(data['eventDateTime']);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.65,
            child: flyerUrl.isEmpty
                ? Container(
                    color: colors.surfaceContainerHighest,
                    child: const Icon(Icons.event_outlined, size: 44),
                  )
                : ColoredBox(
                    color: colors.surfaceContainerHighest,
                    child: Center(
                      child: AppNetworkImage(
                        flyerUrl,
                        fit: BoxFit.contain,
                        fallback: Container(
                          color: colors.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (statusLabel?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Chip(label: Text(statusLabel!)),
                ],
                if (eventDate != null) ...[
                  const SizedBox(height: 6),
                  _meta(Icons.schedule_outlined, formatEventDate(eventDate)),
                ],
                if (location.isNotEmpty)
                  _meta(Icons.location_on_outlined, location),
                if (price.isNotEmpty) _meta(Icons.sell_outlined, price),
                if (phoneNumber.isNotEmpty)
                  _meta(
                    Icons.phone_outlined,
                    phoneNumber,
                    onTap: () => _launchPhone(context, phoneNumber),
                    actionLabel: 'Call',
                  ),
                if (whatsappNumber.isNotEmpty)
                  _meta(
                    Icons.chat_outlined,
                    'WhatsApp: $whatsappNumber',
                    onTap: () => _launchWhatsapp(context, whatsappNumber),
                    actionLabel: 'Open',
                  ),
                if (bookingLink.isNotEmpty)
                  _meta(
                    Icons.link_outlined,
                    bookingLink,
                    onTap: () => _launchWebLink(context, bookingLink),
                    actionLabel: 'Book',
                  ),
                if (amenities.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: amenities
                        .map((item) => Chip(label: Text(item)))
                        .toList(),
                  ),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (adminActions != null) ...[
                  const SizedBox(height: 12),
                  adminActions!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(
    IconData icon,
    String text, {
    VoidCallback? onTap,
    String? actionLabel,
  }) {
    final row = Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text(text)),
          if (onTap != null && actionLabel != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0D0140),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return row;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: row,
    );
  }
}

class EventsEmptyState extends StatelessWidget {
  const EventsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: const Color(0xFF0D0140)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}

List<String> splitCsv(String value) {
  return value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

String formatEventDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day} ${months[date.month - 1]} ${date.year} at $hour:$minute';
}

Future<void> _launchPhone(BuildContext context, String phoneNumber) async {
  final cleaned = phoneNumber.replaceAll(RegExp(r'[\s().-]+'), '');
  await _launchExternalUri(
    context,
    Uri(scheme: 'tel', path: cleaned),
    label: 'phone dialer',
  );
}

Future<void> _launchWhatsapp(BuildContext context, String value) async {
  final trimmed = value.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    await _launchExternalUri(context, Uri.parse(trimmed), label: 'WhatsApp');
    return;
  }

  final phone = _whatsappPath(trimmed);
  final whatsappUri = Uri.parse('whatsapp://send?phone=$phone');
  final openedWhatsapp = await _tryLaunch(whatsappUri);
  if (openedWhatsapp) return;
  if (!context.mounted) return;

  await _launchExternalUri(
    context,
    Uri.https('wa.me', phone),
    label: 'WhatsApp',
  );
}

Future<void> _launchWebLink(BuildContext context, String link) async {
  final trimmed = link.trim();
  final normalized =
      trimmed.startsWith('http://') || trimmed.startsWith('https://')
      ? trimmed
      : 'https://$trimmed';
  await _launchExternalUri(
    context,
    Uri.parse(normalized),
    label: 'booking link',
  );
}

String _whatsappPath(String value) {
  final cleaned = value.replaceAll(RegExp(r'[^0-9+]'), '');
  if (cleaned.startsWith('+')) return cleaned.substring(1);
  return cleaned;
}

Future<void> _launchExternalUri(
  BuildContext context,
  Uri uri, {
  required String label,
}) async {
  final opened = await _tryLaunch(uri);
  if (opened || !context.mounted) return;

  AppToast.say('Unable to open $label.');
}

Future<bool> _tryLaunch(Uri uri) async {
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return true;
    }
    return await launchUrl(uri, mode: LaunchMode.platformDefault);
  } catch (_) {
    return false;
  }
}
