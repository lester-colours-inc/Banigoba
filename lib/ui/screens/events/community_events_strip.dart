// Upcoming events at the top of the Community feed, with a way to add one,
// e.g. to announce a fashion show (October 2026 review, C-1 and C-2).
// Tapping an event opens its full card; "See all" opens the Events page.
import '../../../data/supabase/rows.dart';
import 'package:flutter/material.dart';

import '../../../data/services/event_service.dart';
import '../../widgets/app_network_image.dart';
import 'events_page.dart';

/// Approved events that have not happened yet, soonest first. Events with no
/// date go last.
List<Map<String, dynamic>> upcomingEvents(
  Iterable<Map<String, dynamic>> events, {
  required DateTime now,
}) {
  DateTime? dateOf(Map<String, dynamic> event) =>
      asDateTime(event['eventDateTime']);
  final today = DateTime(now.year, now.month, now.day);
  final upcoming =
      events.where((event) {
        final date = dateOf(event);
        return date == null || !date.isBefore(today);
      }).toList()..sort((a, b) {
        final aDate = dateOf(a);
        final bDate = dateOf(b);
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });
  return List.unmodifiable(upcoming);
}

class CommunityEventsStrip extends StatefulWidget {
  const CommunityEventsStrip({super.key});

  @override
  State<CommunityEventsStrip> createState() => _CommunityEventsStripState();
}

class _CommunityEventsStripState extends State<CommunityEventsStrip> {
  late final Stream<List<Map<String, dynamic>>> _events = EventService()
      .watchApprovedEvents();

  void _addEvent() => Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => const EventSubmissionPage()),
  );

  void _seeAll() => Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => const EventsSection()),
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _events,
      builder: (context, snapshot) {
        final events = snapshot.hasData
            ? upcomingEvents(snapshot.data!, now: DateTime.now())
            : const <Map<String, dynamic>>[];
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Upcoming events',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (events.isNotEmpty)
                    TextButton(
                      onPressed: _seeAll,
                      child: const Text('See all'),
                    ),
                  FilledButton.tonalIcon(
                    key: const ValueKey('community_add_event'),
                    onPressed: _addEvent,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add event'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (events.isEmpty)
                Text(
                  'No events yet. Hosting a fashion show? Add it here.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              else
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: events.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) =>
                        _EventTile(event: events[index]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = (event['title'] ?? 'Event').toString();
    final flyerUrl = (event['flyerUrl'] ?? '').toString();
    final date = asDateTime(event['eventDateTime']);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(title)),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: EventCard(data: event),
            ),
          ),
        ),
      ),
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColoredBox(
                  color: colors.surfaceContainerHigh,
                  child: flyerUrl.isEmpty
                      ? const Center(child: Icon(Icons.event_outlined))
                      : AppNetworkImage(
                          flyerUrl,
                          width: 160,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (date != null)
              Text(
                '${date.day}/${date.month}/${date.year}',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
