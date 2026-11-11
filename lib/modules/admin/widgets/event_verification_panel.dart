// The "Events" tab: events waiting for approval, and the live ones.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/admin/controllers/admin_events_controller.dart';
import 'package:banigoba/modules/events/services/event_service.dart';
import 'package:banigoba/modules/events/views/events_page.dart';

class EventVerificationPanel extends StatelessWidget {
  const EventVerificationPanel({super.key, required this.service});

  final EventService service;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Subheading('Pending Events'),
        const SizedBox(height: 10),
        _EventList(
          service: service,
          approved: false,
          errorText: 'Unable to load pending events.',
          emptyText: 'No events waiting for approval.',
        ),
        const SizedBox(height: 24),
        const _Subheading('Approved Events'),
        const SizedBox(height: 10),
        _EventList(
          service: service,
          approved: true,
          errorText: 'Unable to load approved events.',
          emptyText: 'No approved events are live.',
        ),
      ],
    );
  }
}

class _Subheading extends StatelessWidget {
  const _Subheading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
    );
  }
}

class _EventList extends StatelessWidget {
  const _EventList({
    required this.service,
    required this.approved,
    required this.errorText,
    required this.emptyText,
  });

  final EventService service;
  final bool approved;
  final String errorText;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdminEventsController>(
      init: AdminEventsController(approved: approved, service: service),
      global: false,
      builder: (controller) => Obx(() {
        if (controller.failed.value) {
          return Center(child: Text(errorText));
        }
        if (!controller.loaded.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final events = controller.events;
        if (events.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text(emptyText)),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final event = events[index];
            final eventId = event['id'].toString();
            return EventCard(
              data: event,
              adminActions: approved
                  ? _actions(
                      leftIcon: Icons.visibility_off_outlined,
                      leftLabel: 'Unpublish',
                      onLeft: () => service.disapproveEvent(eventId),
                      rightIcon: Icons.delete_outline,
                      rightLabel: 'Remove',
                      onRight: () => service.removeEvent(eventId),
                      rightColor: Colors.red,
                    )
                  : _actions(
                      leftIcon: Icons.close,
                      leftLabel: 'Disapprove',
                      onLeft: () => service.disapproveEvent(eventId),
                      rightIcon: Icons.check,
                      rightLabel: 'Approve',
                      onRight: () => service.approveEvent(eventId),
                      rightColor: const Color(0xFF0D0140),
                    ),
            );
          },
        );
      }),
    );
  }

  Widget _actions({
    required IconData leftIcon,
    required String leftLabel,
    required VoidCallback onLeft,
    required IconData rightIcon,
    required String rightLabel,
    required VoidCallback onRight,
    required Color rightColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onLeft,
            icon: Icon(leftIcon),
            label: Text(leftLabel),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: onRight,
            icon: Icon(rightIcon),
            label: Text(rightLabel),
            style: FilledButton.styleFrom(backgroundColor: rightColor),
          ),
        ),
      ],
    );
  }
}
