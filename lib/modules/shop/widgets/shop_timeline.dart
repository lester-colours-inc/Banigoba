// The Home tab's activity timeline: a rail of coloured nodes, one per event,
// grouped under day headers.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/shop/models/shop_activity.dart';

/// Colour and icon for each kind of event.
({Color color, IconData icon, String tag}) activityStyle(
  ShopActivityKind kind,
) => switch (kind) {
  ShopActivityKind.orderPlaced => (
    color: const Color(0xFF0D0140),
    icon: Icons.shopping_bag_outlined,
    tag: 'New',
  ),
  ShopActivityKind.orderUpdated => (
    color: const Color(0xFF0F766E),
    icon: Icons.local_shipping_outlined,
    tag: 'Update',
  ),
  ShopActivityKind.message => (
    color: const Color(0xFF7C3AED),
    icon: Icons.chat_bubble_outline,
    tag: 'Unread',
  ),
  ShopActivityKind.listed => (
    color: const Color(0xFFB45309),
    icon: Icons.checkroom_outlined,
    tag: 'Listed',
  ),
};

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Today", "Yesterday" or "Wed 11 Nov".
String dayLabel(DateTime day, DateTime now) {
  final today = activityDay(now);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  final base =
      '${_weekdays[day.weekday - 1]} ${day.day} ${_months[day.month - 1]}';
  return day.year == today.year ? base : '$base ${day.year}';
}

String _clock(DateTime at) {
  final local = at.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}';
}

/// A day header on the timeline.
class TimelineDayHeader extends StatelessWidget {
  const TimelineDayHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: scheme.outlineVariant)),
        ],
      ),
    );
  }
}

/// One event: the time, a node on the rail, and a card.
class TimelineTile extends StatelessWidget {
  const TimelineTile({
    super.key,
    required this.activity,
    required this.onTap,
    this.isLast = false,
  });

  final ShopActivity activity;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = activityStyle(activity.kind);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 64,
            child: Padding(
              padding: const EdgeInsets.only(left: 20, top: 14),
              child: Text(
                _clock(activity.at),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          _Rail(color: style.color, icon: style.icon, isLast: isLast),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 10),
              child: _EventCard(
                activity: activity,
                color: style.color,
                tag: style.tag,
                onTap: onTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.color, required this.icon, required this.isLast});

  final Color color;
  final IconData icon;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final line = Theme.of(context).colorScheme.outlineVariant;
    return SizedBox(
      width: 32,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 0,
            bottom: isLast ? null : 0,
            height: isLast ? 14 : null,
            child: Container(width: 2, color: line),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 3,
                ),
              ),
              child: Icon(icon, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.activity,
    required this.color,
    required this.tag,
    required this.onTap,
  });

  final ShopActivity activity;
  final Color color;
  final String tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hot = activity.highlight;
    return Material(
      color: hot ? color.withValues(alpha: 0.07) : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hot ? color.withValues(alpha: 0.35) : Colors.transparent,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: hot ? FontWeight.w800 : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activity.detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (hot)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else
                Icon(Icons.chevron_right, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
