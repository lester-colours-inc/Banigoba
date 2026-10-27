// Feed card for the Home dress-up feed (Mine, My Friends, Community).
//
// Presentational only: the page resolves the author, picks the visual and
// wires the actions. Mine and the social tabs share one layout and differ
// only in where the timestamp sits: in the header on Mine, on the image on
// the social tabs.
//
// Under the image is one row of icons spread evenly across the card: the
// [actions], the ⋮ menu, then the [trailingAction] (Forward).
//
// A repost or quote carries a [repostLabel] above the header; a quote's own
// words are its [quote], shown above the look.
import 'package:flutter/material.dart';
import 'app_network_image.dart';

/// A tappable icon in the row under the image. [label] is its tooltip and
/// what screen readers announce.
class DressUpCardAction {
  const DressUpCardAction({
    this.icon,
    this.glyph,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.activeIcon,
  }) : assert(icon != null || glyph != null);

  final IconData? icon;

  /// On, like a liked heart: drawn with [activeIcon] in the accent colour.
  final bool isActive;
  final IconData? activeIcon;

  /// A letter drawn in place of an icon, e.g. "a" for affirmations.
  final String? glyph;
  final String label;
  final VoidCallback onTap;
}

/// An entry in the card's overflow (⋮) menu.
class DressUpMenuItem {
  const DressUpMenuItem({
    required this.icon,
    required this.label,
    required this.onSelected,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelected;
  final bool isDestructive;
}

class DressUpPostCard extends StatelessWidget {
  const DressUpPostCard({
    super.key,
    required this.title,
    required this.avatarUrl,
    required this.timeLabel,
    required this.imageBackground,
    required this.visual,
    this.subtitle = '',
    this.detail = '',
    this.captionLead = '',
    this.caption = '',
    this.isMineLayout = false,
    this.actions = const [],
    this.menuItems = const [],
    this.trailingAction,
    this.onImageTap,
    this.footer,
    this.repostLabel = '',
    this.quote = '',
  });

  /// "Reposted from Tariro" / "Quoting Tariro". Empty on an original post.
  final String repostLabel;

  /// The reposter's own words on a quote.
  final String quote;

  /// The author's name, shown next to the verified badge.
  final String title;

  /// Mine only: the look's caption under the name, then [detail] (style).
  final String subtitle;
  final String detail;

  /// Social tabs only: "Tariro's" + caption, with #hashtags highlighted.
  final String captionLead;
  final String caption;

  final String avatarUrl;
  final String timeLabel;
  final Color imageBackground;
  final Widget visual;

  /// Mine puts the time and the menu together in the header; the social tabs
  /// put the menu in the header and the time on the image.
  final bool isMineLayout;
  final List<DressUpCardAction> actions;
  final List<DressUpMenuItem> menuItems;

  /// Sits apart at the end of the action row (Forward).
  final DressUpCardAction? trailingAction;

  /// Opens the look up, e.g. full screen. Fired by a tap anywhere on the
  /// card except the action row and footer.
  final VoidCallback? onImageTap;

  /// Rendered under the action row (affirmations, quick replies).
  final Widget? footer;

  static const Color _primaryColor = Color(0xFF0D0140);
  static const Color _avatarRing = Color(0xFFF2A93B);
  static const Color _activeColor = _avatarRing;
  static const double _avatarSize = 46;
  static const double _contentInset = _avatarSize + 12;

  bool get _hasActionRow =>
      actions.isNotEmpty || menuItems.isNotEmpty || trailingAction != null;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasCaption = !isMineLayout && caption.trim().isNotEmpty;

    // Like X: tapping anywhere on the card (name, words or picture) opens
    // the look. The action row and footer keep their own taps.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _openOnTap(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (repostLabel.isNotEmpty) _buildRepostLabel(context),
              _buildHeader(context),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: _contentInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _openOnTap(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (quote.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        quote.trim(),
                        key: const ValueKey('dress_up_post_quote'),
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (hasCaption) ...[
                      const SizedBox(height: 6),
                      _buildCaption(context),
                    ],
                    const SizedBox(height: 12),
                    _buildImage(context),
                  ],
                ),
              ),
              if (_hasActionRow) ...[
                const SizedBox(height: 6),
                _buildActions(context),
              ],
              ?footer,
            ],
          ),
        ),
        const SizedBox(height: 8),
        Divider(height: 1, color: colors.outlineVariant),
      ],
    );
  }

  Widget _openOnTap(Widget child) {
    if (onImageTap == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onImageTap,
      child: child,
    );
  }

  Widget _buildRepostLabel(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: _contentInset - 22, bottom: 4),
      child: Row(
        children: [
          Icon(Icons.repeat, size: 16, color: colors.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              repostLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final titleColor = colors.brightness == Brightness.dark
        ? colors.onSurface
        : _primaryColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Avatar(url: avatarUrl, name: title, size: _avatarSize),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.verified,
                    size: 18,
                    color: isMineLayout ? titleColor : const Color(0xFF8E86D8),
                  ),
                ],
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (detail.isNotEmpty)
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        if (isMineLayout)
          Text(
            timeLabel,
            style: TextStyle(
              color: titleColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildCaption(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hashtagColor = colors.brightness == Brightness.dark
        ? colors.primary
        : _primaryColor;
    final base = TextStyle(
      color: colors.onSurface,
      fontSize: 12.5,
      height: 1.3,
    );

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          if (captionLead.isNotEmpty)
            TextSpan(
              text: '$captionLead ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          for (final word in caption.trim().split(RegExp(r'(?<=\s)')))
            TextSpan(
              text: word,
              style: word.startsWith('#')
                  ? TextStyle(color: hashtagColor, fontWeight: FontWeight.w700)
                  : null,
            ),
        ],
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildImage(BuildContext context) {
    final image = AspectRatio(
      aspectRatio: 1.4,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: imageBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: visual),
            if (!isMineLayout)
              Positioned(top: 6, right: 6, child: _TimePill(label: timeLabel)),
          ],
        ),
      ),
    );
    if (onImageTap == null) return image;
    return Semantics(
      button: true,
      label: 'Open look',
      child: GestureDetector(
        key: const ValueKey('dress_up_post_image'),
        onTap: onImageTap,
        child: image,
      ),
    );
  }

  /// The ⋮ menu, in the action row.
  Widget _buildMenu(BuildContext context, {required Color iconColor}) {
    final colors = Theme.of(context).colorScheme;

    return PopupMenuButton<int>(
      tooltip: 'More options',
      style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
      icon: Icon(Icons.more_vert, color: iconColor, size: 22),
      onSelected: (index) => menuItems[index].onSelected(),
      itemBuilder: (context) => [
        for (var index = 0; index < menuItems.length; index++)
          PopupMenuItem<int>(
            value: index,
            child: Row(
              children: [
                Icon(
                  menuItems[index].icon,
                  size: 20,
                  color: menuItems[index].isDestructive
                      ? colors.error
                      : colors.onSurface,
                ),
                const SizedBox(width: 12),
                Text(
                  menuItems[index].label,
                  style: TextStyle(
                    color: menuItems[index].isDestructive
                        ? colors.error
                        : colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final iconColor = colors.brightness == Brightness.dark
        ? colors.onSurface
        : _primaryColor;
    // Spread evenly when there is room; shrink to fit a narrow card (a
    // two-column grid on a 320 px phone) instead of overflowing.
    return LayoutBuilder(
      builder: (context, constraints) => FittedBox(
        fit: BoxFit.scaleDown,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final action in actions)
                _ActionIcon(action: action, color: iconColor),
              if (menuItems.isNotEmpty)
                _buildMenu(context, iconColor: iconColor),
              if (trailingAction case final trailing?)
                _ActionIcon(action: trailing, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.action, required this.color});

  final DressUpCardAction action;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final glyph = action.glyph;
    final iconColor = action.isActive ? DressUpPostCard._activeColor : color;
    return IconButton(
      tooltip: action.label,
      onPressed: action.onTap,
      color: iconColor,
      visualDensity: VisualDensity.compact,
      icon: glyph == null
          ? AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                action.isActive
                    ? action.activeIcon ?? action.icon
                    : action.icon,
                key: ValueKey(action.isActive),
                size: 22,
              ),
            )
          : Text(
              glyph,
              style: TextStyle(
                color: color,
                fontSize: 22,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name, required this.size});

  final String url;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initial = name.trim().isEmpty ? 'U' : name.trim()[0].toUpperCase();

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [DressUpPostCard._primaryColor, DressUpPostCard._avatarRing],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.surface,
        ),
        child: ClipOval(
          child: url.isEmpty
              ? ColoredBox(
                  color: colors.surfaceContainerHigh,
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              : AppNetworkImage(
                  url,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  fallback: ColoredBox(
                    color: colors.surfaceContainerHigh,
                    child: Icon(
                      Icons.person_outline,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: DressUpPostCard._primaryColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
