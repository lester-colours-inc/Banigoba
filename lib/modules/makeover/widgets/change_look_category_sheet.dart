// Moves a saved look to another category (or none), from Smart Wardrobe ›
// Saved Looks (October 2026 review, W-6). Returns the new category, '' for
// "no category", or null if dismissed.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/makeover/controllers/change_category_controller.dart';

import 'package:banigoba/modules/wardrobe/widgets/saved_to_wardrobe_sheet.dart'
    show kStarterLookCategories;

/// The categories to offer: the user's own, plus [current], A to Z. Starter
/// suggestions only when they have none yet.
List<String> categoryOptions(Iterable<String> existing, String current) {
  final names = {
    for (final name in [...existing, current])
      if (name.trim().isNotEmpty) name.trim(),
  };
  if (names.isEmpty) return List.unmodifiable(kStarterLookCategories);
  return List.unmodifiable(names.toList()..sort());
}

Future<String?> showChangeLookCategorySheet(
  BuildContext context, {
  required List<String> existingCategories,
  required String currentCategory,
  String noun = 'category',
  String subject = 'look',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ChangeLookCategorySheet(
      existingCategories: existingCategories,
      currentCategory: currentCategory,
      noun: noun,
      subject: subject,
    ),
  );
}

class ChangeLookCategorySheet extends StatelessWidget {
  const ChangeLookCategorySheet({
    super.key,
    required this.existingCategories,
    required this.currentCategory,
    this.noun = 'category',
    this.subject = 'look',
  });

  final List<String> existingCategories;
  final String currentCategory;

  /// What the groups are called ('category', or 'collection' for clothes) and
  /// what is being moved ('look', or 'piece').
  final String noun;
  final String subject;

  @override
  Widget build(BuildContext context) {
    // Scoped to the sheet: built here, disposed when it closes.
    return GetBuilder<ChangeCategoryController>(
      init: ChangeCategoryController(currentCategory: currentCategory),
      global: false,
      builder: (category) => _content(context, category),
    );
  }

  Widget _content(BuildContext context, ChangeCategoryController category) {
    final colors = Theme.of(context).colorScheme;
    final options = categoryOptions(existingCategories, currentCategory);
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
          Text(
            'Move to a $noun',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            currentCategory.trim().isEmpty
                ? 'This $subject has no $noun yet.'
                : 'Now in "${currentCategory.trim()}".',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in options)
                  ChoiceChip(
                    key: ValueKey('move_category_$option'),
                    label: Text(option),
                    selected: category.selected.value == option,
                    onSelected: (_) => category.choose(option),
                  ),
                ChoiceChip(
                  key: const ValueKey('move_category_none'),
                  label: Text('No $noun'),
                  avatar: const Icon(Icons.block, size: 16),
                  selected:
                      category.selected.value.isEmpty &&
                      category.typed.value.trim().isEmpty,
                  onSelected: (_) => category.choose(''),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('move_category_new'),
            controller: category.newCategory,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 30,
            decoration: InputDecoration(
              labelText: 'Or make a new $noun',
              prefixIcon: const Icon(Icons.create_new_folder_outlined),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Obx(
              () => FilledButton(
                key: const ValueKey('move_category_save'),
                onPressed: category.changed
                    ? () => Navigator.pop(context, category.chosen)
                    : null,
                child: Text(
                  category.chosen.isEmpty
                      ? 'Remove from $noun'
                      : 'Move to ${category.chosen}',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
