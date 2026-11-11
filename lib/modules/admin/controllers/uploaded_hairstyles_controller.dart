// The catalogue hairstyles already uploaded, newest first.
import 'dart:async';

import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/core/supabase/rows.dart';
import 'package:banigoba/modules/makeover/services/hairstyle_service.dart';

class UploadedHairstylesController extends GetxController {
  UploadedHairstylesController({required this.curatorMode});

  /// Curators see everyone's uploads; others only their own.
  final bool curatorMode;

  final String userId = AppAuth.instance.currentUser?.uid ?? '';
  final RxList<Map<String, dynamic>> docs = <Map<String, dynamic>>[].obs;
  final RxBool loaded = false.obs;
  final RxnString error = RxnString();

  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void onInit() {
    super.onInit();
    if (userId.isEmpty) return;
    _sub = HairstyleService()
        .watchCatalog(uploaderId: curatorMode ? null : userId)
        .listen((rows) {
          error.value = null;
          docs.assignAll(
            rows.toList()..sort((a, b) {
              final aDate =
                  asDateTime(a['createdAt']) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final bDate =
                  asDateTime(b['createdAt']) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return bDate.compareTo(aDate);
            }),
          );
          loaded.value = true;
        }, onError: (Object e) => error.value = e.toString());
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
