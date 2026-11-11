// Shared fields for describing one piece of clothing beyond its picture and
// size: shoulder and height measurements, fabric, where it was made, and any
// other useful detail the seller or designer wants to add.
//
// Used by the boutique stock form (AdminProductsPage) and the designer
// portfolio editor (FashionDesignersPage), so a customer sees the same kind
// of detail whichever surface a piece came from.
import 'package:flutter/material.dart';

/// The measurement, fabric and origin fields, plus a free-form "Other useful
/// details" list the seller can grow with the add button.
///
/// [otherDetailControllers] is owned by the caller (it decides how the list
/// grows and shrinks) so this stays a plain, stateless section that fits
/// inside either form.
Widget buildPieceExtraDetailsFields(
  BuildContext context, {
  required TextEditingController shoulderController,
  required TextEditingController heightController,
  required TextEditingController linenTypeController,
  required TextEditingController madeWhereController,
  required List<TextEditingController> otherDetailControllers,
  required VoidCallback onAddDetail,
  required ValueChanged<int> onRemoveDetail,
}) {
  final colors = Theme.of(context).colorScheme;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: shoulderController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Shoulder Measurement',
                suffixText: 'cm',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: heightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Height Measurement',
                suffixText: 'cm',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 15),
      TextField(
        controller: linenTypeController,
        decoration: const InputDecoration(
          labelText: 'Linen Type',
          hintText: 'e.g. Pure linen, linen blend',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 15),
      TextField(
        controller: madeWhereController,
        decoration: const InputDecoration(
          labelText: 'Made Where',
          hintText: 'e.g. Harare, Zimbabwe',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 15),
      Row(
        children: [
          const Expanded(
            child: Text(
              'Other Useful Details',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton.icon(
            onPressed: onAddDetail,
            icon: const Icon(Icons.add),
            label: const Text('Add Detail'),
          ),
        ],
      ),
      if (otherDetailControllers.isEmpty)
        Text(
          'Anything else a customer should know, e.g. care instructions or '
          'a design story.',
          style: TextStyle(color: colors.onSurfaceVariant),
        )
      else
        for (int index = 0; index < otherDetailControllers.length; index += 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: otherDetailControllers[index],
                    decoration: const InputDecoration(
                      labelText: 'Detail',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove detail',
                  onPressed: () => onRemoveDetail(index),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
    ],
  );
}
