// Pieces of the AI upload page: the photo frame and the preference picker.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/makeover/controllers/ai_upload_controller.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

const Color aiUploadBlue = Color(0xFF0A0088);
const Color aiUploadYellow = Color(0xFFFFAE00);

/// Statically instantiated list of preferences to protect Flutter Web compilation.
final List<({String label, IconData icon})> aiStylePreferences = [
  (label: 'Casual', icon: Icons.brightness_low),
  (label: 'Afro-Chic', icon: Icons.blur_circular),
  (label: 'Corporate', icon: Icons.business_center),
  (label: 'Streetwear', icon: Icons.checkroom),
  (label: 'Glamour', icon: Icons.auto_awesome),
];

class AiUploadFrame extends StatelessWidget {
  const AiUploadFrame({super.key, required this.controller});

  final AiUploadController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Obx(() {
      final selected = controller.selectedImageBytes.value;
      final hasImage =
          selected != null || controller.existingImageUrl.value != null;
      return Container(
        width: double.infinity,
        height: 320,
        decoration: BoxDecoration(
          color: hasImage ? Colors.white : colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: selected != null
              ? _SelectedPhoto(
                  bytes: selected,
                  onClear: controller.clearSelectedImage,
                )
              : controller.isLoadingExisting.value
              ? const Center(child: CircularProgressIndicator())
              : _savedOrEmpty(context),
        ),
      );
    });
  }

  Widget _savedOrEmpty(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final url = controller.existingImageUrl.value;
    if (url != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _savedPhoto(url),
          Positioned(
            top: 10,
            right: 10,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                onPressed: controller.clearSelectedImage,
              ),
            ),
          ),
        ],
      );
    }
    if (controller.existingImageError.value != null) {
      return _LoadError(controller: controller);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.upload_file_outlined,
          size: 60,
          color: colors.outlineVariant,
        ),
        const SizedBox(height: 12),
        Text(
          'Upload Your Photo to Begin',
          style: TextStyle(
            color: colors.outline,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _savedPhoto(String url) {
    final bytes = controller.existingImageBytes.value;
    if (kIsWeb) {
      return AppNetworkImage(
        url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        fallback: _LoadError(controller: controller),
      );
    }
    if (bytes == null) return const Center(child: CircularProgressIndicator());
    return Image.memory(
      bytes,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('[AiUpload] Image.memory failed: $error');
        debugPrintStack(stackTrace: stackTrace);
        return _LoadError(controller: controller);
      },
    );
  }
}

class _SelectedPhoto extends StatelessWidget {
  const _SelectedPhoto({required this.bytes, required this.onClear});

  final Uint8List bytes;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              width: double.infinity,
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: CircleAvatar(
            backgroundColor: Colors.black45,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              onPressed: onClear,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.controller});

  final AiUploadController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 60,
              color: colors.outlineVariant,
            ),
            const SizedBox(height: 12),
            Text(
              controller.existingImageError.value ??
                  'Saved photo could not be displayed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.outline,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: controller.loadExistingFullBodyImage,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class AiPreferencePicker extends StatelessWidget {
  const AiPreferencePicker({super.key, required this.controller});

  final AiUploadController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 80,
      child: Obx(() {
        final selected = controller.selectedPreference.value;
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: aiStylePreferences.length,
          itemBuilder: (context, index) {
            final item = aiStylePreferences[index];
            final isSelected = selected == index;
            return GestureDetector(
              onTap: () => controller.selectPreference(index),
              child: Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? aiUploadBlue : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? aiUploadBlue
                              : colors.outlineVariant,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: aiUploadBlue.withAlpha(
                                    (0.15 * 255).round(),
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        item.icon,
                        size: 22,
                        color: isSelected ? Colors.white : colors.outline,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? aiUploadBlue : colors.outline,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
