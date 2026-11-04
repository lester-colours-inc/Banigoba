// Moves a saved look to another category (or none), from Smart Wardrobe ›
// Saved Looks (October 2026 review, W-6). Returns the new category, '' for
// "no category", or null if dismissed.
import 'package:flutter/material.dart';

import 'saved_to_wardrobe_sheet.dart' show kStarterLookCategories;

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

class ChangeLookCategorySheet extends StatefulWidget {
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
  State<ChangeLookCategorySheet> createState() =>
      _ChangeLookCategorySheetState();
}

class _ChangeLookCategorySheetState extends State<ChangeLookCategorySheet> {
  final _newCategory = TextEditingController();
  late String _selected = widget.currentCategory.trim();

  @override
  void dispose() {
    _newCategory.dispose();
    super.dispose();
  }

  /// A typed new category wins over a chip.
  String get _chosen {
    final typed = _newCategory.text.trim();
    return typed.isNotEmpty ? typed : _selected;
  }

  bool get _changed => _chosen != widget.currentCategory.trim();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final options = categoryOptions(
      widget.existingCategories,
      widget.currentCategory,
    );
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
            'Move to a ${widget.noun}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            widget.currentCategory.trim().isEmpty
                ? 'This ${widget.subject} has no ${widget.noun} yet.'
                : 'Now in "${widget.currentCategory.trim()}".',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                ChoiceChip(
                  key: ValueKey('move_category_$option'),
                  label: Text(option),
                  selected: _selected == option,
                  onSelected: (_) => setState(() {
                    _selected = option;
                    _newCategory.clear();
                  }),
                ),
              ChoiceChip(
                key: const ValueKey('move_category_none'),
                label: Text('No ${widget.noun}'),
                avatar: const Icon(Icons.block, size: 16),
                selected: _selected.isEmpty && _newCategory.text.trim().isEmpty,
                onSelected: (_) => setState(() {
                  _selected = '';
                  _newCategory.clear();
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('move_category_new'),
            controller: _newCategory,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 30,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Or make a new ${widget.noun}',
              prefixIcon: const Icon(Icons.create_new_folder_outlined),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('move_category_save'),
              onPressed: _changed
                  ? () => Navigator.pop(context, _chosen)
                  : null,
              child: Text(
                _chosen.isEmpty
                    ? 'Remove from ${widget.noun}'
                    : 'Move to $_chosen',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
