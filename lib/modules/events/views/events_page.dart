import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/core/supabase/rows.dart';
import 'package:banigoba/modules/events/controllers/approved_events_controller.dart';
import 'package:banigoba/modules/events/controllers/event_submission_controller.dart';
import 'package:banigoba/modules/events/services/event_service.dart';
import 'package:banigoba/modules/events/widgets/event_card.dart';
import 'package:banigoba/modules/events/widgets/event_submission_widgets.dart';

export 'package:banigoba/modules/events/widgets/event_card.dart' show EventCard;

class EventsSection extends StatelessWidget {
  const EventsSection({super.key, this.embedded = false, this.listHeight});

  final bool embedded;
  final double? listHeight;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Events',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            FilledButton.icon(
              onPressed: () => Get.to<void>(() => const EventSubmissionPage()),
              icon: const Icon(Icons.add),
              label: const Text('Add Event'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0D0140),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => Get.to<void>(() => const MyEventsPage()),
            icon: const Icon(Icons.event_note_outlined),
            label: const Text('My Events'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Submitted events appear publicly after curator approval.',
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
        const SizedBox(height: 16),
        listHeight == null
            ? const Expanded(child: ApprovedEventsList())
            : SizedBox(height: listHeight, child: const ApprovedEventsList()),
      ],
    );

    if (embedded) return content;

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: Padding(padding: const EdgeInsets.all(20), child: content),
    );
  }
}

class MyEventsPage extends StatelessWidget {
  const MyEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to manage your events.')),
      );
    }

    final service = EventService();
    return Scaffold(
      appBar: AppBar(title: const Text('My Events')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.watchUserEvents(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load your events.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!.toList()
            ..sort((a, b) {
              final aTime = asDateTime(a['eventDateTime']);
              final bTime = asDateTime(b['eventDateTime']);
              return (aTime?.millisecondsSinceEpoch ?? 0).compareTo(
                bTime?.millisecondsSinceEpoch ?? 0,
              );
            });

          if (events.isEmpty) {
            return const EventsEmptyState(
              icon: Icons.event_note_outlined,
              title: 'No submitted events yet.',
              message: 'Submit an event and manage it here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final data = events[index];
              final eventId = data['id'].toString();
              final status = (data['status'] ?? 'pending').toString();
              return EventCard(
                data: data,
                statusLabel: status,
                adminActions: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => service.removeEvent(eventId),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Get.to<void>(
                          () => EventSubmissionPage(
                            eventId: eventId,
                            initialData: data,
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0D0140),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ApprovedEventsList extends StatelessWidget {
  const ApprovedEventsList({super.key});

  @override
  Widget build(BuildContext context) {
    // Scoped to this list: created and disposed with the widget.
    return GetBuilder<ApprovedEventsController>(
      init: ApprovedEventsController(),
      global: false,
      builder: (controller) => _approved(controller),
    );
  }

  Widget _approved(ApprovedEventsController controller) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: controller.service.watchApprovedEvents(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load events.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final now = DateTime.now();
        final events =
            snapshot.data!.where((event) {
              final eventDate = asDateTime(event['eventDateTime']);
              return eventDate == null || eventDate.isAfter(now);
            }).toList()..sort((a, b) {
              final aTime = asDateTime(a['eventDateTime']);
              final bTime = asDateTime(b['eventDateTime']);
              return (aTime?.millisecondsSinceEpoch ?? 0).compareTo(
                bTime?.millisecondsSinceEpoch ?? 0,
              );
            });

        if (events.isEmpty) {
          return const EventsEmptyState(
            icon: Icons.event_available_outlined,
            title: 'No approved events yet.',
            message: 'Check back soon or submit an event for approval.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: events.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final data = events[index];
            final eventId = data['id'].toString();
            final currentUserId = AppAuth.instance.currentUser?.uid ?? '';
            final isOwner = data['submittedBy'] == currentUserId;
            return EventCard(
              data: data,
              adminActions: isOwner
                  ? OutlinedButton.icon(
                      onPressed: () => Get.to<void>(
                        () => EventSubmissionPage(
                          eventId: eventId,
                          initialData: data,
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Event'),
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}

class EventSubmissionPage extends StatelessWidget {
  const EventSubmissionPage({super.key, this.eventId, this.initialData});

  final String? eventId;
  final Map<String, dynamic>? initialData;

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: created and disposed with the widget.
    return GetBuilder<EventSubmissionController>(
      init: EventSubmissionController(
        eventId: eventId,
        initialData: initialData,
      ),
      global: false,
      builder: (controller) => _SubmissionView(controller: controller),
    );
  }
}

class _SubmissionView extends StatelessWidget {
  const _SubmissionView({required this.controller});

  final EventSubmissionController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isEditing ? 'Edit Event' : 'Submit Event'),
      ),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            EventFlyerPicker(controller: controller),
            const SizedBox(height: 16),
            EventFormField(
              controller: controller.title,
              label: 'Event name',
              required: true,
            ),
            EventFormField(
              controller: controller.description,
              label: 'Description',
              maxLines: 3,
            ),
            EventFormField(
              controller: controller.location,
              label: 'Location',
              required: true,
            ),
            Obx(() {
              final when = controller.eventDateTime.value;
              return OutlinedButton.icon(
                onPressed: controller.saving.value
                    ? null
                    : controller.pickDateTime,
                icon: const Icon(Icons.schedule_outlined),
                label: Text(
                  when == null ? 'Choose date and time' : formatEventDate(when),
                ),
              );
            }),
            const SizedBox(height: 12),
            EventFormField(
              controller: controller.amenities,
              label: 'Amenities',
              hint: 'Parking, food, VIP seating',
            ),
            EventFormField(
              controller: controller.price,
              label: 'Price',
              hint: 'Free, 20, 50 VIP',
            ),
            EventFormField(
              controller: controller.phone,
              label: 'Phone number',
              hint: '+263...',
            ),
            EventFormField(
              controller: controller.whatsapp,
              label: 'WhatsApp number',
              hint: '+263... or WhatsApp link',
            ),
            EventFormField(
              controller: controller.bookingLink,
              label: 'Booking link',
              hint: 'https://...',
            ),
            const SizedBox(height: 8),
            Obx(() {
              final saving = controller.saving.value;
              final editing = controller.isEditing;
              return FilledButton.icon(
                onPressed: saving ? null : controller.submit,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(
                  saving
                      ? (editing ? 'Updating...' : 'Submitting...')
                      : (editing
                            ? 'Update for approval'
                            : 'Submit for approval'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D0140),
                  minimumSize: const Size(double.infinity, 50),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
