import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/services/event_service.dart';
import '../../widgets/app_network_image.dart';

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
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const MyEventsPage()),
            ),
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to manage your events.')),
      );
    }

    final service = EventService();
    return Scaffold(
      appBar: AppBar(title: const Text('My Events')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.watchUserEvents(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load your events.'));
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
              final doc = events[index];
              final data = doc.data();
              final status = (data['status'] ?? 'pending').toString();
              return EventCard(
                data: data,
                statusLabel: status,
                adminActions: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => service.removeEvent(doc.id),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => EventSubmissionPage(
                              eventId: doc.id,
                              initialData: data,
                            ),
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

class ApprovedEventsList extends StatefulWidget {
  const ApprovedEventsList({super.key});

  @override
  State<ApprovedEventsList> createState() => _ApprovedEventsListState();
}

class _ApprovedEventsListState extends State<ApprovedEventsList> {
  final _service = EventService();

  @override
  void initState() {
    super.initState();
    _service.removeExpiredEvents();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.watchApprovedEvents(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load events.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final now = DateTime.now();
        final events =
            snapshot.data!.docs.where((doc) {
              final eventDate = doc.data()['eventDateTime'] as Timestamp?;
              return eventDate == null || eventDate.toDate().isAfter(now);
            }).toList()..sort((a, b) {
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
            final doc = events[index];
            final data = doc.data();
            final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
            final isOwner = data['submittedBy'] == currentUserId;
            return EventCard(
              data: data,
              adminActions: isOwner
                  ? OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => EventSubmissionPage(
                            eventId: doc.id,
                            initialData: data,
                          ),
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

class EventSubmissionPage extends StatefulWidget {
  const EventSubmissionPage({super.key, this.eventId, this.initialData});

  final String? eventId;
  final Map<String, dynamic>? initialData;

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
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _bookingLinkController = TextEditingController();
  final _picker = ImagePicker();
  final _service = EventService();

  DateTime? _eventDateTime;
  Uint8List? _flyerBytes;
  String? _flyerName;
  String? _existingFlyerUrl;
  bool _saving = false;

  bool get _isEditing => widget.eventId?.isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data == null) return;
    _titleController.text = (data['title'] ?? '').toString();
    _descriptionController.text = (data['description'] ?? '').toString();
    _locationController.text = (data['location'] ?? '').toString();
    _amenitiesController.text = List<String>.from(
      data['amenities'] ?? const [],
    ).join(', ');
    _priceController.text = (data['price'] ?? '').toString();
    _phoneController.text = (data['phoneNumber'] ?? '').toString();
    _whatsappController.text = (data['whatsappNumber'] ?? '').toString();
    _bookingLinkController.text = (data['bookingLink'] ?? '').toString();
    _existingFlyerUrl = (data['flyerUrl'] ?? '').toString();
    if (data['eventDateTime'] is Timestamp) {
      _eventDateTime = (data['eventDateTime'] as Timestamp).toDate();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _amenitiesController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _bookingLinkController.dispose();
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
    if (_flyerBytes == null && (_existingFlyerUrl?.isEmpty ?? true)) {
      _message('Upload the event flyer.');
      return;
    }

    setState(() => _saving = true);
    try {
      final flyerUrl = _flyerBytes == null
          ? _existingFlyerUrl!
          : await _service.uploadEventFlyer(
              bytes: _flyerBytes!,
              fileName: _flyerName ?? 'event-flyer.jpg',
            );
      if (_isEditing) {
        await _service.updateEvent(
          eventId: widget.eventId!,
          title: _titleController.text,
          description: _descriptionController.text,
          location: _locationController.text,
          eventDateTime: _eventDateTime!,
          amenities: _splitCsv(_amenitiesController.text),
          price: _priceController.text,
          phoneNumber: _phoneController.text,
          whatsappNumber: _whatsappController.text,
          bookingLink: _bookingLinkController.text,
          flyerUrl: flyerUrl,
        );
      } else {
        await _service.submitEvent(
          title: _titleController.text,
          description: _descriptionController.text,
          location: _locationController.text,
          eventDateTime: _eventDateTime!,
          amenities: _splitCsv(_amenitiesController.text),
          price: _priceController.text,
          phoneNumber: _phoneController.text,
          whatsappNumber: _whatsappController.text,
          bookingLink: _bookingLinkController.text,
          flyerUrl: flyerUrl,
        );
      }

      if (!mounted) return;
      _message(
        _isEditing
            ? 'Event updated and sent for curator approval.'
            : 'Event submitted for curator approval.',
      );
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
      appBar: AppBar(title: Text(_isEditing ? 'Edit Event' : 'Submit Event')),
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
                  child: _buildFlyerPreview(),
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
            _field(_phoneController, 'Phone number', hint: '+263...'),
            _field(
              _whatsappController,
              'WhatsApp number',
              hint: '+263... or WhatsApp link',
            ),
            _field(_bookingLinkController, 'Booking link', hint: 'https://...'),
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
              label: Text(
                _saving
                    ? (_isEditing ? 'Updating...' : 'Submitting...')
                    : (_isEditing
                          ? 'Update for approval'
                          : 'Submit for approval'),
              ),
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

  Widget _buildFlyerPreview() {
    final background = Theme.of(context).colorScheme.surfaceContainerHighest;
    if (_flyerBytes != null) {
      return ColoredBox(
        color: background,
        child: Center(child: Image.memory(_flyerBytes!, fit: BoxFit.contain)),
      );
    }
    if (_existingFlyerUrl?.isNotEmpty == true) {
      return ColoredBox(
        color: background,
        child: Center(
          child: AppNetworkImage(
            _existingFlyerUrl!,
            fit: BoxFit.contain,
            fallback: _buildFlyerPlaceholder(),
          ),
        ),
      );
    }
    return _buildFlyerPlaceholder();
  }

  Widget _buildFlyerPlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.upload_file_outlined, size: 36),
        SizedBox(height: 8),
        Text('Upload event flyer'),
      ],
    );
  }
}

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.data,
    this.adminActions,
    this.statusLabel,
  });

  final Map<String, dynamic> data;
  final Widget? adminActions;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = (data['title'] ?? 'Event').toString();
    final flyerUrl = (data['flyerUrl'] ?? '').toString();
    final location = (data['location'] ?? '').toString();
    final price = (data['price'] ?? '').toString();
    final phoneNumber = (data['phoneNumber'] ?? '').toString();
    final whatsappNumber = (data['whatsappNumber'] ?? '').toString();
    final bookingLink = (data['bookingLink'] ?? '').toString();
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
                : ColoredBox(
                    color: colors.surfaceContainerHighest,
                    child: Center(
                      child: AppNetworkImage(
                        flyerUrl,
                        fit: BoxFit.contain,
                        fallback: Container(
                          color: colors.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
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
                if (statusLabel?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Chip(label: Text(statusLabel!)),
                ],
                if (eventDate != null) ...[
                  const SizedBox(height: 6),
                  _meta(Icons.schedule_outlined, _formatEventDate(eventDate)),
                ],
                if (location.isNotEmpty)
                  _meta(Icons.location_on_outlined, location),
                if (price.isNotEmpty) _meta(Icons.sell_outlined, price),
                if (phoneNumber.isNotEmpty)
                  _meta(
                    Icons.phone_outlined,
                    phoneNumber,
                    onTap: () => _launchPhone(context, phoneNumber),
                    actionLabel: 'Call',
                  ),
                if (whatsappNumber.isNotEmpty)
                  _meta(
                    Icons.chat_outlined,
                    'WhatsApp: $whatsappNumber',
                    onTap: () => _launchWhatsapp(context, whatsappNumber),
                    actionLabel: 'Open',
                  ),
                if (bookingLink.isNotEmpty)
                  _meta(
                    Icons.link_outlined,
                    bookingLink,
                    onTap: () => _launchWebLink(context, bookingLink),
                    actionLabel: 'Book',
                  ),
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

  Widget _meta(
    IconData icon,
    String text, {
    VoidCallback? onTap,
    String? actionLabel,
  }) {
    final row = Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text(text)),
          if (onTap != null && actionLabel != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0D0140),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return row;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: row,
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

Future<void> _launchPhone(BuildContext context, String phoneNumber) async {
  final cleaned = phoneNumber.replaceAll(RegExp(r'[\s().-]+'), '');
  await _launchExternalUri(
    context,
    Uri(scheme: 'tel', path: cleaned),
    label: 'phone dialer',
  );
}

Future<void> _launchWhatsapp(BuildContext context, String value) async {
  final trimmed = value.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    await _launchExternalUri(context, Uri.parse(trimmed), label: 'WhatsApp');
    return;
  }

  final phone = _whatsappPath(trimmed);
  final whatsappUri = Uri.parse('whatsapp://send?phone=$phone');
  final openedWhatsapp = await _tryLaunch(whatsappUri);
  if (openedWhatsapp) return;
  if (!context.mounted) return;

  await _launchExternalUri(
    context,
    Uri.https('wa.me', phone),
    label: 'WhatsApp',
  );
}

Future<void> _launchWebLink(BuildContext context, String link) async {
  final trimmed = link.trim();
  final normalized =
      trimmed.startsWith('http://') || trimmed.startsWith('https://')
      ? trimmed
      : 'https://$trimmed';
  await _launchExternalUri(
    context,
    Uri.parse(normalized),
    label: 'booking link',
  );
}

String _whatsappPath(String value) {
  final cleaned = value.replaceAll(RegExp(r'[^0-9+]'), '');
  if (cleaned.startsWith('+')) return cleaned.substring(1);
  return cleaned;
}

Future<void> _launchExternalUri(
  BuildContext context,
  Uri uri, {
  required String label,
}) async {
  final opened = await _tryLaunch(uri);
  if (opened || !context.mounted) return;

  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('Unable to open $label.')));
}

Future<bool> _tryLaunch(Uri uri) async {
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return true;
    }
    return launchUrl(uri, mode: LaunchMode.platformDefault);
  } catch (_) {
    return false;
  }
}
