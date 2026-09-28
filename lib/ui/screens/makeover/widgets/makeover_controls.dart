// Small controls shared by the Makeover screens, styled after X: navy pills,
// thin outlines, bold titles and quiet secondary text.
import 'package:flutter/material.dart';

const Color kMakeoverNavy = Color(0xFF0D0140);

/// A selectable pill. Filled navy when selected, outlined otherwise.
class MakeoverPill extends StatelessWidget {
  const MakeoverPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? Colors.white : colors.onSurface;
    final shape = StadiumBorder(
      side: BorderSide(color: selected ? kMakeoverNavy : colors.outlineVariant),
    );

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? kMakeoverNavy : Colors.transparent,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: foreground),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

/// A section heading with an optional line of help underneath.
class MakeoverSectionTitle extends StatelessWidget {
  const MakeoverSectionTitle(this.title, {super.key, this.subtitle = ''});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13.5),
          ),
        ],
      ],
    );
  }
}

/// The main action of a screen: a full-width navy pill.
class MakeoverPrimaryButton extends StatelessWidget {
  const MakeoverPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: kMakeoverNavy,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
    if (icon case final iconData?) {
      return FilledButton.icon(
        style: style,
        onPressed: onPressed,
        icon: Icon(iconData, size: 20),
        label: Text(label),
      );
    }
    return FilledButton(style: style, onPressed: onPressed, child: Text(label));
  }
}

/// A compact icon-over-label action, like the row under a post on X.
class MakeoverIconAction extends StatelessWidget {
  const MakeoverIconAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = onTap == null
        ? colors.onSurface.withValues(alpha: 0.38)
        : colors.onSurface;

    return Semantics(
      button: true,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MakeoverErrorBanner extends StatelessWidget {
  const MakeoverErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: colors.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
