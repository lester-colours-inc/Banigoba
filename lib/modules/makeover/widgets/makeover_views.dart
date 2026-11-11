// The photo card at the top of the Makeover page. The step-by-step view and
// the finished look live in look_step_view.dart and look_done_view.dart.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/makeover/widgets/makeover_controls.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

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
      preview = Semantics(
        button: onUpload != null,
        label: 'Upload your photo',
        child: InkWell(
          onTap: onUpload,
          child: const Center(
            child: Icon(
              Icons.upload_file_rounded,
              size: 72,
              color: kMakeoverNavy,
            ),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 140,
          height: 164,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: preview,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: isEditingLook
              ? _EditingNote(colors: colors)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      photoUrl.isEmpty ? 'Add Your Photo' : 'Your Photo',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _PhotoButton(
                          key: const ValueKey('makeover_upload_photo'),
                          icon: Icons.add_photo_alternate_outlined,
                          label: 'Upload',
                          filled: true,
                          onTap: onUpload,
                        ),
                        _PhotoButton(
                          key: const ValueKey('makeover_take_photo'),
                          icon: Icons.add_circle_outline,
                          label: 'Camera',
                          filled: false,
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

/// Upload (solid navy) or Camera (soft lavender) beside the photo.
class _PhotoButton extends StatelessWidget {
  const _PhotoButton({
    super.key,
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? Colors.white : kMakeoverNavy;

    return FilledButton.icon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: filled ? kMakeoverNavy : const Color(0xFFE6E1F0),
        foregroundColor: foreground,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label),
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
