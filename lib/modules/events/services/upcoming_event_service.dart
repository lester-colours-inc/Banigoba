// Resolves the closest upcoming Plan Ahead event for dashboard context chips.
import 'package:banigoba/core/supabase/rows.dart';
import 'package:banigoba/modules/wardrobe/services/outfit_service.dart';

class UpcomingEventService {
  final OutfitService _plans = OutfitService();

  Stream<UpcomingEvent?> watchClosestEvent(String userId) {
    if (userId.isEmpty) return Stream.value(null);
    return _plans.watchEventPlans(userId).map(_closestEvent);
  }

  Future<UpcomingEvent?> getClosestEvent(String userId) async {
    if (userId.isEmpty) return null;
    return _closestEvent(await _plans.watchEventPlans(userId).first);
  }

  UpcomingEvent? _closestEvent(List<Map<String, dynamic>> plans) {
    final today = _dateOnly(DateTime.now());
    final events =
        plans
            .map((plan) => UpcomingEvent.fromPlan(plan['id'].toString(), plan))
            .where((event) => !event.endDate.isBefore(today))
            .toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));

    return events.isEmpty ? null : events.first;
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

class UpcomingEvent {
  const UpcomingEvent({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;

  factory UpcomingEvent.fromPlan(String id, Map<String, dynamic> data) {
    final start = data['startDate'];
    final end = data['endDate'];
    final startDate = asDateTime(start) ?? DateTime.now();
    final endDate = asDateTime(end) ?? startDate;

    return UpcomingEvent(
      id: id,
      name: (data['name'] ?? 'Upcoming Event').toString(),
      startDate: DateTime(startDate.year, startDate.month, startDate.day),
      endDate: DateTime(endDate.year, endDate.month, endDate.day),
    );
  }

  String get shortLabel {
    final dateLabel = _sameDay(startDate, endDate)
        ? _shortDate(startDate)
        : '${_shortDate(startDate)}-${_shortDate(endDate)}';
    return '$dateLabel $name';
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _shortDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${value.day} ${months[value.month - 1]}';
  }
}
