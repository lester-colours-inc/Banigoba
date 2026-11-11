// Plan Ahead hub: upcoming plans, creating event series, packing checklists.
import 'dart:async';

import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/wardrobe/bindings/trip_packer_binding.dart';
import 'package:banigoba/modules/wardrobe/models/upcoming_plan.dart';
import 'package:banigoba/modules/wardrobe/services/outfit_service.dart';
import 'package:banigoba/modules/wardrobe/views/trip_packer_page.dart';
import 'package:banigoba/modules/wardrobe/views/wardrobe_calendar_page.dart';
import 'package:banigoba/modules/wardrobe/widgets/event_series_dialog.dart';
import 'package:banigoba/modules/wardrobe/widgets/packing_list_dialog.dart';

class PlanAheadController extends GetxController {
  PlanAheadController({OutfitService? outfitService})
    : _outfitService = outfitService ?? OutfitService();

  final OutfitService _outfitService;

  final RxList<Map<String, dynamic>> _events = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _packingLists =
      <Map<String, dynamic>>[].obs;

  final List<StreamSubscription<List<Map<String, dynamic>>>> _subscriptions =
      [];

  /// Events and packing lists together, newest first.
  List<UpcomingPlan> get plans => <UpcomingPlan>[
    for (final doc in _events) UpcomingPlan.event(doc['id'].toString(), doc),
    for (final doc in _packingLists)
      UpcomingPlan.packing(doc['id'].toString(), doc),
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  void onInit() {
    super.onInit();
    final user = AppAuth.instance.currentUser;
    if (user == null) return;
    _subscriptions
      ..add(_outfitService.watchEventPlans(user.uid).listen(_events.assignAll))
      ..add(
        _outfitService
            .watchPackingLists(user.uid)
            .listen(_packingLists.assignAll),
      );
  }

  @override
  void onClose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.onClose();
  }

  void openWeekPlanner() =>
      Get.to<void>(() => const WardrobeCalendarPage(planningMode: true));

  void openTripPacker() =>
      Get.to<void>(() => const TripPackerPage(), binding: TripPackerBinding());

  Future<void> createEvent() async {
    final user = AppAuth.instance.currentUser;
    if (user == null) return;
    final result = await askEventSeries();
    if (result == null || isClosed) return;

    final eventId = await _outfitService.createEventPlan(
      userId: user.uid,
      name: result.name,
      startDate: result.range.start,
      endDate: result.range.end,
    );
    if (isClosed) return;
    await Get.to<void>(
      () => WardrobeCalendarPage(
        planningMode: true,
        eventId: eventId,
        eventName: result.name,
        eventStart: result.range.start,
        eventEnd: result.range.end,
      ),
    );
  }

  void openPlan(UpcomingPlan plan) {
    if (plan.isEvent) {
      Get.to<void>(
        () => WardrobeCalendarPage(
          planningMode: true,
          eventId: plan.id,
          eventName: plan.name,
          eventStart: plan.startDate,
          eventEnd: plan.endDate,
        ),
      );
    } else {
      _showPackingList(plan);
    }
  }

  Future<void> _showPackingList(UpcomingPlan plan) async {
    final user = AppAuth.instance.currentUser;
    if (user == null) return;
    await showPackingList(
      plan: plan,
      onChanged: (items) => _outfitService.updatePackingItemPacked(
        userId: user.uid,
        packingListId: plan.id,
        items: items,
      ),
    );
  }
}
