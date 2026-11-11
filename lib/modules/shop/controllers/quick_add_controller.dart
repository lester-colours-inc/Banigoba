// State and saving for quick add: the draft, the photo, the AI suggestion.
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:banigoba/modules/shop/models/quick_add.dart';
import 'package:banigoba/modules/shop/services/quick_add_saver.dart';
import 'package:banigoba/modules/wardrobe/services/garment_tagger.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class QuickAddController extends GetxController {
  QuickAddController({
    QuickAddSaver? saver,
    PickPhoto? pickPhoto,
    GarmentTagger? tagger,
    required this.confirmAiUse,
  }) : _saver = saver ?? ProductQuickAddSaver(),
       _pick = pickPhoto ?? pickWithImagePicker,
       _tagger = tagger ?? ServerGarmentTagger();

  /// Asks before photos go to the AI (App Store 5.1.2).
  final Future<bool> Function() confirmAiUse;

  final QuickAddSaver _saver;
  final PickPhoto _pick;
  final GarmentTagger _tagger;

  final TextEditingController price = TextEditingController();
  final TextEditingController name = TextEditingController();
  final Rx<QuickAddDraft> draft = const QuickAddDraft().obs;
  final Rxn<Uint8List> photo = Rxn<Uint8List>();
  final RxBool saving = false.obs;
  final RxInt added = 0.obs;
  final RxBool suggested = false.obs;

  @override
  void onClose() {
    price.dispose();
    name.dispose();
    super.onClose();
  }

  // Edits read the live draft, not a copy captured by the last build.
  void setKind(QuickKind kind) =>
      draft.value = draft.value.copyWith(kind: kind);

  void adjustSize(String size, int delta) =>
      draft.value = draft.value.adjustSize(size, delta);

  void adjustQuantity(int delta) {
    final d = draft.value;
    final next = d.quantity + delta;
    draft.value = d.copyWith(quantity: next < 1 ? 1 : next);
  }

  void onPriceChanged(String value) {
    final d = draft.value;
    final parsed = parsePrice(value);
    draft.value = parsed == null
        ? QuickAddDraft(
            kind: d.kind,
            name: d.name,
            sizes: d.sizes,
            quantity: d.quantity,
            hasPhoto: d.hasPhoto,
          )
        : d.copyWith(price: parsed);
  }

  void onNameChanged(String value) =>
      draft.value = draft.value.copyWith(name: value);

  /// Takes the photo the user chose and asks the AI for suggestions.
  Future<void> choosePhotoFrom(ImageSource source) async {
    final bytes = await _pick(source);
    if (bytes == null || isClosed) return;
    photo.value = bytes;
    draft.value = draft.value.copyWith(hasPhoto: true);
    await _suggestFromPhoto(bytes);
  }

  /// Lets the AI pick the kind and a name from the photo, unless the trader
  /// has already chosen them. Never blocks adding the piece by hand.
  Future<void> _suggestFromPhoto(Uint8List bytes) async {
    if (!_tagger.isConfigured) return;
    if (!await confirmAiUse() || isClosed) return;
    final tags = await _tagger.tag(bytes);
    if (tags == null || isClosed || photo.value != bytes) return;
    final kind = tags.category == null
        ? null
        : QuickKind.values
              .where((k) => k.category == tags.category)
              .firstOrNull;
    var next = draft.value;
    if (kind != null && next.kind == QuickKind.tops && next.sizes.isEmpty) {
      next = next.copyWith(kind: kind);
    }
    if (name.text.trim().isEmpty && tags.name.isNotEmpty) {
      name.text = tags.name;
      next = next.copyWith(name: tags.name);
    }
    draft.value = next;
    suggested.value = true;
  }

  Future<void> save() async {
    final problem = draft.value.problem;
    final bytes = photo.value;
    if (problem != null || bytes == null || saving.value) {
      if (problem != null) AppToast.say(problem);
      return;
    }
    saving.value = true;
    try {
      await _saver.save(draft.value, bytes);
      if (isClosed) return;
      price.clear();
      name.clear();
      added.value += 1;
      photo.value = null;
      suggested.value = false;
      // Ready for the next piece of the same kind.
      draft.value = QuickAddDraft(kind: draft.value.kind);
      AppToast.say('Added. Add the next one, or go back when you are done.');
    } on Exception catch (error) {
      if (!isClosed) AppToast.say('Could not add it: $error');
    } finally {
      if (!isClosed) saving.value = false;
    }
  }
}
