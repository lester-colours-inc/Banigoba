// Form fields and the save button used on the hairstyle upload screen.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/admin/models/hairstyle_catalog_options.dart';

class UploadDropdown extends StatelessWidget {
  const UploadDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        // Rebuilt with the value, so a change made elsewhere shows.
        key: ValueKey('$label-$value-${options.length}'),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        items: [
          for (final option in options)
            DropdownMenuItem<String>(
              value: option,
              child: Text(option, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class UploadMultiSelect extends StatelessWidget {
  const UploadMultiSelect({
    super.key,
    required this.label,
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final Set<String> selected;
  final List<String> options;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              FilterChip(
                label: Text(option),
                selected: selected.contains(option),
                selectedColor: hairNavy.withValues(alpha: 0.14),
                checkmarkColor: hairNavy,
                labelStyle: TextStyle(
                  color: selected.contains(option)
                      ? hairNavy
                      : colors.onSurface,
                  fontWeight: selected.contains(option)
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
                onSelected: (value) {
                  final next = {...selected};
                  if (value) {
                    next.add(option);
                  } else if (next.length > 1) {
                    next.remove(option);
                  }
                  onChanged(next);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class HairButton extends StatelessWidget {
  const HairButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.65),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon ?? Icons.check_rounded, size: 20),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
