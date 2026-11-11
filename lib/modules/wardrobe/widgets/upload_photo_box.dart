// The photo picker box on the upload form, with the AI-suggestion status.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/wardrobe/controllers/wardrobe_upload_controller.dart';

class UploadPhotoBox extends StatelessWidget {
  const UploadPhotoBox({super.key, required this.form});

  final WardrobeUploadController form;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Obx(() {
      final photo = form.image.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: form.pickPhoto,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: photo != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(photo, fit: BoxFit.contain),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          'Select Image',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
            ),
          ),
          if (form.tagging.value)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Row(
                key: ValueKey('tagging_progress'),
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Looking at your photo…'),
                ],
              ),
            )
          else if (form.taggedFromPhoto.value)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Filled in from your photo. Check it and change '
                'anything that is not right.',
                key: const ValueKey('tagged_note'),
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ),
        ],
      );
    });
  }
}
