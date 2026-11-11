// How long since a piece or a look was worn (October 2026 review, W-7):
// "You haven't worn this shirt in 10 months". Pure functions so the wording
// is the same everywhere and easy to test.
import 'package:banigoba/core/supabase/rows.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'wear_tracking.freezed.dart';

/// Not worn for this long (or never, once owned this long) is worth a nudge.
const Duration kNotWornNudgeAfter = Duration(days: 182);

/// A new item gets this long before "never worn" counts as a nudge.
const Duration kNewItemGrace = Duration(days: 30);

@freezed
abstract class WearStatus with _$WearStatus {
  const WearStatus._();

  const factory WearStatus(
    String label, {

    /// True when it has gone unworn long enough to point out.
    @Default(false) bool isNudge,
  }) = _WearStatus;
}

/// The label for something last worn on [lastWorn] (null if never), owned
/// since [addedAt] (null if unknown), as of [now].
WearStatus wearStatus({
  required DateTime? lastWorn,
  required DateTime? addedAt,
  required DateTime now,
}) {
  if (lastWorn == null) {
    final ownedLong =
        addedAt != null && now.difference(addedAt) >= kNewItemGrace;
    return WearStatus('Not worn yet', isNudge: ownedLong);
  }
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(lastWorn.year, lastWorn.month, lastWorn.day);
  final days = today.difference(day).inDays;
  if (days <= 0) return const WearStatus('Worn today');
  if (days == 1) return const WearStatus('Worn yesterday');
  final since = now.difference(lastWorn);
  final isNudge = since >= kNotWornNudgeAfter;
  if (days < 14) return WearStatus('Worn $days days ago');
  if (days < 60) return WearStatus('Worn ${days ~/ 7} weeks ago');
  final months = _monthsBetween(lastWorn, now);
  if (months < 12) {
    return isNudge
        ? WearStatus('Not worn in $months months', isNudge: true)
        : WearStatus('Worn $months months ago');
  }
  final years = months ~/ 12;
  return WearStatus(
    'Not worn in ${years == 1 ? 'a year' : '$years years'}',
    isNudge: true,
  );
}

int _monthsBetween(DateTime from, DateTime to) {
  var months = (to.year - from.year) * 12 + to.month - from.month;
  if (to.day < from.day) months -= 1;
  return months < 1 ? 1 : months;
}

/// The latest wear date per saved look, from wearHistory entries
/// ({outfitId, wearDate}).
Map<String, DateTime> lastWornByOutfit(
  Iterable<Map<String, dynamic>> wearHistory,
) {
  final latest = <String, DateTime>{};
  for (final entry in wearHistory) {
    final id = (entry['outfitId'] ?? '').toString();
    final worn = asDateTime(entry['wearDate']);
    if (id.isEmpty || worn == null) continue;
    if (latest[id] case final seen? when !worn.isAfter(seen)) continue;
    latest[id] = worn;
  }
  return Map.unmodifiable(latest);
}

DateTime? timestampToDate(Object? value) => asDateTime(value);
