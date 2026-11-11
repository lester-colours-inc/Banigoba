// Asks what a look should say before it goes to the Home feed.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Null when cancelled; a default caption when left empty.
Future<String?> askLookCaption() => Get.dialog<String>(const _CaptionDialog());

class _CaptionController extends GetxController {
  final TextEditingController text = TextEditingController();

  void save() {
    final trimmed = text.text.trim();
    Get.back<String>(
      result: trimmed.isEmpty ? 'My completed try-on look' : trimmed,
    );
  }

  @override
  void onClose() {
    text.dispose();
    super.onClose();
  }
}

class _CaptionDialog extends StatelessWidget {
  const _CaptionDialog();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<_CaptionController>(
      init: _CaptionController(),
      global: false,
      builder: (caption) => AlertDialog(
        title: const Text('Caption your look'),
        content: TextField(
          controller: caption.text,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          maxLength: 160,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'What should this Daily Dress Up say?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          FilledButton(onPressed: caption.save, child: const Text('Save Look')),
        ],
      ),
    );
  }
}
