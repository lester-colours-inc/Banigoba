// The curators' workspace: who is allowed in, the chosen tab, and logout.
import 'dart:async';

import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/auth/services/auth_service.dart';
import 'package:banigoba/modules/events/services/event_service.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class CuratorsWorkspaceController extends GetxController {
  final String? userId = AppAuth.instance.currentUser?.uid;
  final EventService events = EventService();

  /// The signed-in user's profile; null until it loads.
  final Rxn<Map<String, dynamic>> profile = Rxn<Map<String, dynamic>>();
  final RxInt tab = 0.obs;

  StreamSubscription<Map<String, dynamic>>? _sub;
  bool _cleaned = false;

  bool get isAdmin {
    final data = profile.value;
    return data != null && (data['isAdmin'] == true || data['role'] == 'admin');
  }

  @override
  void onInit() {
    super.onInit();
    final id = userId;
    if (id == null) return;
    _sub = ProfileService().watch(id).listen((data) {
      profile.value = data;
      // Expired events are cleared once, when an admin opens the workspace.
      if (!_cleaned && isAdmin) {
        _cleaned = true;
        events.removeExpiredEvents();
      }
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void selectTab(int index) => tab.value = index;

  Future<void> signOut() async {
    try {
      await AuthService().signOut();
    } catch (_) {
      if (!isClosed) AppToast.say('Could not log out. Please try again.');
    }
  }
}
