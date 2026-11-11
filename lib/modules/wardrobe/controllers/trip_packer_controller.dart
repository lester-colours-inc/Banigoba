// Trip packer: which saved outfits are ticked, and creating the packing list.
import 'dart:async';

import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/wardrobe/models/packing_outfit.dart';
import 'package:banigoba/modules/wardrobe/services/outfit_service.dart';
import 'package:banigoba/modules/wardrobe/widgets/trip_name_dialog.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class TripPackerController extends GetxController {
  TripPackerController({OutfitService? outfitService})
    : _outfitService = outfitService ?? OutfitService();

  final OutfitService _outfitService;

  /// Null until the first snapshot arrives.
  final Rxn<List<PackingOutfit>> outfits = Rxn<List<PackingOutfit>>();
  final RxSet<String> selectedIds = <String>{}.obs;
  final RxBool isSaving = false.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  bool get isSignedIn => AppAuth.instance.currentUser != null;

  @override
  void onInit() {
    super.onInit();
    final user = AppAuth.instance.currentUser;
    if (user == null) return;
    _subscription = _outfitService.watchSavedOutfits(user.uid).listen((docs) {
      outfits.value = docs
          .map((doc) => PackingOutfit(doc['id'].toString(), doc))
          .where((outfit) => outfit.itemNames.isNotEmpty)
          .toList();
    });
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  void toggle(String id) {
    if (!selectedIds.remove(id)) selectedIds.add(id);
  }

  Future<void> saveList() async {
    final user = AppAuth.instance.currentUser;
    if (user == null || selectedIds.isEmpty) return;
    final name = await askTripName();
    if (name == null || name.isEmpty || isClosed) return;

    final selected = (outfits.value ?? const <PackingOutfit>[])
        .where((outfit) => selectedIds.contains(outfit.id))
        .toList();
    final itemNames =
        selected
            .expand((outfit) => outfit.itemNames)
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    isSaving.value = true;
    try {
      await _outfitService.createPackingList(
        userId: user.uid,
        name: name,
        outfitIds: selected.map((outfit) => outfit.id).toList(),
        itemNames: itemNames,
      );
      if (isClosed) return;
      AppToast.say('$name packing list created.');
      Get.back<void>();
    } finally {
      if (!isClosed) isSaving.value = false;
    }
  }
}
