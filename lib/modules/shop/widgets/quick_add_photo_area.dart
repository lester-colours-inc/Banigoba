// The tappable photo box at the top of quick add, with the AI note below it.
import 'dart:typed_data';

import 'package:flutter/material.dart';

class QuickAddPhotoArea extends StatelessWidget {
  const QuickAddPhotoArea({
    super.key,
    required this.photo,
    required this.suggested,
    required this.onTap,
  });

  final Uint8List? photo;
  final bool suggested;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bytes = photo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          key: const ValueKey('photo_area'),
          onTap: onTap,
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: bytes == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 44,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      const Text('Take a photo of the piece'),
                    ],
                  )
                : Image.memory(bytes, fit: BoxFit.cover),
          ),
        ),
        if (suggested)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Kind and name suggested from the photo. Change them if '
              'they are not right.',
              key: const ValueKey('suggested_note'),
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
