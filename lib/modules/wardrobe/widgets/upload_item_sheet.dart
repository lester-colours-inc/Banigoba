// The "Upload to Wardrobe" bottom sheet.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/profile_details/models/body_profile.dart';
import 'package:banigoba/modules/wardrobe/controllers/wardrobe_upload_controller.dart';
import 'package:banigoba/modules/wardrobe/widgets/upload_choice_chips.dart';
import 'package:banigoba/modules/wardrobe/widgets/upload_photo_box.dart';

const Color _primary = Color(0xFF0D0140);

Future<void> showUploadItemSheet({required String userId}) {
  return Get.bottomSheet<void>(
    UploadItemSheet(userId: userId),
    isScrollControlled: true,
    backgroundColor: Get.theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  );
}

class UploadItemSheet extends StatelessWidget {
  const UploadItemSheet({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    // Scoped to the sheet: built here, disposed when it closes.
    return GetBuilder<WardrobeUploadController>(
      init: WardrobeUploadController(userId: userId),
      global: false,
      builder: (form) => SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  key: const ValueKey('wardrobe_upload_back'),
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: Get.back,
                ),
                const Expanded(
                  child: Text(
                    'Upload to Wardrobe',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                // Balances the back button so the title stays centred.
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 12),
            UploadPhotoBox(form: form),
            const SizedBox(height: 15),
            TextField(
              controller: form.name,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            _CategoryRow(form: form),
            const SizedBox(height: 15),
            Obx(
              () => UploadDropdown(
                label: 'Style',
                value: form.styleTag.value,
                items: WardrobeUploadController.styleOptions,
                onChanged: (v) => form.styleTag.value = v!,
              ),
            ),
            const SizedBox(height: 15),
            // Size and key measurements (W-4), so the wardrobe knows what
            // fits and shops can match like for like.
            const UploadLabel('Size'),
            const SizedBox(height: 8),
            Obx(
              () => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in BodyProfile.clothingSizes)
                    ChoiceChip(
                      key: ValueKey('wardrobe_size_$option'),
                      label: Text(option),
                      selected: form.size.value == option,
                      onSelected: (selected) =>
                          form.selectSize(option, selected: selected),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _MeasurementRow(form: form),
            const SizedBox(height: 15),
            const UploadLabel('Select Colours'),
            Obx(
              () => form.coloursFromPhoto.value
                  ? Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Picked from your photo. Tap to change.',
                        key: const ValueKey('colours_from_photo'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 8),
            UploadChoiceChips(
              options: WardrobeUploadController.availableColours,
              selected: form.colours,
              onToggle: form.toggleColour,
            ),
            const SizedBox(height: 15),
            _GenderVisibilityRow(form: form),
            const SizedBox(height: 15),
            const UploadLabel('Weather Tags'),
            const SizedBox(height: 8),
            UploadChoiceChips(
              options: WardrobeUploadController.weatherTagOptions,
              selected: form.weatherTags,
              onToggle: form.toggleWeather,
            ),
            const SizedBox(height: 15),
            const UploadLabel('Functional Tags'),
            const SizedBox(height: 8),
            UploadChoiceChips(
              options: WardrobeUploadController.functionalTagOptions,
              selected: form.functionalTags,
              onToggle: form.toggleFunctional,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: form.upload,
                child: const Text(
                  'Upload Item',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.form});

  final WardrobeUploadController form;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: UploadDropdown(
              label: 'Category',
              value: form.category.value,
              items: WardrobeUploadController.categoryData.keys.toList(),
              onChanged: (v) => form.setCategory(v!),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: UploadDropdown(
              label: 'Subcategory',
              value: form.subcategory.value,
              items:
                  WardrobeUploadController.categoryData[form.category.value]!,
              onChanged: (v) => form.subcategory.value = v!,
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementRow extends StatelessWidget {
  const _MeasurementRow({required this.form});

  final WardrobeUploadController form;

  @override
  Widget build(BuildContext context) {
    const keyboard = TextInputType.numberWithOptions(decimal: true);
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey('wardrobe_shoulders'),
            controller: form.shoulders,
            keyboardType: keyboard,
            decoration: const InputDecoration(
              labelText: 'Shoulders (cm)',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            key: const ValueKey('wardrobe_length'),
            controller: form.length,
            keyboardType: keyboard,
            decoration: const InputDecoration(
              labelText: 'Length (cm)',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}

class _GenderVisibilityRow extends StatelessWidget {
  const _GenderVisibilityRow({required this.form});

  final WardrobeUploadController form;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: UploadDropdown(
              label: 'Gender',
              value: form.gender.value,
              items: WardrobeUploadController.genderOptions,
              onChanged: (v) => form.gender.value = v!,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: UploadDropdown(
              label: 'Visibility',
              value: form.visibility.value,
              items: WardrobeUploadController.visibilityOptions,
              onChanged: (v) => form.visibility.value = v!,
            ),
          ),
        ],
      ),
    );
  }
}
