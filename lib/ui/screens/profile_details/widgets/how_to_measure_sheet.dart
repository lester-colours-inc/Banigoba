// Short measuring tips, so the numbers people enter are ones a boutique and
// the eFitting Room can trust.
import 'package:flutter/material.dart';

import '../../../../data/models/body_profile.dart';

Future<void> showHowToMeasureSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _HowToMeasureSheet(),
  );
}

class _HowToMeasureSheet extends StatelessWidget {
  const _HowToMeasureSheet();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final measurements = BodyMeasurement.values.where(
      (measurement) => measurement != BodyMeasurement.weight,
    );

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Text(
              'How to measure',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Use a soft tape measure over light clothing. Keep it snug, '
              'not tight, and ask someone to help if you can.',
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 16),
            for (final measurement in measurements)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.straighten, size: 18, color: colors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${measurement.label}  ',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                            TextSpan(
                              text: measurement.howToMeasure,
                              style: TextStyle(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
