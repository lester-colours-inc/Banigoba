// Collects or reuses a full-body image before the user selects a makeover style.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:banigoba/modules/makeover/controllers/ai_upload_controller.dart';
import 'package:banigoba/modules/makeover/widgets/ai_upload_parts.dart';
import 'package:banigoba/modules/shop/widgets/cart_badge_button.dart';

/// The starting point of the AI Makeover flow.
/// Users upload a full-body photo or take a selfie to be used for the AI generation.
class AiUploadPage extends StatelessWidget {
  const AiUploadPage({
    super.key,
    this.plannedDate,
    this.eventId,
    this.eventName,
  });

  final DateTime? plannedDate;
  final String? eventId;
  final String? eventName;

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: built from its parameters, disposed with it.
    return GetBuilder<AiUploadController>(
      init: AiUploadController(
        plannedDate: plannedDate,
        eventId: eventId,
        eventName: eventName,
      ),
      global: false,
      builder: (controller) => _AiUploadView(controller: controller),
    );
  }
}

class _AiUploadView extends StatelessWidget {
  const _AiUploadView({required this.controller});

  final AiUploadController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: colors.onSurface),
          onPressed: () {},
        ),
        actions: [
          CartBadgeButton(
            onPressed: controller.openCart,
            color: colors.onSurface,
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: colors.onSurface,
              ),
              onPressed: Get.back,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              'My Daily Dress Up',
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 25),
            Text(
              'Upload Your Image to Start',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            AiUploadFrame(controller: controller),
            const SizedBox(height: 15),
            _UseSavedPhotoButton(controller: controller),
            _PhotoButtons(controller: controller),
            const SizedBox(height: 30),
            Text(
              'Styling Preferences',
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            AiPreferencePicker(controller: controller),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

ButtonStyle _buttonStyle(Color color) => ElevatedButton.styleFrom(
  backgroundColor: color,
  foregroundColor: Colors.white,
  minimumSize: const Size(double.infinity, 52),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  elevation: 0,
);

class _UseSavedPhotoButton extends StatelessWidget {
  const _UseSavedPhotoButton({required this.controller});

  final AiUploadController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.existingImageUrl.value == null ||
          controller.selectedImageBytes.value != null) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: ElevatedButton.icon(
          onPressed: controller.isPicking.value
              ? null
              : controller.useExistingSavedPhoto,
          icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
          label: const Text('Use Saved FullBody Photo'),
          style: _buttonStyle(aiUploadBlue),
        ),
      );
    });
  }
}

class _PhotoButtons extends StatelessWidget {
  const _PhotoButtons({required this.controller});

  final AiUploadController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = controller.isPicking.value;
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: busy
                  ? null
                  : () => controller.pickImage(ImageSource.gallery),
              icon: const Icon(
                Icons.cloud_upload_outlined,
                size: 20,
                color: Colors.white,
              ),
              label: const Text(
                'Upload Photo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: _buttonStyle(aiUploadBlue),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: busy
                  ? null
                  : () => controller.pickImage(ImageSource.camera),
              icon: const Icon(
                Icons.add_a_photo_outlined,
                size: 20,
                color: Colors.white,
              ),
              label: const Text(
                'Take a Photo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: _buttonStyle(aiUploadYellow),
            ),
          ),
        ],
      );
    });
  }
}
