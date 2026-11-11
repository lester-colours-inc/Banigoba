// Wardrobe calendar: the selected day, wear history, and reusing saved outfits.
import 'dart:async';

import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/makeover/views/ai_upload_page.dart';
import 'package:banigoba/modules/wardrobe/models/calendar_dates.dart';
import 'package:banigoba/modules/wardrobe/models/saved_outfit.dart';
import 'package:banigoba/modules/wardrobe/services/outfit_service.dart';
import 'package:banigoba/modules/wardrobe/widgets/full_calendar_dialog.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class WardrobeCalendarController extends GetxController {
  WardrobeCalendarController({
    this.planningMode = false,
    this.eventId,
    this.eventName,
    this.eventStart,
    this.eventEnd,
    OutfitService? outfitService,
  }) : _outfitService = outfitService ?? OutfitService();

  final bool planningMode;
  final String? eventId;
  final String? eventName;
  final DateTime? eventStart;
  final DateTime? eventEnd;
  final OutfitService _outfitService;

  late final Rx<DateTime> selectedDate = dateOnly(
    eventStart ?? DateTime.now(),
  ).obs;
  final RxnString savingOutfitId = RxnString();

  /// Wear history keyed by day.
  final RxMap<String, Map<String, dynamic>> history =
      <String, Map<String, dynamic>>{}.obs;

  /// Null until the first snapshot; see [outfitsFailed].
  final Rxn<List<SavedOutfit>> outfits = Rxn<List<SavedOutfit>>();
  final RxBool outfitsFailed = false.obs;

  final List<StreamSubscription<Object?>> _subscriptions = [];

  String? get userId => AppAuth.instance.currentUser?.uid;

  List<DateTime> get selectedWeek {
    final date = selectedDate.value;
    final sunday = date.subtract(Duration(days: date.weekday % 7));
    return List.generate(7, (index) => sunday.add(Duration(days: index)));
  }

  bool isEventDay(DateTime value) {
    final start = eventStart;
    final end = eventEnd;
    if (start == null || end == null) return false;
    final date = dateOnly(value);
    return !date.isBefore(dateOnly(start)) && !date.isAfter(dateOnly(end));
  }

  void selectDate(DateTime date) => selectedDate.value = date;

  @override
  void onInit() {
    super.onInit();
    final id = userId;
    if (id == null) return;
    _subscriptions
      ..add(
        _outfitService.watchWearHistory(id).listen((docs) {
          history.assignAll({
            for (final doc in docs) doc['id'].toString(): doc,
          });
        }),
      )
      ..add(
        _outfitService.watchSavedOutfits(id).listen((docs) {
          outfitsFailed.value = false;
          outfits.value =
              docs.map((doc) => SavedOutfit(doc['id'].toString(), doc)).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }, onError: (_) => outfitsFailed.value = true),
      );
  }

  @override
  void onClose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.onClose();
  }

  Future<void> openFullCalendar([
    Map<String, Map<String, dynamic>>? known,
  ]) async {
    final picked = await pickCalendarDate(
      initialDate: selectedDate.value,
      firstDate: dateOnly(eventStart ?? DateTime(2020)),
      lastDate: dateOnly(eventEnd ?? DateTime(DateTime.now().year + 5, 12, 31)),
      historyKeys: (known ?? history).keys.toSet(),
    );
    if (picked == null || isClosed) return;
    selectedDate.value = dateOnly(picked);
  }

  Future<void> openFullCalendarForUser() async {
    final id = userId;
    if (id == null) return;
    try {
      final snapshot = await _outfitService.watchWearHistory(id).first;
      final fresh = <String, Map<String, dynamic>>{
        for (final doc in snapshot) doc['id'].toString(): doc,
      };
      if (isClosed) return;
      await openFullCalendar(fresh);
    } catch (error) {
      if (isClosed) return;
      AppToast.say('Unable to open calendar: $error');
    }
  }

  Future<void> reuseOutfit(SavedOutfit outfit) async {
    final id = userId;
    if (id == null) {
      AppToast.say('Please sign in first.');
      return;
    }

    savingOutfitId.value = outfit.id;
    try {
      await _outfitService.reuseOutfitOnDate(
        userId: id,
        outfitId: outfit.id,
        date: selectedDate.value,
        outfit: outfit.data,
        eventId: eventId,
        eventName: eventName,
      );
      if (isClosed) return;
      AppToast.say(
        '${outfit.name} added to ${formatCalendarDate(selectedDate.value)}.',
      );
    } catch (error) {
      if (isClosed) return;
      AppToast.say('Unable to reuse this outfit: $error');
    } finally {
      if (!isClosed) savingOutfitId.value = null;
    }
  }

  Future<void> createOutfitForSelectedDate() async {
    await Get.to<void>(
      () => AiUploadPage(
        plannedDate: selectedDate.value,
        eventId: eventId,
        eventName: eventName,
      ),
    );
  }
}
