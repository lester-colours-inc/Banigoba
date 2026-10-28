// Feed card for the Home feeds (My Fashion Makeover, My Daily Dress Up,
// Community), laid out like a page from a lookbook.
//
// Presentational only: the page resolves the author, picks the visual and
// wires the actions.
//
// The look stands in a tall studio frame. The picture is blended (multiply)
// over a soft pastel spotlight, so the white background of a generated look
// becomes the studio backdrop and the whole outfit shows, head to shoes. The
// date sits on the frame like a stamp.
//
// Above the frame: the author, with the ⋯ menu. Below it: the look's title
// (Mine) or the author's caption (the social feeds), then one row of
// actions: any labelled pill first (Affirm), the other [actions] as icons,
// and the [trailingAction] (Send to) at the far end.
//
// A repost or quote carries a [repostLabel] above the header; a quote's own
// words are its [quote], shown above the look.
import 'package:flutter/material.dart';
import 'app_network_image.dart';

/// Soft studio backdrops, given to posts in turn so neighbouring looks stand
/// on different colours: blush, lilac, butter, sage and sky.
const List<Color> kLookBackdrops = [
  Color(0xFFF4DCD6),
  Color(0xFFE2DBF5),
  Color(0xFFF3E6C3),
  Color(0xFFD7EADD),
  Color(0xFFD5E4F3),
];

/// A tappable action in the row under the look. [label] is its tooltip and
/// what screen readers announce.
class DressUpCardAction {
  const DressUpCardAction({
    this.icon,
    this.glyph,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.activeIcon,
    this.chipLabel,
  }) : assert(icon != null || glyph != null);

  final IconData? icon;

  /// On, like a liked heart: drawn with [activeIcon] in the accent colour.
  final bool isActive;
  final IconData? activeIcon;

  /// A letter drawn in place of an icon, e.g. "a" for affirmations.
  final String? glyph;
  final String label;
  final VoidCallback onTap;

  /// A short word shown beside the icon, making this the card's main action:
  /// an amber pill at the start of the row instead of a bare icon.
  final String? chipLabel;
}

/// An entry in the card's overflow (⋯) menu.
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

  /// Mine only: the look's title under the picture, and [detail] (style)
  /// under the name.
  final String subtitle;
  final String detail;

  /// Social feeds only: "Tariro's" + caption, with #hashtags highlighted.
  final String captionLead;
  final String caption;

  final String avatarUrl;
  final String timeLabel;

  /// The studio backdrop's colour, usually one of [kLookBackdrops].
  final Color imageBackground;
  final Widget visual;

  /// Mine shows the look's title under the picture; the social feeds show
  /// the author's caption there instead.
  final bool isMineLayout;
  final List<DressUpCardAction> actions;
  final List<DressUpMenuItem> menuItems;

  /// Sits apart at the end of the action row (Send to).
  final DressUpCardAction? trailingAction;

  /// Opens the look up, e.g. full screen. Fired by a tap anywhere on the
  /// card except the menu, the action row and the footer.
  final VoidCallback? onImageTap;

  /// Rendered under the action row (affirmations, quick replies).
  final Widget? footer;

  static const Color _primaryColor = Color(0xFF0D0140);
  static const Color _accent = Color(0xFFF2A93B);
  static const Color _activeColor = _accent;
  static const double _avatarSize = 42;
  static const double _cardRadius = 28;
  static const double _frameRadius = 20;
  static const double _cardPadding = 12;

  /// Portrait, like a fashion page, so a full-length look is not cropped.
  static const double _frameAspectRatio = 4 / 5;

  /// Room around the look inside the frame, so it stands in the studio
  /// rather than touching its edges.
  static const EdgeInsets _framePadding = EdgeInsets.fromLTRB(14, 18, 14, 10);

  bool get _hasActionRow => actions.isNotEmpty || trailingAction != null;

  /// Text and icons: the brand navy, or plain light text at night.
  static Color _ink(ColorScheme colors) =>
      colors.brightness == Brightness.dark ? colors.onSurface : _primaryColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final hasTitle = subtitle.trim().isNotEmpty;
    final hasCaption = !isMineLayout && caption.trim().isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(
          color: _ink(colors).withValues(alpha: isDark ? 0.10 : 0.06),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.08),
                  blurRadius: 28,
                  spreadRadius: -6,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _cardPadding,
          _cardPadding,
          _cardPadding,
          6,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Like X: tapping anywhere on the card (name, words or picture)
            // opens the look. The menu, actions and footer keep their taps.
            _openOnTap(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (repostLabel.isNotEmpty) _buildRepostLabel(context),
                  _buildHeader(context),
                  if (quote.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        quote.trim(),
                        key: const ValueKey('dress_up_post_quote'),
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildImage(context),
                  if (hasTitle) ...[
                    const SizedBox(height: 12),
                    _buildTitle(context),
                  ],
                  if (hasCaption) ...[
                    const SizedBox(height: 10),
                    _buildCaption(context),
                  ],
                ],
              ),
            ),
            if (_hasActionRow) ...[
              const SizedBox(height: 8),
              _buildActions(context),
            ],
            if (footer case final footer?)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 2, 4, 6),
                child: footer,
              ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(Icons.repeat, size: 15, color: colors.onSurfaceVariant),
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
    final ink = _ink(colors);

    return Row(
      children: [
        _Avatar(url: avatarUrl, name: title, size: _avatarSize),
        const SizedBox(width: 10),
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
                        color: ink,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.verified,
                    size: 16,
                    color: isMineLayout ? ink : const Color(0xFF8E86D8),
                  ),
                ],
              ),
              if (detail.isNotEmpty)
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        if (menuItems.isNotEmpty) _buildMenu(context),
      ],
    );
  }

  /// The look's title, set like a caption in a magazine.
  Widget _buildTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        subtitle.trim(),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _ink(Theme.of(context).colorScheme),
          fontSize: 19,
          fontWeight: FontWeight.w800,
          height: 1.2,
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  Widget _buildCaption(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hashtagColor = colors.brightness == Brightness.dark
        ? colors.primary
        : _primaryColor;
    final base = TextStyle(color: colors.onSurface, fontSize: 14, height: 1.35);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text.rich(
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
                    ? TextStyle(
                        color: hashtagColor,
                        fontWeight: FontWeight.w700,
                      )
                    : null,
              ),
          ],
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final image = AspectRatio(
      aspectRatio: _frameAspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_frameRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _StudioBackdrop(
              tint: imageBackground,
              isDark: isDark,
              child: Padding(padding: _framePadding, child: visual),
            ),
            Positioned(top: 12, left: 12, child: _DateStamp(label: timeLabel)),
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

  /// The ⋯ menu, at the end of the header.
  Widget _buildMenu(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return PopupMenuButton<int>(
      tooltip: 'More options',
      style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
      icon: Icon(Icons.more_horiz, color: colors.onSurfaceVariant, size: 24),
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
    final iconColor = _ink(Theme.of(context).colorScheme);
    // The main actions together at the start, Send to apart at the end.
    // Shrinks to fit a narrow card instead of overflowing.
    return LayoutBuilder(
      builder: (context, constraints) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final action in actions)
                    if (action.chipLabel case final chipLabel?)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _ActionChip(action: action, text: chipLabel),
                      )
                    else
                      _ActionIcon(action: action, color: iconColor),
                ],
              ),
              if (trailingAction case final trailing?)
                _ActionIcon(action: trailing, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}

/// A pastel studio spotlight, blended over [child] with multiply: white in
/// the picture takes on the backdrop's colour, so a look generated on white
/// stands in the studio, while the clothes, under the near-white centre of
/// the light, keep their colours.
class _StudioBackdrop extends StatelessWidget {
  const _StudioBackdrop({
    required this.tint,
    required this.isDark,
    required this.child,
  });

  final Color tint;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // At night the whole frame is dimmed, so it does not glare out of a
    // dark feed; the centre stays neutral so colours do not shift.
    final edge = isDark ? Color.lerp(tint, Colors.black, 0.5)! : tint;
    final centre = isDark
        ? const Color(0xFFD9D9D9)
        : Color.lerp(tint, Colors.white, 0.85)!;
    final light = RadialGradient(
      center: const Alignment(0, -0.1),
      radius: 0.62,
      colors: [centre, Color.lerp(centre, edge, 0.35)!, edge],
      stops: const [0, 0.6, 1],
      // Taller than wide, like a spotlight on a standing figure.
      transform: const _StretchVertically(1.4),
    );

    return ShaderMask(
      blendMode: BlendMode.multiply,
      shaderCallback: light.createShader,
      child: ColoredBox(color: Colors.white, child: child),
    );
  }
}

/// Stretches a gradient up and down about the middle of its box.
class _StretchVertically extends GradientTransform {
  const _StretchVertically(this.factor);

  final double factor;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.diagonal3Values(1, factor, 1)
      ..setTranslationRaw(0, bounds.center.dy * (1 - factor), 0);
  }
}

/// The post's date, pinned to the corner of the frame.
class _DateStamp extends StatelessWidget {
  const _DateStamp({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final ink = isDark ? Colors.white : DressUpPostCard._primaryColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.45)
            : Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 11, color: DressUpPostCard._accent),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: ink,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The card's main action as an amber pill: its icon or letter in a disc,
/// then a word, e.g. "a  Affirm".
class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.action, required this.text});

  final DressUpCardAction action;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final glyph = action.glyph;
    const discInk = DressUpPostCard._primaryColor;

    return Tooltip(
      message: action.label,
      child: Material(
        color: DressUpPostCard._accent.withValues(alpha: isDark ? 0.22 : 0.16),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: action.onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: DressUpPostCard._accent,
                  ),
                  child: glyph == null
                      ? Icon(
                          action.isActive
                              ? action.activeIcon ?? action.icon
                              : action.icon,
                          size: 17,
                          color: discInk,
                        )
                      : Text(
                          glyph,
                          style: const TextStyle(
                            color: discInk,
                            fontSize: 18,
                            height: 1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    color: DressUpPostCard._ink(colors),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
          colors: [DressUpPostCard._primaryColor, DressUpPostCard._accent],
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
