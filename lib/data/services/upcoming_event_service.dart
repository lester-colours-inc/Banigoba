// Resolves the closest upcoming Plan Ahead event for dashboard context chips.
import 'package:cloud_firestore/cloud_firestore.dart';

class UpcomingEventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<UpcomingEvent?> watchClosestEvent(String userId) {
    if (userId.isEmpty) return Stream.value(null);

    return _db
        .collection('users')
        .doc(userId)
        .collection('eventPlans')
        .snapshots()
        .map((snapshot) => _closestEvent(snapshot.docs));
  }

  Future<UpcomingEvent?> getClosestEvent(String userId) async {
    if (userId.isEmpty) return null;

    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('eventPlans')
        .get();
    return _closestEvent(snapshot.docs);
  }

  UpcomingEvent? _closestEvent(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final today = _dateOnly(DateTime.now());
    final events =
        docs
            .map((doc) => UpcomingEvent.fromFirestore(doc.id, doc.data()))
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

  factory UpcomingEvent.fromFirestore(String id, Map<String, dynamic> data) {
    final start = data['startDate'];
    final end = data['endDate'];
    final startDate = start is Timestamp ? start.toDate() : DateTime.now();
    final endDate = end is Timestamp ? end.toDate() : startDate;

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
