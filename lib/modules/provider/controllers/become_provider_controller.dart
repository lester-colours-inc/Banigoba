// "Business mode" sign-up: which roles to open, the name and the place.
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/provider/models/provider_roles.dart';
import 'package:banigoba/modules/provider/services/provider_service.dart';

class BecomeProviderController extends GetxController {
  BecomeProviderController({
    this.held = const [],
    this.initialRoles = const [],
    this.suggestedName = '',
    ProviderService? service,
  }) : _service = service ?? ProviderService();

  final List<ProviderRole> held;
  final List<ProviderRole> initialRoles;
  final String suggestedName;
  final ProviderService _service;

  late final TextEditingController name = TextEditingController(
    text: suggestedName,
  );
  final TextEditingController location = TextEditingController();
  late final RxSet<ProviderRole> chosen = <ProviderRole>{
    for (final role in initialRoles)
      if (!held.contains(role)) role,
  }.obs;
  final RxBool saving = false.obs;
  final RxnString error = RxnString();

  @override
  void onClose() {
    name.dispose();
    location.dispose();
    super.onClose();
  }

  void toggleRole(ProviderRole role, {required bool on}) {
    if (on) {
      chosen.add(role);
    } else {
      chosen.remove(role);
    }
  }

  Future<void> start() async {
    if (chosen.isEmpty) {
      error.value = 'Tick at least one thing you offer.';
      return;
    }
    if (name.text.trim().isEmpty) {
      error.value = 'Enter your business name.';
      return;
    }
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      error.value = 'Sign in to use business mode.';
      return;
    }
    saving.value = true;
    error.value = null;
    try {
      await _service.become(
        userId: user.uid,
        held: held,
        added: chosen.toList(),
        businessName: name.text,
        location: location.text,
      );
      // The app's home follows the user document, so provider mode opens by
      // itself; this page only needs to get out of the way.
      if (!isClosed) Get.until((route) => route.isFirst);
    } on Exception catch (e) {
      if (!isClosed) error.value = 'Could not save: $e';
    } finally {
      if (!isClosed) saving.value = false;
    }
  }
}
