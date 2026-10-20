// Small controls shared by the Makeover screens: navy rounded-square pills
// with thin outlines, bold titles and quiet secondary text.
import 'package:flutter/material.dart';

import '../../../widgets/cart_badge_button.dart';

const Color kMakeoverNavy = Color(0xFF0D0140);

/// The top of every Makeover stage: the menu and a round back button, then a
/// large title beside the cart.
class MakeoverHeader extends StatelessWidget {
  const MakeoverHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;

  /// Shown before the cart, e.g. a Done action while styling.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // Back sits top-left, where users expect it on every app.
                IconButton(
                  key: const ValueKey('makeover_back'),
                  tooltip: 'Back',
                  onPressed: onBack,
                  icon: Icon(
                    Icons.arrow_back,
                    size: 26,
                    color: colors.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  key: const ValueKey('makeover_menu'),
                  tooltip: 'Menu',
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: Icon(Icons.menu, size: 28, color: colors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  ?trailing,
                  CartBadgeButton(color: colors.onSurface),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A selectable rounded-square pill. Filled navy when selected, outlined
/// otherwise.
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
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(
        color: selected ? kMakeoverNavy : colors.outline,
        width: 1.2,
      ),
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
                    fontWeight: FontWeight.w500,
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

/// The main action of a screen: a centred navy button, sized to its label.
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
      disabledBackgroundColor: kMakeoverNavy.withValues(alpha: 0.35),
      disabledForegroundColor: Colors.white,
      minimumSize: const Size(240, 54),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );
    final Widget button;
    if (icon case final iconData?) {
      button = FilledButton.icon(
        style: style,
        onPressed: onPressed,
        icon: Icon(iconData, size: 20),
        label: Text(label),
      );
    } else {
      button = FilledButton(
        style: style,
        onPressed: onPressed,
        child: Text(label),
      );
    }
    return Center(child: button);
  }
}

/// An icon on a soft square tile over a label.
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
    final labelColor = onTap == null
        ? colors.onSurfaceVariant.withValues(alpha: 0.5)
        : colors.onSurfaceVariant;

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
              Container(
                width: 46,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: labelColor, fontSize: 15),
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
