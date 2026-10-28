// "Near me / Everyone" at the top of the Community feed (P-5, A-4). Near me
// is the people you follow plus people in your city; without a city it asks
// for one instead of guessing.
import 'package:flutter/material.dart';

class NearMeBar extends StatelessWidget {
  const NearMeBar({
    super.key,
    required this.city,
    required this.nearMe,
    required this.onChanged,
    required this.onSetCity,
  });

  /// The person's city as they wrote it, '' when not set.
  final String city;
  final bool nearMe;
  final ValueChanged<bool> onChanged;
  final VoidCallback onSetCity;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasCity = city.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ChoiceChip(
              key: const ValueKey('near_me_chip'),
              label: Text(hasCity ? 'Near me · ${city.trim()}' : 'Near me'),
              selected: nearMe,
              onSelected: (_) => onChanged(true),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              key: const ValueKey('everyone_chip'),
              label: const Text('Everyone'),
              selected: !nearMe,
              onSelected: (_) => onChanged(false),
            ),
          ],
        ),
        if (!hasCity)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Add your city to see looks from people near you. Others '
                    'will see your city, nothing more.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                TextButton(
                  key: const ValueKey('add_city'),
                  onPressed: onSetCity,
                  child: const Text('Add city'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
