// "Near me / Everyone" at the top of the Community feed (P-5, A-4). Near me
// is the people you follow plus people near you, found from the phone's
// location when allowed and from the typed city otherwise; with neither it
// asks instead of guessing.
import 'package:flutter/material.dart';

class NearMeBar extends StatelessWidget {
  const NearMeBar({
    super.key,
    required this.city,
    required this.nearMe,
    required this.onChanged,
    required this.onSetCity,
    this.hasLocation = false,
    this.onUseLocation,
  });

  /// The person's city as they wrote it, '' when not set.
  final String city;
  final bool nearMe;
  final ValueChanged<bool> onChanged;
  final VoidCallback onSetCity;

  /// The phone's location is being used.
  final bool hasLocation;
  final VoidCallback? onUseLocation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasCity = city.trim().isNotEmpty;
    final label = hasLocation
        ? 'Near me · your area'
        : hasCity
        ? 'Near me · ${city.trim()}'
        : 'Near me';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ChoiceChip(
              key: const ValueKey('near_me_chip'),
              label: Text(label),
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
        if (!hasLocation && !hasCity)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tell us where you are to see looks from people near you. '
                  'Others only see that you are nearby.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Row(
                  children: [
                    if (onUseLocation != null)
                      TextButton.icon(
                        key: const ValueKey('use_location'),
                        onPressed: onUseLocation,
                        icon: const Icon(Icons.my_location, size: 18),
                        label: const Text('Use my location'),
                      ),
                    TextButton(
                      key: const ValueKey('add_city'),
                      onPressed: onSetCity,
                      child: const Text('Add city'),
                    ),
                  ],
                ),
              ],
            ),
          )
        else if (!hasLocation && onUseLocation != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('use_location'),
              onPressed: onUseLocation,
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text('Use my location instead'),
            ),
          ),
      ],
    );
  }
}
