import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/provider/models/portfolio_piece.dart';
import 'package:banigoba/modules/wardrobe/models/piece_details.dart';

/// Owns the controllers for one portfolio piece being edited: the picture
/// link, size, and the same measurement/fabric/origin fields a boutique
/// stock item has.
class PortfolioPieceEntry {
  PortfolioPieceEntry({required PortfolioPiece piece})
    : imageUrlController = TextEditingController(text: piece.imageUrl),
      sizeController = TextEditingController(text: piece.size),
      shoulderController = TextEditingController(
        text: piece.details.shoulderMeasurement,
      ),
      heightController = TextEditingController(
        text: piece.details.heightMeasurement,
      ),
      linenTypeController = TextEditingController(
        text: piece.details.linenType,
      ),
      madeWhereController = TextEditingController(
        text: piece.details.madeWhere,
      ),
      otherDetailControllers = <TextEditingController>[
        for (final detail in piece.details.otherDetails)
          TextEditingController(text: detail),
      ].obs;

  final TextEditingController imageUrlController;
  final TextEditingController sizeController;
  final TextEditingController shoulderController;
  final TextEditingController heightController;
  final TextEditingController linenTypeController;
  final TextEditingController madeWhereController;
  final RxList<TextEditingController> otherDetailControllers;

  /// Bumped when the picture link or size is typed, so the card's title
  /// follows.
  final RxInt revision = 0.obs;

  void touch() => revision.value++;

  void addDetail() => otherDetailControllers.add(TextEditingController());

  void removeDetail(int index) =>
      otherDetailControllers.removeAt(index).dispose();

  PortfolioPiece toPiece() => PortfolioPiece(
    imageUrl: imageUrlController.text.trim(),
    size: sizeController.text.trim(),
    details: PieceDetails.fromControllerText(
      shoulderMeasurement: shoulderController.text,
      heightMeasurement: heightController.text,
      linenType: linenTypeController.text,
      madeWhere: madeWhereController.text,
      otherDetails: otherDetailControllers.map((controller) => controller.text),
    ),
  );

  void dispose() {
    imageUrlController.dispose();
    sizeController.dispose();
    shoulderController.dispose();
    heightController.dispose();
    linenTypeController.dispose();
    madeWhereController.dispose();
    for (final controller in otherDetailControllers) {
      controller.dispose();
    }
  }
}
