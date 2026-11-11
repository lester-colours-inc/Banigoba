// One of the two profile photos (face or full body): empty prompt, the photo
// itself, or an upload in progress.
import 'package:flutter/material.dart';

import 'package:banigoba/shared/widgets/app_network_image.dart';

class ProfilePhotoTile extends StatelessWidget {
  const ProfilePhotoTile({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.imageUrl,
    required this.isUploading,
    required this.onTap,
  });

  final String label;

  /// What makes a good photo, shown while it is empty.
  final String hint;
  final IconData icon;
  final String imageUrl;
  final bool isUploading;
  final VoidCallback? onTap;

  static const double _radius = 18;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasPhoto = imageUrl.isNotEmpty;

    return Semantics(
      button: true,
      label: hasPhoto ? 'Change $label photo' : 'Add $label photo',
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(_radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isUploading ? null : onTap,
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasPhoto)
                  AppNetworkImage(imageUrl, fit: BoxFit.cover)
                else
                  _EmptyPrompt(label: label, hint: hint, icon: icon),
                if (hasPhoto) _PhotoCaption(label: label),
                if (isUploading)
                  const ColoredBox(
                    color: Colors.black45,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
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

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt({
    required this.label,
    required this.hint,
    required this.icon,
  });

  final String label;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ProfilePhotoTile._radius),
        border: Border.all(color: colors.outlineVariant, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: colors.primaryContainer,
              child: Icon(icon, color: colors.onPrimaryContainer, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_a_photo_outlined,
                  size: 16,
                  color: colors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Add photo',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoCaption extends StatelessWidget {
  const _PhotoCaption({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black54],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 24, 10, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
