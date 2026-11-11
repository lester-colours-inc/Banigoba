// One portfolio piece's fields, collapsed to its picture and size until the
// designer expands it.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/designers/models/portfolio_piece_entry.dart';
import 'package:banigoba/modules/wardrobe/widgets/piece_extra_details_fields.dart';

class PieceEditorCard extends StatelessWidget {
  const PieceEditorCard({
    super.key,
    required this.entry,
    required this.onRemove,
  });

  final PortfolioPieceEntry entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = entry.revision.value;
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ExpansionTile(
          title: Text(
            entry.imageUrlController.text.isEmpty
                ? 'New piece'
                : (entry.sizeController.text.isEmpty
                      ? 'Piece'
                      : 'Size ${entry.sizeController.text}'),
          ),
          trailing: IconButton(
            tooltip: 'Remove piece',
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            TextField(
              controller: entry.imageUrlController,
              onChanged: (_) => entry.touch(),
              decoration: const InputDecoration(
                labelText: 'Picture link',
                hintText: 'Paste an image URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: entry.sizeController,
              onChanged: (_) => entry.touch(),
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Size',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            buildPieceExtraDetailsFields(
              context,
              shoulderController: entry.shoulderController,
              heightController: entry.heightController,
              linenTypeController: entry.linenTypeController,
              madeWhereController: entry.madeWhereController,
              otherDetailControllers: entry.otherDetailControllers,
              onAddDetail: entry.addDetail,
              onRemoveDetail: entry.removeDetail,
            ),
          ],
        ),
      );
    });
  }
}
