// The Customer / Business switch at the top of the menu.
import 'dart:async';

import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/provider/models/provider_roles.dart';
import 'package:banigoba/modules/provider/services/provider_service.dart';
import 'package:banigoba/modules/provider/views/become_provider_page.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';

class ProviderModeSwitchController extends GetxController {
  final String? userId = AppAuth.instance.currentUser?.uid;

  /// The user's profile; null until it loads.
  final Rxn<Map<String, dynamic>> profile = Rxn<Map<String, dynamic>>();

  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  void onInit() {
    super.onInit();
    final id = userId;
    if (id == null) return;
    _sub = ProfileService().watch(id).listen((data) => profile.value = data);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  List<ProviderRole> get roles => providerRolesOf(profile.value ?? const {});

  /// Closes the menu and opens the sign-up.
  void becomeProvider() {
    final suggested = (profile.value?['displayName'] ?? '').toString();
    Get.back<void>();
    Get.to<void>(() => BecomeProviderPage(suggestedName: suggested));
  }

  void switchToBusiness() {
    final id = userId;
    if (id != null) ProviderService().setMode(id, provider: true);
  }
}
