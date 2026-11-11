// Business mode's home: the roles the user holds and what is waiting.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/provider/models/provider_inbox.dart';
import 'package:banigoba/modules/provider/models/provider_roles.dart';
import 'package:banigoba/modules/provider/services/provider_inbox_service.dart';
import 'package:banigoba/modules/provider/services/provider_service.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';

class ProviderHomeController extends GetxController {
  final String? userId = AppAuth.instance.currentUser?.uid;

  final RxList<ProviderRole> roles = <ProviderRole>[].obs;
  final RxString name = ''.obs;

  /// Orders and requests waiting for an answer.
  final RxInt waiting = 0.obs;

  StreamSubscription<Map<String, dynamic>>? _profileSub;
  StreamSubscription<List<InboxItem>>? _inboxSub;

  @override
  void onInit() {
    super.onInit();
    final id = userId;
    if (id == null) return;
    _profileSub = ProfileService().watch(id).listen((data) {
      final next = providerRolesOf(data);
      name.value = (data['displayName'] ?? '').toString();
      final changed = !listEquals(roles.toList(), next);
      roles.assignAll(next);
      if (changed || _inboxSub == null) _watchInbox(id, next);
    });
  }

  void _watchInbox(String id, List<ProviderRole> held) {
    _inboxSub?.cancel();
    _inboxSub = ProviderInboxService()
        .watch(id, held)
        .listen((items) => waiting.value = openCount(items));
  }

  @override
  void onClose() {
    _profileSub?.cancel();
    _inboxSub?.cancel();
    super.onClose();
  }

  Future<void> switchToCustomer() async {
    final id = userId;
    if (id == null) return;
    await ProviderService().setMode(id, provider: false);
  }
}
