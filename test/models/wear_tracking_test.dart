// Verifies "worn ... ago" / "not worn in ..." wording (W-7).
import 'package:banigoba/data/models/wear_tracking.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 10, 21, 15);

WearStatus _worn(DateTime? lastWorn, {DateTime? addedAt}) =>
    wearStatus(lastWorn: lastWorn, addedAt: addedAt, now: _now);

void main() {
  test('recent wear reads naturally and is not a nudge', () {
    expect(_worn(DateTime(2026, 10, 21, 8)).label, 'Worn today');
    expect(_worn(DateTime(2026, 10, 20, 22)).label, 'Worn yesterday');
    expect(_worn(DateTime(2026, 10, 16)).label, 'Worn 5 days ago');
    expect(_worn(DateTime(2026, 9, 30)).label, 'Worn 3 weeks ago');
    expect(_worn(DateTime(2026, 7, 21)).label, 'Worn 3 months ago');
    expect(_worn(DateTime(2026, 7, 21)).isNudge, isFalse);
  });

  test('six months or more unworn is a nudge', () {
    final status = _worn(DateTime(2025, 12, 20));
    expect(status.label, 'Not worn in 10 months');
    expect(status.isNudge, isTrue);
    expect(_worn(DateTime(2025, 10, 1)).label, 'Not worn in a year');
    expect(_worn(DateTime(2023, 10, 1)).label, 'Not worn in 3 years');
  });

  test('never worn is only a nudge once owned a month', () {
    expect(_worn(null, addedAt: DateTime(2026, 10, 10)).isNudge, isFalse);
    final old = _worn(null, addedAt: DateTime(2026, 8, 1));
    expect(old.label, 'Not worn yet');
    expect(old.isNudge, isTrue);
  });

  test('last wear per saved look takes the latest date', () {
    final latest = lastWornByOutfit([
      {'outfitId': 'a', 'wearDate': DateTime(2026, 5, 1)},
      {'outfitId': 'a', 'wearDate': DateTime(2026, 9, 1)},
      {'outfitId': 'b', 'wearDate': DateTime(2026, 1, 1)},
      {'outfitId': '', 'wearDate': DateTime(2026, 1, 1)},
    ]);
    expect(latest['a'], DateTime(2026, 9, 1));
    expect(latest['b'], DateTime(2026, 1, 1));
    expect(latest, hasLength(2));
  });
}
