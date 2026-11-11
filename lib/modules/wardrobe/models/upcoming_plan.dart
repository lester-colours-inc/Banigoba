// What the Plan Ahead hub lists: event series and packing lists.
import 'package:flutter/material.dart' show DateTimeRange;

import 'package:banigoba/core/supabase/rows.dart';

String shortDate(DateTime value) => '${value.day}/${value.month}/${value.year}';

class EventDraft {
  const EventDraft({required this.name, required this.range});

  final String name;
  final DateTimeRange range;
}

/// A planned event series or a packing list, as the Plan Ahead hub lists it.
class UpcomingPlan {
  const UpcomingPlan({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.isEvent,
    required this.createdAt,
    this.startDate,
    this.endDate,
    this.packingItems = const [],
  });

  factory UpcomingPlan.event(String id, Map<String, dynamic> data) {
    final start = data['startDate'];
    final end = data['endDate'];
    final startDate = asDateTime(start) ?? DateTime.now();
    final endDate = asDateTime(end) ?? startDate;
    return UpcomingPlan(
      id: id,
      name: (data['name'] ?? 'Event Series').toString(),
      subtitle:
          '${shortDate(startDate)} - '
          '${shortDate(endDate)}',
      isEvent: true,
      startDate: startDate,
      endDate: endDate,
      createdAt: _stamp(data['createdAt']),
      packingItems: const [],
    );
  }

  factory UpcomingPlan.packing(String id, Map<String, dynamic> data) {
    final items = data['items'];
    final checkedItems = data['checkedItems'] is Iterable
        ? (data['checkedItems'] as Iterable)
              .map((item) => item.toString())
              .toSet()
        : <String>{};
    final packingItems = items is Iterable
        ? items
              .map((item) {
                if (item is Map) {
                  final name = (item['name'] ?? '').toString();
                  return {'name': name, 'packed': item['packed'] == true};
                }
                final name = item.toString();
                return {'name': name, 'packed': checkedItems.contains(name)};
              })
              .where((item) => (item['name'] as String).isNotEmpty)
              .toList()
        : <Map<String, dynamic>>[];
    final packedCount = packingItems
        .where((item) => item['packed'] == true)
        .length;
    return UpcomingPlan(
      id: id,
      name: (data['name'] ?? 'Packing List').toString(),
      subtitle: '$packedCount/${packingItems.length} packed',
      isEvent: false,
      createdAt: _stamp(data['createdAt']),
      packingItems: packingItems,
    );
  }

  final String id;
  final String name;
  final String subtitle;
  final bool isEvent;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<Map<String, dynamic>> packingItems;

  static DateTime _stamp(dynamic value) => asDateTime(value) ?? DateTime(1970);
}
