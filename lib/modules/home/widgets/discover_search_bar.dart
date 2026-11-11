// The search field on Discover.
import 'package:flutter/material.dart';

class DiscoverSearchBar extends StatelessWidget {
  const DiscoverSearchBar({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.outlineVariant, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: colors.outline, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search people by name or @username',
                hintStyle: TextStyle(color: colors.outline, fontSize: 16),
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
