// The "Delivery" card in My Shop: the fields, validation and saving.
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/shop/models/delivery.dart';

class DeliverySettingsController extends GetxController {
  DeliverySettingsController({required this.initial, required this.onSave});

  final DeliverySettings initial;
  final Future<void> Function(DeliverySettings settings) onSave;

  late final RxBool delivers = initial.delivers.obs;
  late final TextEditingController fee = TextEditingController(
    text: initial.delivers || initial.fee > 0
        ? initial.fee.toStringAsFixed(2)
        : '',
  );
  late final TextEditingController areas = TextEditingController(
    text: initial.areas.join(', '),
  );
  late final TextEditingController note = TextEditingController(
    text: initial.note,
  );
  final RxBool saving = false.obs;
  final RxnString error = RxnString();
  final RxBool saved = false.obs;

  @override
  void onClose() {
    fee.dispose();
    areas.dispose();
    note.dispose();
    super.onClose();
  }

  void setDelivers(bool on) {
    delivers.value = on;
    saved.value = false;
  }

  Future<void> save() async {
    final feeText = fee.text.trim().replaceAll(',', '.');
    final feeValue = feeText.isEmpty ? 0.0 : double.tryParse(feeText);
    if (delivers.value && (feeValue == null || feeValue < 0)) {
      error.value = 'Enter the fee as a number, like 2.50.';
      return;
    }
    saving.value = true;
    error.value = null;
    saved.value = false;
    try {
      await onSave(
        DeliverySettings.cleaned(
          delivers: delivers.value,
          fee: feeValue ?? 0,
          areas: areas.text.split(','),
          note: note.text,
        ),
      );
      if (!isClosed) saved.value = true;
    } on Exception catch (e) {
      if (!isClosed) error.value = 'Could not save: $e';
    } finally {
      if (!isClosed) saving.value = false;
    }
  }
}
