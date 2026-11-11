// The form sections of My Profile Details: photos, sizes and measurements.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/profile_details/controllers/body_profile_controller.dart';
import 'package:banigoba/modules/profile_details/models/body_profile.dart';
import 'package:banigoba/modules/profile_details/widgets/measurement_field.dart';
import 'package:banigoba/modules/profile_details/widgets/profile_photo_tile.dart';

class BodyProfilePhotos extends StatelessWidget {
  const BodyProfilePhotos({super.key, required this.controller});

  final BodyProfileController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    // Read here so the tiles follow uploads and saves.
    controller.uploading.length;
    return _buildPhotos();
  });

  Widget _buildPhotos() {
    // Two tiles per row so each stays large enough to read on a phone.
    final firstRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ProfilePhotoTile(
            key: const ValueKey('photo_face'),
            label: 'Face',
            hint: 'Front-facing, in good light',
            icon: Icons.face_outlined,
            imageUrl: controller.saved.value.facePhotoUrl,
            isUploading: controller.uploading.contains(BodyPhoto.face),
            onTap: () => controller.changePhoto(BodyPhoto.face),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ProfilePhotoTile(
            key: const ValueKey('photo_full_body'),
            label: 'Full body',
            hint: 'Head to toe, standing straight',
            icon: Icons.accessibility_new,
            imageUrl: controller.saved.value.fullBodyPhotoUrl,
            isUploading: controller.uploading.contains(BodyPhoto.fullBody),
            onTap: () => controller.changePhoto(BodyPhoto.fullBody),
          ),
        ),
      ],
    );
    return Column(
      children: [
        firstRow,
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ProfilePhotoTile(
                key: const ValueKey('photo_hand'),
                label: 'Hand',
                hint: 'Back of your hand, fingers apart',
                icon: Icons.back_hand_outlined,
                imageUrl: controller.saved.value.handPhotoUrl,
                isUploading: controller.uploading.contains(BodyPhoto.hand),
                onTap: () => controller.changePhoto(BodyPhoto.hand),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }
}

class BodyProfileSizes extends StatelessWidget {
  const BodyProfileSizes({super.key, required this.controller});

  final BodyProfileController controller;

  @override
  Widget build(BuildContext context) => _buildSizes(context);

  Widget _buildSizes(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clothing size',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final size in BodyProfile.clothingSizes)
                ChoiceChip(
                  key: ValueKey('clothing_size_$size'),
                  label: Text(size),
                  selected: controller.clothingSize.value == size,
                  showCheckmark: false,
                  onSelected: (selected) =>
                      controller.selectClothingSize(size, selected: selected),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('shoe_size'),
            controller: controller.shoeSize,
            onChanged: controller.markChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) => BodyProfile.validateShoeSize(value ?? ''),
            decoration: const InputDecoration(
              labelText: 'Shoe size',
              prefixText: 'UK ',
              hintText: 'e.g. 8',
            ),
          ),
        ],
      ),
    );
  }
}

class BodyMeasurementGrid extends StatelessWidget {
  const BodyMeasurementGrid({
    super.key,
    required this.controller,
    required this.measurements,
  });

  final BodyProfileController controller;
  final List<BodyMeasurement> measurements;

  @override
  Widget build(BuildContext context) => _buildMeasurementGrid(measurements);

  Widget _buildMeasurementGrid(List<BodyMeasurement> measurements) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final measurement in measurements)
              SizedBox(
                width: width,
                child: MeasurementField(
                  measurement: measurement,
                  controller: controller.measurements[measurement]!,
                  onChanged: controller.markChanged,
                ),
              ),
          ],
        );
      },
    );
  }
}
