// Event moderation: the pending list or the approved (live) list.
import 'dart:async';

import 'package:get/get.dart';

import 'package:banigoba/core/supabase/rows.dart';
import 'package:banigoba/modules/events/services/event_service.dart';

class AdminEventsController extends GetxController {
  AdminEventsController({required this.approved, required this.service});

  /// True for live events; false for the ones waiting for approval.
  final bool approved;
  final EventService service;

  final RxList<Map<String, dynamic>> events = <Map<String, dynamic>>[].obs;
  final RxBool loaded = false.obs;
  final RxBool failed = false.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void onInit() {
    super.onInit();
    final stream = approved
        ? service.watchApprovedManageableEvents()
        : service.watchPendingEvents();
    _sub = stream.listen((rows) {
      failed.value = false;
      events.assignAll(approved ? _live(rows) : _pending(rows));
      loaded.value = true;
    }, onError: (Object _) => failed.value = true);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  /// Newest submission first.
  static List<Map<String, dynamic>> _pending(List<Map<String, dynamic>> rows) {
    return rows.toList()..sort((a, b) {
      final aTime = asDateTime(a['submittedAt']);
      final bTime = asDateTime(b['submittedAt']);
      return (bTime?.millisecondsSinceEpoch ?? 0).compareTo(
        aTime?.millisecondsSinceEpoch ?? 0,
      );
    });
  }

  /// Upcoming only, soonest first.
  static List<Map<String, dynamic>> _live(List<Map<String, dynamic>> rows) {
    final now = DateTime.now();
    return rows.where((event) {
      final eventDate = asDateTime(event['eventDateTime']);
      return eventDate == null || eventDate.isAfter(now);
    }).toList()..sort((a, b) {
      final aTime = asDateTime(a['eventDateTime']);
      final bTime = asDateTime(b['eventDateTime']);
      return (aTime?.millisecondsSinceEpoch ?? 0).compareTo(
        bTime?.millisecondsSinceEpoch ?? 0,
      );
    });
  }
}
