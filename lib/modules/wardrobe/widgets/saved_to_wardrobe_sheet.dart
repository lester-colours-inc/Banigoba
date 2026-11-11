// Shown after "Save to Smart Wardrobe": says where the look went, lets the
// user file it under a category, and opens the wardrobe. Saving should never
// feel like a dark hole (October 2026 review, P-3).
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/wardrobe/controllers/saved_to_wardrobe_controller.dart';

export 'package:banigoba/modules/wardrobe/controllers/saved_to_wardrobe_controller.dart'
    show kStarterLookCategories;

/// Returns the chosen category ('' for none), or null if dismissed.
Future<String?> showSavedToWardrobeSheet(
  BuildContext context, {
  required List<String> existingCategories,
  required VoidCallback onOpenWardrobe,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => SavedToWardrobeSheet(
      existingCategories: existingCategories,
      onOpenWardrobe: onOpenWardrobe,
    ),
  );
}

class SavedToWardrobeSheet extends StatelessWidget {
  const SavedToWardrobeSheet({
    super.key,
    required this.existingCategories,
    required this.onOpenWardrobe,
  });

  final List<String> existingCategories;
  final VoidCallback onOpenWardrobe;

  @override
  Widget build(BuildContext context) {
    // Scoped to the sheet: built here, disposed when it closes.
    return GetBuilder<SavedToWardrobeController>(
      init: SavedToWardrobeController(existingCategories: existingCategories),
      global: false,
      builder: (controller) =>
          _SheetBody(controller: controller, onOpenWardrobe: onOpenWardrobe),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.controller, required this.onOpenWardrobe});

  final SavedToWardrobeController controller;
  final VoidCallback onOpenWardrobe;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checkroom, color: colors.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Saved to My Smart Wardrobe',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Find it under Saved Looks. Add it to a category to keep your '
            'looks easy to find.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in controller.options)
                  ChoiceChip(
                    key: ValueKey('look_category_$option'),
                    label: Text(option),
                    selected: controller.selected.value == option,
                    onSelected: (isSelected) =>
                        controller.toggle(option, isSelected: isSelected),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('look_category_new'),
            controller: controller.newCategory,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 30,
            decoration: const InputDecoration(
              labelText: 'Or make a new category',
              prefixIcon: Icon(Icons.create_new_folder_outlined),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                key: const ValueKey('open_wardrobe'),
                onPressed: () {
                  Navigator.pop(context, controller.chosen);
                  onOpenWardrobe();
                },
                child: const Text('View in wardrobe'),
              ),
              const Spacer(),
              Obx(
                () => FilledButton(
                  key: const ValueKey('save_look_category'),
                  onPressed: () => Navigator.pop(context, controller.chosen),
                  child: Text(
                    controller.chosen.isEmpty
                        ? 'Done'
                        : 'Add to ${controller.chosen}',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
