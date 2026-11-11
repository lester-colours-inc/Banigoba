// Pieces of the event submission form: the flyer picker and a text field.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/events/controllers/event_submission_controller.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

class EventFormField extends StatelessWidget {
  const EventFormField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.required = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: required
            ? (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

/// Tap to choose the event flyer; shows the new or the existing one.
class EventFlyerPicker extends StatelessWidget {
  const EventFlyerPicker({super.key, required this.controller});

  final EventSubmissionController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Obx(
      () => GestureDetector(
        onTap: controller.saving.value ? null : controller.pickFlyer,
        child: AspectRatio(
          aspectRatio: 1.45,
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: _preview(context),
          ),
        ),
      ),
    );
  }

  Widget _preview(BuildContext context) {
    final background = Theme.of(context).colorScheme.surfaceContainerHighest;
    final bytes = controller.flyerBytes.value;
    if (bytes != null) {
      return ColoredBox(
        color: background,
        child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
      );
    }
    final url = controller.existingFlyerUrl.value;
    if (url.isNotEmpty) {
      return ColoredBox(
        color: background,
        child: Center(
          child: AppNetworkImage(
            url,
            fit: BoxFit.contain,
            fallback: const _FlyerPlaceholder(),
          ),
        ),
      );
    }
    return const _FlyerPlaceholder();
  }
}

class _FlyerPlaceholder extends StatelessWidget {
  const _FlyerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.upload_file_outlined, size: 36),
        SizedBox(height: 8),
        Text('Upload event flyer'),
      ],
    );
  }
}
