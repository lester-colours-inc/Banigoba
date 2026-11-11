// Small read-only rows used on the product detail screen.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/wardrobe/models/piece_details.dart';

/// A bold "Label: value" line; nothing when the value is empty.
class ProductDetailRow extends StatelessWidget {
  const ProductDetailRow(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    final shown = value[0].toUpperCase() + value.substring(1);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(child: Text(shown, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

/// A "Weather Tags:" style heading over a wrap of chips.
class ProductTagsRow extends StatelessWidget {
  const ProductTagsRow(this.label, this.tags, {super.key});

  final String label;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label Tags:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 8,
            children: [
              for (final tag in tags)
                Chip(
                  label: Text(tag[0].toUpperCase() + tag.substring(1)),
                  backgroundColor: const Color(
                    0xFF0D0140,
                  ).withValues(alpha: 0.1),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0D0140),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The seller's measurement, fabric, origin and extra-detail fields, each
/// only shown when the seller actually filled it in.
class ProductPieceDetails extends StatelessWidget {
  const ProductPieceDetails(this.details, {super.key});

  final PieceDetails details;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (details.shoulderMeasurement.isNotEmpty)
          ProductDetailRow(
            'Shoulder Measurement',
            '${details.shoulderMeasurement} cm',
          ),
        if (details.heightMeasurement.isNotEmpty)
          ProductDetailRow(
            'Height Measurement',
            '${details.heightMeasurement} cm',
          ),
        if (details.linenType.isNotEmpty)
          ProductDetailRow('Linen Type', details.linenType),
        if (details.madeWhere.isNotEmpty)
          ProductDetailRow('Made Where', details.madeWhere),
        if (details.otherDetails.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Other Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 5),
                for (final detail in details.otherDetails)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('• $detail'),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
