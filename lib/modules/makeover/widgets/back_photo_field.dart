// The shop's optional "back photo" for an item. Shops usually photograph
// only the front, so the turn-around view has to guess the back; a real back
// photo makes that view accurate.
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:banigoba/modules/shop/widgets/safe_product_image.dart';

class BackPhotoField extends StatelessWidget {
  const BackPhotoField({
    super.key,
    required this.picked,
    required this.existingUrl,
    required this.onPick,
    required this.onRemove,
  });

  /// A photo chosen just now, not yet uploaded.
  final File? picked;

  /// The back photo already saved with the item, or ''.
  final String existingUrl;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  bool get _hasPhoto => picked != null || existingUrl.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: picked != null
                  ? Image.file(picked!, fit: BoxFit.cover)
                  : existingUrl.isNotEmpty
                  ? SafeProductImage(
                      imageUrl: existingUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    )
                  : ColoredBox(
                      color: colors.surfaceContainerHighest,
                      child: Icon(
                        Icons.flip_camera_android_outlined,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Back photo (optional)',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  _hasPhoto
                      ? 'Buyers see an accurate back when they turn around.'
                      : 'Helps buyers see the back when they turn the '
                            'try-on around.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            key: const ValueKey('back_photo_pick'),
            onPressed: onPick,
            child: Text(_hasPhoto ? 'Change' : 'Add'),
          ),
          if (_hasPhoto)
            IconButton(
              key: const ValueKey('back_photo_remove'),
              tooltip: 'Remove back photo',
              onPressed: onRemove,
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }
}
