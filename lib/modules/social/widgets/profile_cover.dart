// The top of a profile, set like a magazine cover: a pastel studio banner
// running up behind the app bar, the person's photo in the navy-to-amber
// ring the feed uses, overlapping the banner's edge, then their name, handle
// and (on your own profile only) your email.
//
// Presentational only: the page reads the profile and decides what to show.
import 'package:flutter/material.dart';

import 'package:banigoba/shared/widgets/app_network_image.dart';
import 'package:banigoba/modules/social/widgets/dress_up_post_card.dart';

class ProfileCover extends StatelessWidget {
  const ProfileCover({
    super.key,
    required this.name,
    required this.photoUrl,
    this.username = '',
    this.email = '',
    this.onChangePhoto,
  });

  final String name;
  final String photoUrl;

  /// The @handle, without the @. Empty when the person has none.
  final String username;

  /// Shown to the profile's owner only (U-5); empty for everyone else.
  final String email;

  /// Your own profile: tapping the photo changes it. Null on other people's.
  final VoidCallback? onChangePhoto;

  static const Color _primaryColor = Color(0xFF0D0140);
  static const Color _accent = Color(0xFFF2A93B);
  static const Color _handleColor = Color(0xFF6A4CE0);
  static const double _avatarSize = 108;

  /// How far the banner reaches below the app bar.
  static const double _bannerDepth = 64;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final ink = isDark ? colors.onSurface : _primaryColor;
    // Under the status bar and the app bar, which the page draws over it.
    final bannerHeight = MediaQuery.paddingOf(context).top + _bannerDepth;

    return Column(
      children: [
        SizedBox(
          height: bannerHeight + _avatarSize / 2,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              SizedBox(
                height: bannerHeight,
                width: double.infinity,
                child: _Banner(isDark: isDark),
              ),
              Positioned(
                top: bannerHeight - _avatarSize / 2,
                child: _buildPhoto(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ink,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
        ),
        if (username.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '@$username',
            key: const ValueKey('profile_username'),
            style: TextStyle(
              color: isDark ? colors.primary : _handleColor,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (email.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            email,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _buildPhoto(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initial = name.trim().isEmpty ? 'U' : name.trim()[0].toUpperCase();
    final photo = Container(
      width: _avatarSize,
      height: _avatarSize,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryColor, _accent],
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.surface,
        ),
        child: ClipOval(
          child: photoUrl.isEmpty
              ? ColoredBox(
                  color: _primaryColor,
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              : AppNetworkImage(
                  photoUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  fallback: ColoredBox(
                    color: colors.surfaceContainerHigh,
                    child: Icon(
                      Icons.person_outline,
                      size: 40,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
        ),
      ),
    );

    final onChangePhoto = this.onChangePhoto;
    if (onChangePhoto == null) return photo;
    return Semantics(
      button: true,
      label: 'Change profile photo',
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('profile_change_photo'),
        onTap: onChangePhoto,
        child: Stack(
          children: [
            photo,
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent,
                  border: Border.all(color: colors.surface, width: 3),
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  size: 17,
                  color: _primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A soft wash of the feed's studio backdrops, lilac into blush into
/// butter, with two pools of light, and a rounded lower edge.
class _Banner extends StatelessWidget {
  const _Banner({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final wash = [kLookBackdrops[1], kLookBackdrops[0], kLookBackdrops[2]];
    final light = Colors.white.withValues(alpha: isDark ? 0.10 : 0.55);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              for (final colour in wash)
                isDark ? Color.lerp(colour, Colors.black, 0.62)! : colour,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -60,
              top: -40,
              child: _Glow(size: 220, colour: light),
            ),
            Positioned(
              right: -40,
              bottom: -90,
              child: _Glow(size: 200, colour: light),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.colour});

  final double size;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [colour, colour.withValues(alpha: 0)]),
      ),
    );
  }
}
