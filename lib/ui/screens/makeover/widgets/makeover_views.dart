// The photo card at the top of the Makeover page. The step-by-step view and
// the finished look live in look_step_view.dart and look_done_view.dart.
import 'package:flutter/material.dart';

import 'makeover_controls.dart';
import '../../../widgets/app_network_image.dart';

/// Shows the user's photo first, with ways to replace it.
///
/// When [isEditingLook] is set, the photo is a saved look being edited, so it
/// is labelled as such and cannot be swapped.
class MakeoverPhotoCard extends StatelessWidget {
  const MakeoverPhotoCard({
    super.key,
    required this.photoUrl,
    required this.isLoading,
    required this.onUpload,
    required this.onTakePhoto,
    this.isEditingLook = false,
  });

  final String photoUrl;
  final bool isLoading;
  final VoidCallback? onUpload;
  final VoidCallback? onTakePhoto;
  final bool isEditingLook;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final Widget preview;
    if (isLoading) {
      preview = const Center(child: CircularProgressIndicator());
    } else if (photoUrl.isEmpty) {
      // Scales down rather than overflowing with large system text sizes.
      preview = Padding(
        padding: const EdgeInsets.all(10),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline, size: 40, color: colors.outline),
              const SizedBox(height: 6),
              Text(
                'Add a\nfull-length\nphoto',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    } else {
      preview = AppNetworkImage(
        photoUrl,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        fallback: Icon(Icons.broken_image_outlined, color: colors.outline),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 120,
            height: 160,
            color: colors.surfaceContainerHigh,
            child: preview,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: isEditingLook
              ? _EditingNote(colors: colors)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      photoUrl.isEmpty
                          ? 'Start with a full-length photo of you.'
                          : 'Looking good. Use this photo or pick another.',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        MakeoverPill(
                          key: const ValueKey('makeover_upload_photo'),
                          icon: Icons.photo_library_outlined,
                          label: 'Upload',
                          selected: false,
                          onTap: onUpload,
                        ),
                        MakeoverPill(
                          key: const ValueKey('makeover_take_photo'),
                          icon: Icons.photo_camera_outlined,
                          label: 'Camera',
                          selected: false,
                          onTap: onTakePhoto,
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _EditingNote extends StatelessWidget {
  const _EditingNote({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit_outlined, size: 18, color: colors.onSurface),
            const SizedBox(width: 6),
            const Flexible(
              child: Text(
                'Editing your look',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Choose what to change below. Everything else stays as it is.',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13.5),
        ),
      ],
    );
  }
}
