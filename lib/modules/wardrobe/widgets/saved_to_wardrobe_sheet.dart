// Shown after "Save to Smart Wardrobe": says where the look went, lets the
// user file it under a category, and opens the wardrobe. Saving should never
// feel like a dark hole (October 2026 review, P-3).
import 'package:flutter/material.dart';

/// Suggested when the user has no categories of their own yet.
const List<String> kStarterLookCategories = [
  'Work',
  'Church',
  'Weddings',
  'Weekend',
  'Date night',
];

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

class SavedToWardrobeSheet extends StatefulWidget {
  const SavedToWardrobeSheet({
    super.key,
    required this.existingCategories,
    required this.onOpenWardrobe,
  });

  final List<String> existingCategories;
  final VoidCallback onOpenWardrobe;

  @override
  State<SavedToWardrobeSheet> createState() => _SavedToWardrobeSheetState();
}

class _SavedToWardrobeSheetState extends State<SavedToWardrobeSheet> {
  final _newCategory = TextEditingController();
  String _selected = '';

  List<String> get _options => widget.existingCategories.isEmpty
      ? kStarterLookCategories
      : widget.existingCategories;

  @override
  void dispose() {
    _newCategory.dispose();
    super.dispose();
  }

  String get _chosen {
    final typed = _newCategory.text.trim();
    return typed.isNotEmpty ? typed : _selected;
  }

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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in _options)
                ChoiceChip(
                  key: ValueKey('look_category_$option'),
                  label: Text(option),
                  selected: _selected == option,
                  onSelected: (selected) =>
                      setState(() => _selected = selected ? option : ''),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('look_category_new'),
            controller: _newCategory,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 30,
            onChanged: (_) => setState(() {}),
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
                  Navigator.pop(context, _chosen);
                  widget.onOpenWardrobe();
                },
                child: const Text('View in wardrobe'),
              ),
              const Spacer(),
              FilledButton(
                key: const ValueKey('save_look_category'),
                onPressed: () => Navigator.pop(context, _chosen),
                child: Text(_chosen.isEmpty ? 'Done' : 'Add to $_chosen'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
