// Quick add (review item K-1): a flea-market trader puts a piece up in a few
// taps. A photo, a price, what kind of piece it is and the sizes in hand, then
// "Add to my shop"; everything else the full form asks for gets a default and
// can be edited later. Built for adding many pieces in a row, so after each one
// the screen clears and keeps the kind.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:banigoba/modules/makeover/widgets/ai_photo_consent.dart';
import 'package:banigoba/modules/shop/controllers/quick_add_controller.dart';
import 'package:banigoba/modules/shop/models/quick_add.dart';
import 'package:banigoba/modules/shop/services/quick_add_saver.dart';
import 'package:banigoba/modules/shop/widgets/quick_add_photo_area.dart';
import 'package:banigoba/modules/shop/widgets/quick_add_stepper.dart';
import 'package:banigoba/modules/wardrobe/services/garment_tagger.dart';

class QuickAddPage extends StatelessWidget {
  const QuickAddPage({
    super.key,
    this.saver,
    this.pickPhoto,
    this.tagger,
    this.confirmAiUse = ensureAiPhotoConsent,
  });

  /// Asks before photos go to the AI (App Store 5.1.2); injected in tests.
  final Future<bool> Function(BuildContext context) confirmAiUse;

  final QuickAddSaver? saver;
  final PickPhoto? pickPhoto;
  final GarmentTagger? tagger;

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: created and disposed with the widget.
    return GetBuilder<QuickAddController>(
      init: QuickAddController(
        saver: saver,
        pickPhoto: pickPhoto,
        tagger: tagger,
        confirmAiUse: () => confirmAiUse(context),
      ),
      global: false,
      builder: (controller) => _QuickAddView(controller: controller),
    );
  }
}

class _QuickAddView extends StatelessWidget {
  const _QuickAddView({required this.controller});

  static const Color _primary = Color(0xFF0D0140);

  final QuickAddController controller;

  Future<void> _choosePhoto(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const ValueKey('photo_camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              key: const ValueKey('photo_gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from photos'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    await controller.choosePhotoFrom(source);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final draft = controller.draft.value;
      final kind = draft.kind;
      final chosen = draft.sizes.keys.toList()
        ..sort(
          (a, b) => kind.sizes.indexOf(a).compareTo(kind.sizes.indexOf(b)),
        );
      final added = controller.added.value;
      final saving = controller.saving.value;

      return Scaffold(
        appBar: AppBar(
          title: Text(added == 0 ? 'Quick add' : 'Quick add · $added added'),
          backgroundColor: _primary,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            QuickAddPhotoArea(
              photo: controller.photo.value,
              suggested: controller.suggested.value,
              onTap: () => _choosePhoto(context),
            ),
            const SizedBox(height: 18),
            TextField(
              key: const ValueKey('price_field'),
              controller: controller.price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixText: r'$ ',
              ),
              onChanged: controller.onPriceChanged,
            ),
            const SizedBox(height: 18),
            const Text(
              'What is it?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in QuickKind.values)
                  ChoiceChip(
                    key: ValueKey('kind_${option.name}'),
                    label: Text(option.defaultName),
                    selected: kind == option,
                    onSelected: (_) => controller.setKind(option),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (kind.isSized) ...[
              const Text(
                'Which sizes do you have?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final size in kind.sizes)
                    FilterChip(
                      key: ValueKey('size_$size'),
                      label: Text(size),
                      selected: draft.sizes.containsKey(size),
                      onSelected: (on) =>
                          controller.adjustSize(size, on ? 1 : -99),
                    ),
                ],
              ),
              for (final size in chosen)
                QuickAddStepper(
                  key: ValueKey('count_$size'),
                  label: 'Size $size',
                  count: draft.sizes[size] ?? 0,
                  onMinus: () => controller.adjustSize(size, -1),
                  onPlus: () => controller.adjustSize(size, 1),
                ),
            ] else
              QuickAddStepper(
                key: const ValueKey('count_one'),
                label: 'How many do you have?',
                count: draft.quantity,
                onMinus: () => controller.adjustQuantity(-1),
                onPlus: () => controller.adjustQuantity(1),
              ),
            const SizedBox(height: 18),
            TextField(
              key: const ValueKey('name_field'),
              controller: controller.name,
              decoration: InputDecoration(
                labelText: 'Name (optional)',
                hintText: kind.defaultName,
              ),
              onChanged: controller.onNameChanged,
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const ValueKey('quick_add_save'),
              onPressed: saving ? null : controller.save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: _primary,
              ),
              child: Text(saving ? 'Adding…' : 'Add to my shop'),
            ),
          ],
        ),
      );
    });
  }
}
