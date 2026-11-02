// Community events: submitted by anyone, shown to everyone once a curator
// approves them. Events are rows in `events`; screens read them as maps with
// camelCase fields, `id`, and `eventDateTime` as a DateTime.
import 'package:flutter/foundation.dart';

import '../../core/supabase/app_auth.dart';
import '../../core/supabase/supabase_config.dart';
import '../supabase/rows.dart';
import '../supabase/storage_files.dart';

/// An `events` row as the screens read it.
Map<String, dynamic> eventMap(Map<String, dynamic> row) {
  final flat = flattenRow(row);
  return {
    ...flat,
    'eventDateTime': asDateTime(row['starts_at']),
    'flyerUrl': row['image_url'],
    'submittedAt': row['created_at'],
  };
}

class EventService {
  Stream<List<Map<String, dynamic>>> _watch(
    bool Function(Map<String, dynamic> row) keep, {
    String? submittedBy,
  }) {
    final stream = submittedBy == null
        ? supabase.from('events').stream(primaryKey: ['id'])
        : supabase
              .from('events')
              .stream(primaryKey: ['id'])
              .eq('submitted_by', submittedBy);
    return stream.map(
      (rows) => [
        for (final row in rows)
          if (keep(row)) eventMap(row),
      ],
    );
  }

  Stream<List<Map<String, dynamic>>> watchApprovedEvents() =>
      _watch((row) => row['status'] == 'approved');

  Stream<List<Map<String, dynamic>>> watchPendingEvents() =>
      _watch((row) => row['status'] == 'pending');

  Stream<List<Map<String, dynamic>>> watchApprovedManageableEvents() =>
      watchApprovedEvents();

  Stream<List<Map<String, dynamic>>> watchUserEvents(String userId) =>
      _watch((_) => true, submittedBy: userId);

  Future<String> uploadEventFlyer({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final userId = AppAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      throw Exception('You must be signed in to upload an event flyer.');
    }

    final isPng = fileName.toLowerCase().endsWith('.png');
    return StorageFiles.upload(
      bucket: Buckets.events,
      path: '$userId/flyers/${randomFileName(isPng ? 'png' : 'jpg')}',
      bytes: bytes,
      contentType: isPng ? 'image/png' : 'image/jpeg',
    );
  }

  Map<String, dynamic> _fields({
    required String title,
    required String description,
    required String location,
    required DateTime eventDateTime,
    required List<String> amenities,
    required String price,
    required String phoneNumber,
    required String whatsappNumber,
    required String bookingLink,
    required String flyerUrl,
  }) {
    return {
      'title': title.trim(),
      'description': description.trim(),
      'location': location.trim(),
      'starts_at': eventDateTime.toUtc().toIso8601String(),
      'amenities': amenities,
      'price': price.trim(),
      'phone_number': phoneNumber.trim(),
      'whatsapp_number': whatsappNumber.trim(),
      'booking_link': bookingLink.trim(),
      'image_url': flyerUrl,
    };
  }

  Future<void> submitEvent({
    required String title,
    required String description,
    required String location,
    required DateTime eventDateTime,
    required List<String> amenities,
    required String price,
    required String phoneNumber,
    required String whatsappNumber,
    required String bookingLink,
    required String flyerUrl,
  }) async {
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to submit an event.');
    }

    await supabase.from('events').insert({
      ..._fields(
        title: title,
        description: description,
        location: location,
        eventDateTime: eventDateTime,
        amenities: amenities,
        price: price,
        phoneNumber: phoneNumber,
        whatsappNumber: whatsappNumber,
        bookingLink: bookingLink,
        flyerUrl: flyerUrl,
      ),
      'submitted_by': user.uid,
      'submitted_by_name': user.displayName ?? user.email ?? 'User',
    });
  }

  Future<void> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required String location,
    required DateTime eventDateTime,
    required List<String> amenities,
    required String price,
    required String phoneNumber,
    required String whatsappNumber,
    required String bookingLink,
    required String flyerUrl,
  }) async {
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to edit an event.');
    }

    final updated = await supabase
        .from('events')
        .update({
          ..._fields(
            title: title,
            description: description,
            location: location,
            eventDateTime: eventDateTime,
            amenities: amenities,
            price: price,
            phoneNumber: phoneNumber,
            whatsappNumber: whatsappNumber,
            bookingLink: bookingLink,
            flyerUrl: flyerUrl,
          ),
        })
        .eq('id', eventId)
        .eq('submitted_by', user.uid)
        .select('id');
    if (updated.isEmpty) {
      throw Exception('You are not authorised to edit this event.');
    }
  }

  Future<void> approveEvent(String eventId) async {
    await _reviewEvent(eventId: eventId, status: 'approved');
  }

  Future<void> disapproveEvent(String eventId) async {
    await _reviewEvent(eventId: eventId, status: 'disapproved');
  }

  Future<void> removeEvent(String eventId) async {
    await supabase.from('events').delete().eq('id', eventId);
  }

  /// Removes events whose date has passed (curators and the event's owner can
  /// only delete what they may see; the rest is cleaned up by the server).
  Future<void> removeExpiredEvents() async {
    try {
      await supabase
          .from('events')
          .delete()
          .lt('starts_at', DateTime.now().toUtc().toIso8601String());
    } on Object catch (error) {
      debugPrint('Unable to remove expired events: $error');
    }
  }

  Future<void> _reviewEvent({
    required String eventId,
    required String status,
  }) async {
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      throw Exception('You must be signed in as an admin.');
    }

    await supabase
        .from('events')
        .update({
          'status': status,
          'reviewed_by': user.uid,
          'reviewed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', eventId);
  }
}
