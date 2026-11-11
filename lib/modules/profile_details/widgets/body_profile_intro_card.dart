// The card at the top of My Profile Details: why, and how much is filled in.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/profile_details/models/body_profile.dart';

class BodyProfileIntroCard extends StatelessWidget {
  const BodyProfileIntroCard({super.key, required this.detailsAdded});

  final int detailsAdded;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const total = BodyProfile.requestedDetailCount;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'See clothes on you, at your real size',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your photos and sizes are used in the eFitting Room when you '
            'shop online, and for your Fashion Idol Twin.',
            style: TextStyle(color: colors.onPrimaryContainer, height: 1.35),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: detailsAdded / total,
                    minHeight: 8,
                    backgroundColor: colors.surface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$detailsAdded of $total added',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colors.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 16,
                color: colors.onPrimaryContainer,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Private to you. Never shown on your profile or posts.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onPrimaryContainer,
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
