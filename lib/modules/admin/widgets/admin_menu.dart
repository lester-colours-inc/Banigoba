// The row of section buttons at the top of the curators' workspace.
import 'package:flutter/material.dart';

class AdminMenuItem {
  const AdminMenuItem({
    required this.label,
    required this.icon,
    required this.title,
  });

  final String label;
  final IconData icon;
  final String title;
}

class AdminMenu extends StatelessWidget {
  const AdminMenu({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<AdminMenuItem> items;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final selected = selectedIndex == index;
          return SizedBox(
            width: 118,
            child: OutlinedButton(
              onPressed: () => onSelected(index),
              style: OutlinedButton.styleFrom(
                backgroundColor: selected
                    ? const Color(0xFF0D0140)
                    : colors.surfaceContainerLow,
                foregroundColor: selected ? Colors.white : colors.onSurface,
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF0D0140)
                      : colors.outlineVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 20),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
