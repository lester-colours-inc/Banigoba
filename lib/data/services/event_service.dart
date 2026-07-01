import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class EventService {
  EventService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchApprovedEvents() {
    return _db
        .collection('events')
        .where('status', isEqualTo: 'approved')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPendingEvents() {
    return _db
        .collection('events')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchApprovedManageableEvents() {
    return _db
        .collection('events')
        .where('status', isEqualTo: 'approved')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUserEvents(String userId) {
    return _db
        .collection('events')
        .where('submittedBy', isEqualTo: userId)
        .snapshots();
  }

  Future<String> uploadEventFlyer({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      throw Exception('You must be signed in to upload an event flyer.');
    }

    final safeName = fileName
        .replaceAll(RegExp(r'[^\w.\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final uploadId = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = _storage
        .ref()
        .child('events')
        .child(userId)
        .child('flyers')
        .child('$uploadId-$safeName');

    final contentType = safeName.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
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
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to submit an event.');
    }

    await _db.collection('events').add({
      'title': title.trim(),
      'description': description.trim(),
      'location': location.trim(),
      'eventDateTime': Timestamp.fromDate(eventDateTime),
      'amenities': amenities,
      'price': price.trim(),
      'phoneNumber': phoneNumber.trim(),
      'whatsappNumber': whatsappNumber.trim(),
      'bookingLink': bookingLink.trim(),
      'flyerUrl': flyerUrl,
      'status': 'pending',
      'submittedBy': user.uid,
      'submittedByName': user.displayName ?? user.email ?? 'User',
      'submittedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
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
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to edit an event.');
    }

    final eventRef = _db.collection('events').doc(eventId);
    final event = await eventRef.get();
    final data = event.data();
    if (data == null || data['submittedBy'] != user.uid) {
      throw Exception('You are not authorised to edit this event.');
    }

    await eventRef.set({
      'title': title.trim(),
      'description': description.trim(),
      'location': location.trim(),
      'eventDateTime': Timestamp.fromDate(eventDateTime),
      'amenities': amenities,
      'price': price.trim(),
      'phoneNumber': phoneNumber.trim(),
      'whatsappNumber': whatsappNumber.trim(),
      'bookingLink': bookingLink.trim(),
      'flyerUrl': flyerUrl,
      'status': 'pending',
      'updatedAt': FieldValue.serverTimestamp(),
      'editedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> approveEvent(String eventId) async {
    await _reviewEvent(eventId: eventId, status: 'approved');
  }

  Future<void> disapproveEvent(String eventId) async {
    await _reviewEvent(eventId: eventId, status: 'disapproved');
  }

  Future<void> removeEvent(String eventId) async {
    await _db.collection('events').doc(eventId).delete();
  }

  Future<void> removeExpiredEvents() async {
    final now = Timestamp.now();
    final expired = await _db
        .collection('events')
        .where('eventDateTime', isLessThan: now)
        .get();
    if (expired.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in expired.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> _reviewEvent({
    required String eventId,
    required String status,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in as an admin.');
    }

    await _db.collection('events').doc(eventId).set({
      'status': status,
      'reviewedBy': user.uid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
