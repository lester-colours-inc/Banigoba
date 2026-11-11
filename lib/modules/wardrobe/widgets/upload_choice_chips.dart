// Small building blocks of the upload form: a label, a dropdown, and a wrap
// of filter chips bound to a list.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const Color _primary = Color(0xFF0D0140);

class UploadLabel extends StatelessWidget {
  const UploadLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
    );
  }
}

class UploadDropdown extends StatelessWidget {
  const UploadDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UploadLabel(label),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          // Re-keyed so a value set by the AI suggestion shows up.
          key: ValueKey('$label-$value'),
          initialValue: value,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e[0].toUpperCase() + e.substring(1)),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 10),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

class UploadChoiceChips extends StatelessWidget {
  const UploadChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final List<String> options;
  final RxList<String> selected;
  final void Function(String option, {required bool selected}) onToggle;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((option) {
          final isSelected = selected.contains(option);
          return FilterChip(
            label: Text(option[0].toUpperCase() + option.substring(1)),
            selected: isSelected,
            onSelected: (value) => onToggle(option, selected: value),
            selectedColor: _primary.withValues(alpha: 0.2),
            checkmarkColor: _primary,
            labelStyle: TextStyle(
              color: isSelected ? _primary : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          );
        }).toList(),
      ),
    );
  }
}
