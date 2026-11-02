// Verifies which events show as upcoming in the Community feed.
import 'package:banigoba/ui/screens/events/community_events_strip.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _event(String title, [DateTime? date]) => {
  'title': title,
  if (date != null) 'eventDateTime': date,
};

void main() {
  final now = DateTime(2026, 10, 14, 15);

  List<String> titles(List<Map<String, dynamic>> events) => upcomingEvents(
    events,
    now: now,
  ).map((e) => e['title'] as String).toList();

  test('shows today and later, soonest first, undated last', () {
    expect(
      titles([
        _event('Undated'),
        _event('Next month', DateTime(2026, 11, 1)),
        _event('This morning', DateTime(2026, 10, 14, 9)),
        _event('Friday', DateTime(2026, 10, 16)),
      ]),
      ['This morning', 'Friday', 'Next month', 'Undated'],
    );
  });

  test('leaves out events that are over', () {
    expect(titles([_event('Last week', DateTime(2026, 10, 7))]), isEmpty);
  });
}
