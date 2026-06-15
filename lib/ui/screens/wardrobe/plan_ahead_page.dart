// Provides planning shortcuts for future outfits and wardrobe activities.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/services/outfit_service.dart';
import 'trip_packer_page.dart';
import 'wardrobe_calendar_page.dart';

/// Hub for planning outfits in advance, including weekly planning and trip packing.
class PlanAheadPage extends StatefulWidget {
  const PlanAheadPage({super.key});

  static Color primaryColor = Color(0xFF0D0140);

  @override
  State<PlanAheadPage> createState() => _PlanAheadPageState();
}

class _PlanAheadPageState extends State<PlanAheadPage> {
  final OutfitService _outfitService = OutfitService();

  Future<void> _createEvent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final controller = TextEditingController();
    DateTimeRange? range;

    final result = await showDialog<_EventDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Event Series'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Event name',
                  hintText: 'Wedding weekend',
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final selected = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime(DateTime.now().year + 5, 12, 31),
                    initialDateRange: range,
                    helpText: 'Select event days',
                  );
                  if (selected != null) {
                    setDialogState(() => range = selected);
                  }
                },
                icon: const Icon(Icons.date_range),
                label: Text(
                  range == null
                      ? 'Choose event days'
                      : '${_shortDate(range!.start)} - ${_shortDate(range!.end)}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty || range == null) return;
                Navigator.pop(
                  dialogContext,
                  _EventDraft(name: name, range: range!),
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;

    final eventId = await _outfitService.createEventPlan(
      userId: user.uid,
      name: result.name,
      startDate: result.range.start,
      endDate: result.range.end,
    );
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WardrobeCalendarPage(
          planningMode: true,
          eventId: eventId,
          eventName: result.name,
          eventStart: result.range.start,
          eventEnd: result.range.end,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Plan Ahead',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Organize Your Style",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Prepare for your upcoming week, trips, and special events.",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 30),
            _buildPlanningCard(
              context,
              title: "Week Planner",
              subtitle: "Schedule your outfits for the next 7 days",
              icon: Icons.calendar_view_week,
              color: Colors.blue.shade400,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const WardrobeCalendarPage(planningMode: true),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            _buildPlanningCard(
              context,
              title: "Trip Packer",
              subtitle: "Create smart packing lists for your travels",
              icon: Icons.luggage,
              color: Colors.orange.shade400,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TripPackerPage()),
                );
              },
            ),
            SizedBox(height: 20),
            _buildPlanningCard(
              context,
              title: "Event Series",
              subtitle: "Coordinate looks for multi-day events",
              icon: Icons.event_available,
              color: Colors.pink.shade400,
              onTap: _createEvent,
            ),
            SizedBox(height: 40),
            Text(
              "Upcoming Plans",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),
            _buildUpcomingPlans(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingPlans(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _buildEmptyState(context);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _outfitService.watchEventPlans(user.uid),
      builder: (context, eventSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _outfitService.watchPackingLists(user.uid),
          builder: (context, packingSnapshot) {
            final plans = <_UpcomingPlan>[
              for (final doc in eventSnapshot.data?.docs ?? const [])
                _UpcomingPlan.event(doc.id, doc.data()),
              for (final doc in packingSnapshot.data?.docs ?? const [])
                _UpcomingPlan.packing(doc.id, doc.data()),
            ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            if (plans.isEmpty) return _buildEmptyState(context);
            return Column(
              children: [
                for (final plan in plans) ...[
                  _buildUpcomingPlanCard(context, plan),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUpcomingPlanCard(BuildContext context, _UpcomingPlan plan) {
    final color = plan.isEvent ? Colors.pink.shade400 : Colors.orange.shade400;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: plan.isEvent
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WardrobeCalendarPage(
                  planningMode: true,
                  eventId: plan.id,
                  eventName: plan.name,
                  eventStart: plan.startDate,
                  eventEnd: plan.endDate,
                ),
              ),
            )
          : () => _showPackingList(plan),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(
                plan.isEvent ? Icons.event_available : Icons.luggage,
                color: color,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Future<void> _showPackingList(_UpcomingPlan plan) async {
    final checked = <String>{};
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(plan.name),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final item in plan.items)
                  CheckboxListTile(
                    value: checked.contains(item),
                    title: Text(item),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (_) => setDialogState(() {
                      checked.contains(item)
                          ? checked.remove(item)
                          : checked.add(item);
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanningCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome, size: 50, color: Colors.orange.shade200),
          SizedBox(height: 20),
          Text(
            "No plans scheduled yet",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            "Start by scheduling your first outfit\nor creating a packing list.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  static String _shortDate(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';
}

class _EventDraft {
  const _EventDraft({required this.name, required this.range});

  final String name;
  final DateTimeRange range;
}

class _UpcomingPlan {
  const _UpcomingPlan({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.isEvent,
    required this.createdAt,
    this.startDate,
    this.endDate,
    this.items = const [],
  });

  factory _UpcomingPlan.event(String id, Map<String, dynamic> data) {
    final start = data['startDate'];
    final end = data['endDate'];
    final startDate = start is Timestamp ? start.toDate() : DateTime.now();
    final endDate = end is Timestamp ? end.toDate() : startDate;
    return _UpcomingPlan(
      id: id,
      name: (data['name'] ?? 'Event Series').toString(),
      subtitle:
          '${_PlanAheadPageState._shortDate(startDate)} - '
          '${_PlanAheadPageState._shortDate(endDate)}',
      isEvent: true,
      startDate: startDate,
      endDate: endDate,
      createdAt: _timestamp(data['createdAt']),
      items: const [],
    );
  }

  factory _UpcomingPlan.packing(String id, Map<String, dynamic> data) {
    final items = data['items'];
    final itemNames = items is Iterable
        ? items.map((item) => item.toString()).toList()
        : <String>[];
    return _UpcomingPlan(
      id: id,
      name: (data['name'] ?? 'Packing List').toString(),
      subtitle: '${itemNames.length} packing items',
      isEvent: false,
      createdAt: _timestamp(data['createdAt']),
      items: itemNames,
    );
  }

  final String id;
  final String name;
  final String subtitle;
  final bool isEvent;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> items;

  static DateTime _timestamp(dynamic value) =>
      value is Timestamp ? value.toDate() : DateTime(1970);
}
