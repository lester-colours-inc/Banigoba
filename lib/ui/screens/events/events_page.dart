import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/services/event_service.dart';

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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const EventSubmissionPage(),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Event'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0D0140),
              ),
            ),
          ],
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

class ApprovedEventsList extends StatelessWidget {
  const ApprovedEventsList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: EventService().watchApprovedEvents(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load events.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final events = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final aTime = a.data()['eventDateTime'] as Timestamp?;
            final bTime = b.data()['eventDateTime'] as Timestamp?;
            return (aTime?.millisecondsSinceEpoch ?? 0).compareTo(
              bTime?.millisecondsSinceEpoch ?? 0,
            );
          });

        if (events.isEmpty) {
          return const _EventsEmptyState(
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
            return EventCard(data: events[index].data());
          },
        );
      },
    );
  }
}

class EventSubmissionPage extends StatefulWidget {
  const EventSubmissionPage({super.key});

  @override
  State<EventSubmissionPage> createState() => _EventSubmissionPageState();
}

class _EventSubmissionPageState extends State<EventSubmissionPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _amenitiesController = TextEditingController();
  final _priceController = TextEditingController();
  final _picker = ImagePicker();
  final _service = EventService();

  DateTime? _eventDateTime;
  Uint8List? _flyerBytes;
  String? _flyerName;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _amenitiesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickFlyer() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _flyerBytes = bytes;
      _flyerName = picked.name;
    });
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDateTime ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _eventDateTime == null
          ? TimeOfDay.now()
          : TimeOfDay.fromDateTime(_eventDateTime!),
    );
    if (time == null) return;

    setState(() {
      _eventDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_eventDateTime == null) {
      _message('Choose the event date and time.');
      return;
    }
    if (_flyerBytes == null) {
      _message('Upload the event flyer.');
      return;
    }

    setState(() => _saving = true);
    try {
      final flyerUrl = await _service.uploadEventFlyer(
        bytes: _flyerBytes!,
        fileName: _flyerName ?? 'event-flyer.jpg',
      );
      await _service.submitEvent(
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        eventDateTime: _eventDateTime!,
        amenities: _splitCsv(_amenitiesController.text),
        price: _priceController.text,
        flyerUrl: flyerUrl,
      );

      if (!mounted) return;
      _message('Event submitted for curator approval.');
      Navigator.pop(context);
    } catch (error) {
      _message('Unable to submit event: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _eventDateTime == null
        ? 'Choose date and time'
        : _formatEventDate(_eventDateTime!);

    return Scaffold(
      appBar: AppBar(title: const Text('Submit Event')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GestureDetector(
              onTap: _saving ? null : _pickFlyer,
              child: AspectRatio(
                aspectRatio: 1.45,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _flyerBytes == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_file_outlined, size: 36),
                            SizedBox(height: 8),
                            Text('Upload event flyer'),
                          ],
                        )
                      : Image.memory(_flyerBytes!, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _field(_titleController, 'Event name', required: true),
            _field(_descriptionController, 'Description', maxLines: 3),
            _field(_locationController, 'Location', required: true),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickDateTime,
              icon: const Icon(Icons.schedule_outlined),
              label: Text(dateLabel),
            ),
            const SizedBox(height: 12),
            _field(
              _amenitiesController,
              'Amenities',
              hint: 'Parking, food, VIP seating',
            ),
            _field(_priceController, 'Price', hint: 'Free, 20, 50 VIP'),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(_saving ? 'Submitting...' : 'Submit for approval'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0D0140),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    int maxLines = 1,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: required
            ? (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.data, this.adminActions});

  final Map<String, dynamic> data;
  final Widget? adminActions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = (data['title'] ?? 'Event').toString();
    final flyerUrl = (data['flyerUrl'] ?? '').toString();
    final location = (data['location'] ?? '').toString();
    final price = (data['price'] ?? '').toString();
    final description = (data['description'] ?? '').toString();
    final amenities = List<String>.from(data['amenities'] ?? const []);
    final eventDate = data['eventDateTime'] is Timestamp
        ? (data['eventDateTime'] as Timestamp).toDate()
        : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.65,
            child: flyerUrl.isEmpty
                ? Container(
                    color: colors.surfaceContainerHighest,
                    child: const Icon(Icons.event_outlined, size: 44),
                  )
                : Image.network(
                    flyerUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: colors.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (eventDate != null) ...[
                  const SizedBox(height: 6),
                  _meta(Icons.schedule_outlined, _formatEventDate(eventDate)),
                ],
                if (location.isNotEmpty)
                  _meta(Icons.location_on_outlined, location),
                if (price.isNotEmpty) _meta(Icons.sell_outlined, price),
                if (amenities.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: amenities
                        .map((item) => Chip(label: Text(item)))
                        .toList(),
                  ),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (adminActions != null) ...[
                  const SizedBox(height: 12),
                  adminActions!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _EventsEmptyState extends StatelessWidget {
  const _EventsEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: const Color(0xFF0D0140)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}

List<String> _splitCsv(String value) {
  return value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

String _formatEventDate(DateTime date) {
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
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day} ${months[date.month - 1]} ${date.year} at $hour:$minute';
}
