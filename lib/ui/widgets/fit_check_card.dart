// "Fit check" on a product page (review item K-2): how this item will fit
// you, from the shop's size chart and your saved measurements. Always shown
// as an estimate with the numbers behind it.
import 'package:flutter/material.dart';

import '../../data/models/body_profile.dart';
import '../../data/models/fit_check.dart';

class FitCheckCard extends StatelessWidget {
  const FitCheckCard({
    super.key,
    required this.chart,
    required this.body,
    required this.selectedSize,
    required this.availableSizes,
    required this.onChooseSize,
    required this.onAddMeasurements,
  });

  final SizeChart chart;
  final BodyProfile body;

  /// The size picked on the product page, or '' when none.
  final String selectedSize;

  /// Sizes in stock, used to offer the recommended one only if it is there.
  final List<String> availableSizes;
  final ValueChanged<String> onChooseSize;
  final VoidCallback onAddMeasurements;

  static const Color _warn = Color(0xFFD9822B);
  static const Color _ok = Color(0xFF2E8B57);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final check = FitCheck.of(chart, body, selectedSize: selectedSize);
    final hasMeasurements = body.measurements.isNotEmpty;

    return Container(
      key: const ValueKey('fit_check_card'),
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.straighten, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Fit check',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'Estimate',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._content(context, check, hasMeasurements),
        ],
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    FitCheck check,
    bool hasMeasurements,
  ) {
    final colors = Theme.of(context).colorScheme;
    final muted = TextStyle(color: colors.onSurfaceVariant, height: 1.35);

    if (chart.isEmpty) {
      final advice = sizeLabelAdvice(selectedSize, body.clothingSize);
      return [
        Text(
          advice ??
              "This shop hasn't added garment measurements, so we can't say "
                  'exactly how it fits. Check the size you usually wear.',
          key: const ValueKey('fit_no_chart'),
          style: muted,
        ),
      ];
    }
    if (!hasMeasurements) {
      return [
        Text(
          'Add your measurements to see where this will be tight or loose '
          'on you.',
          style: muted,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const ValueKey('fit_add_measurements'),
          onPressed: onAddMeasurements,
          icon: const Icon(Icons.add),
          label: const Text('Add my measurements'),
        ),
      ];
    }
    if (!check.hasResult) {
      return [
        Text(
          selectedSize.isEmpty
              ? 'Choose a size to see how it fits you.'
              : "The shop hasn't measured size $selectedSize, or your "
                    "measurements don't cover the same parts.",
          style: muted,
        ),
        ..._recommendation(check),
      ];
    }
    final good = check.isComfortable;
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            good ? Icons.check_circle : Icons.warning_amber_rounded,
            color: good ? _ok : _warn,
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              check.size.isEmpty
                  ? check.headline
                  : 'Size ${check.size}: ${check.headline.toLowerCase()}',
              key: const ValueKey('fit_headline'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      for (final part in check.parts)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text('• ${part.numbers}, so ${part.phrase}', style: muted),
        ),
      ..._recommendation(check),
    ];
  }

  List<Widget> _recommendation(FitCheck check) {
    final best = check.recommendedSize;
    if (best == null || best == selectedSize.trim().toUpperCase()) {
      return const [];
    }
    final inStock = availableSizes.any(
      (size) => size.trim().toUpperCase() == best,
    );
    return [
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(
            child: Text(
              inStock
                  ? 'Best size for you: $best'
                  : 'Best size for you would be $best, but it is out of stock.',
              key: const ValueKey('fit_recommendation'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (inStock)
            TextButton(
              key: const ValueKey('fit_choose_best'),
              onPressed: () => onChooseSize(best),
              child: Text('Choose $best'),
            ),
        ],
      ),
    ];
  }
}
