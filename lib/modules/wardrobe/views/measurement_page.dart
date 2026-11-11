// Calibrates body proportions before outfit generation and recommendations.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/wardrobe/controllers/measurement_controller.dart';
import 'package:banigoba/modules/wardrobe/widgets/measurement_slider.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

class MeasurementPage extends StatelessWidget {
  const MeasurementPage({
    super.key,
    this.imageBytes,
    this.imageUrl,
    this.plannedDate,
    this.eventId,
    this.eventName,
  });

  final Uint8List? imageBytes;
  final String? imageUrl;
  final DateTime? plannedDate;
  final String? eventId;
  final String? eventName;

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: built from its parameters, disposed with it.
    return GetBuilder<MeasurementController>(
      init: MeasurementController(
        imageBytes: imageBytes,
        imageUrl: imageUrl,
        plannedDate: plannedDate,
        eventId: eventId,
        eventName: eventName,
      ),
      global: false,
      builder: (controller) => _MeasurementView(controller: controller),
    );
  }
}

class _MeasurementView extends StatelessWidget {
  const _MeasurementView({required this.controller});

  final MeasurementController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: Get.back,
          icon: Icon(Icons.chevron_left_rounded, color: colors.onSurface),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analyzing Your Measurement',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 0.92,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: _SourceImage(controller: controller),
              ),
            ),
            const SizedBox(height: 18),
            Obx(
              () => MeasurementSlider(
                label: 'Height',
                value: controller.height.value,
                onChanged: controller.height.call,
              ),
            ),
            Obx(
              () => MeasurementSlider(
                label: 'Waist',
                value: controller.waist.value,
                onChanged: controller.waist.call,
              ),
            ),
            Obx(
              () => MeasurementSlider(
                label: 'Shoulders',
                value: controller.shoulders.value,
                onChanged: controller.shoulders.call,
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: SizedBox(
                width: 190,
                height: 46,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.isSaving.value
                        ? null
                        : controller.confirm,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: MeasurementSlider.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: controller.isSaving.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Confirm Measurement',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceImage extends StatelessWidget {
  const _SourceImage({required this.controller});

  final MeasurementController controller;

  @override
  Widget build(BuildContext context) {
    final bytes = controller.imageBytes;
    final url = controller.imageUrl;
    if (bytes != null) return Image.memory(bytes, fit: BoxFit.contain);
    if (url != null) {
      return AppNetworkImage(
        url,
        fit: BoxFit.contain,
        fallback: const _Placeholder(),
      );
    }
    return const _Placeholder();
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF9A84F5),
      child: Center(
        child: Icon(Icons.person_outline, size: 140, color: Colors.white70),
      ),
    );
  }
}
