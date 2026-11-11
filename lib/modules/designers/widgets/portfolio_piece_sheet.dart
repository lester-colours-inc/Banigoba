import 'package:flutter/material.dart';

import 'package:banigoba/modules/provider/models/portfolio_piece.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

/// Shows one portfolio piece full-size with the detail a customer needs to
/// judge fit and fabric, the same way a boutique's product page does.
class PortfolioPieceSheet extends StatelessWidget {
  const PortfolioPieceSheet({super.key, required this.piece});

  final PortfolioPiece piece;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final details = piece.details;
    final rows = <MapEntry<String, String>>[
      if (piece.size.isNotEmpty) MapEntry('Size', piece.size),
      if (details.shoulderMeasurement.isNotEmpty)
        MapEntry('Shoulder Measurement', '${details.shoulderMeasurement} cm'),
      if (details.heightMeasurement.isNotEmpty)
        MapEntry('Height Measurement', '${details.heightMeasurement} cm'),
      if (details.linenType.isNotEmpty)
        MapEntry('Linen Type', details.linenType),
      if (details.madeWhere.isNotEmpty)
        MapEntry('Made Where', details.madeWhere),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (piece.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AppNetworkImage(piece.imageUrl, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 16),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 150,
                      child: Text(
                        row.key,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(child: Text(row.value)),
                  ],
                ),
              ),
            if (details.otherDetails.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Other Details',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              for (final detail in details.otherDetails)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('• $detail'),
                ),
            ],
            if (rows.isEmpty && details.otherDetails.isEmpty)
              Text(
                'No extra details were added for this piece.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}
