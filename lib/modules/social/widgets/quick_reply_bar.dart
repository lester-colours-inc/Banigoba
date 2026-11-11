// One-tap preset replies for Daily Dress Up posts.
//
// Custom text comments are not allowed: these presets are the only way to
// reply. Replies are ordinary comments — they go through the same PostService path
// as typed ones — so a preset is just a shortcut, never a separate reaction
// type that could be tallied into a popularity score.
import 'package:flutter/material.dart';

/// Preloaded replies, emoji first so the strip reads at a glance.
const List<String> kQuickReplies = [
  '🔥',
  '😍',
  '👏',
  '💯',
  '✨',
  'Nice outfit!',
  'Love this look 😍',
  'Serving looks! 🔥',
  'Slay! 💃',
  'Those colours work so well',
  'Perfect for the weather ☀️',
  'Stunning combo ✨',
  'Need this in my wardrobe 👗',
  'Where is that from?',
  'Try-on worthy!',
];

/// A horizontally scrolling row of preset reply chips.
///
/// [onSelected] receives the tapped reply. While [isSending] is true the chips
/// are disabled so one tap cannot post the same reply twice.
class QuickReplyBar extends StatelessWidget {
  const QuickReplyBar({
    super.key,
    required this.onSelected,
    this.isSending = false,
    this.replies = kQuickReplies,
    this.wrap = false,
  });

  final ValueChanged<String> onSelected;
  final bool isSending;
  final List<String> replies;

  /// Lays chips out in wrapping rows instead of one scrolling strip.
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    if (wrap) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var index = 0; index < replies.length; index++)
            SizedBox(height: 36, child: _buildChip(context, index)),
        ],
      );
    }

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: replies.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: _buildChip,
      ),
    );
  }

  Widget _buildChip(BuildContext context, int index) {
    final colors = Theme.of(context).colorScheme;
    final reply = replies[index];
    final isEmoji = reply.runes.length <= 2;
    return Semantics(
      button: true,
      label: 'Reply $reply',
      child: Material(
        color: colors.surfaceContainerLow,
        shape: StadiumBorder(side: BorderSide(color: colors.outlineVariant)),
        child: InkWell(
          key: Key('quick_reply_$index'),
          customBorder: const StadiumBorder(),
          onTap: isSending ? null : () => onSelected(reply),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isEmoji ? 12 : 14),
            child: Center(
              widthFactor: 1,
              child: Text(
                reply,
                style: TextStyle(
                  fontSize: isEmoji ? 17 : 12.5,
                  fontWeight: FontWeight.w600,
                  color: isSending ? colors.onSurfaceVariant : colors.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
