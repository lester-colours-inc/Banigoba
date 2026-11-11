// One size row in the product form: the size label, how many, and the
// optional garment measurements for the fit check.
import 'package:flutter/widgets.dart';

import 'package:banigoba/modules/profile_details/models/body_profile.dart';
import 'package:banigoba/modules/wardrobe/models/fit_check.dart';

class SizeInventoryEntry {
  SizeInventoryEntry({
    required String size,
    required int quantity,
    Map<BodyMeasurement, double> measures = const {},
  }) : sizeController = TextEditingController(text: size),
       quantityController = TextEditingController(text: quantity.toString()),
       measureControllers = {
         for (final part in kChartParts)
           part: TextEditingController(
             text: measures[part] == null ? '' : formatNumber(measures[part]!),
           ),
       };

  final TextEditingController sizeController;
  final TextEditingController quantityController;

  /// The garment's measurements in this size, by body part (optional).
  final Map<BodyMeasurement, TextEditingController> measureControllers;

  void dispose() {
    sizeController.dispose();
    quantityController.dispose();
    for (final controller in measureControllers.values) {
      controller.dispose();
    }
  }
}
