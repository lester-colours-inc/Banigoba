// Generates, stores, and retrieves hairstyle makeover results.
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/affirmation.dart';
import '../models/post.dart';
import 'affirmation_service.dart';

class HairstyleService {
  HairstyleService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Future<String> saveLatestSelfie({
    required String userId,
    required Uint8List imageBytes,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final selfieRef = _storage
        .ref()
        .child('userImages')
        .child(userId)
        .child('hairStyles')
        .child('selfies')
        .child('$timestamp.jpg');

    await selfieRef.putData(
      imageBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final imageUrl = await selfieRef.getDownloadURL();

    await _firestore.collection('users').doc(userId).set({
      'latestHairStyleSelfieUrl': imageUrl,
      'hairStyleSelfieUrls': FieldValue.arrayUnion([imageUrl]),
      'hairStyleSelfieUploadedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return imageUrl;
  }

  Future<String?> getLatestSelfieUrl(String userId) async {
    final snapshot = await _firestore.collection('users').doc(userId).get();
    final value = snapshot.data()?['latestHairStyleSelfieUrl'];
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  Future<Uint8List> downloadSelfie(String imageUrl) async {
    const maxSize = 10 * 1024 * 1024;
    final bytes = await _storage.refFromURL(imageUrl).getData(maxSize);
    if (bytes == null || bytes.isEmpty) {
      throw Exception('The saved hairstyle selfie is empty.');
    }
    return bytes;
  }

  Future<void> saveLook({
    required String userId,
    required String styleName,
    required String prompt,
    required String styleReferenceImageUrl,
    required HairstyleGeneration generation,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('hairStyles')
        .add({
          'styleName': styleName,
          'prompt': prompt,
          'sourceImageUrl': generation.sourceImageUrl,
          'resultImageUrl': generation.resultImageUrl,
          'styleReferenceImageUrl': styleReferenceImageUrl,
          'isPreview': generation.isPreview,
          'previewType': generation.isPreview ? 'mock_collage' : 'generated',
          'authorId': userId,
          'isPublic': false,
          'visibility': 'private',
          'commentCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSavedLooks(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('hairStyles')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> makeSavedLookPublic({
    required String userId,
    required String lookId,
  }) async {
    await _savedLookRef(userId, lookId).update({
      'isPublic': true,
      'visibility': 'public',
      'publishedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> makeSavedLookPrivate({
    required String userId,
    required String lookId,
  }) async {
    await _savedLookRef(userId, lookId).update({
      'isPublic': false,
      'visibility': 'private',
      'privatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSavedLook({
    required String userId,
    required String lookId,
  }) async {
    final lookRef = _savedLookRef(userId, lookId);
    final comments = await lookRef.collection('comments').get();
    final batch = _firestore.batch();
    for (final comment in comments.docs) {
      batch.delete(comment.reference);
    }
    batch.delete(lookRef);
    await batch.commit();

    // Affirmations must not outlive the look they were about.
    await AffirmationService().deleteAllForTarget(
      targetType: AffirmationTargetType.hairLook,
      targetId: lookId,
    );
  }

  Future<void> addSavedLookComment({
    required String ownerId,
    required String lookId,
    required String userId,
    required String text,
    required String username,
    required String profileImageURL,
  }) async {
    if (userId.isEmpty || text.trim().isEmpty) return;
    final lookRef = _savedLookRef(ownerId, lookId);
    final commentRef = lookRef.collection('comments').doc();

    await _firestore.runTransaction((transaction) async {
      transaction.set(commentRef, {
        'authorId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'profileImageURL': profileImageURL,
        'text': text.trim(),
        'username': username,
      });
      transaction.update(lookRef, {'commentCount': FieldValue.increment(1)});
    });
  }

  Stream<List<PostComment>> watchSavedLookComments({
    required String ownerId,
    required String lookId,
  }) {
    return _savedLookRef(ownerId, lookId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PostComment.fromFirestore(doc))
              .toList(),
        );
  }

  DocumentReference<Map<String, dynamic>> _savedLookRef(
    String userId,
    String lookId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('hairStyles')
        .doc(lookId);
  }

  Future<String> uploadCatalogHairstyle({
    required String userId,
    required Uint8List imageBytes,
    required String filename,
    required String length,
    required String gender,
    required String hairType,
    required List<String> styleTypes,
    required String cutTypeGroup,
    required String cutType,
    required List<String> occasions,
    required String colour,
    required String maintenanceLevel,
    String? name,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = _safeStorageName(
      filename.trim().isEmpty ? cutType : filename,
    );
    final storageRef = _storage
        .ref()
        .child('hairstyles')
        .child('${timestamp}_$safeName.jpg');

    await storageRef.putData(
      imageBytes,
      SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploadedBy': userId, 'catalogType': 'hairstyle'},
      ),
    );
    final imageUrl = await storageRef.getDownloadURL();

    final doc = await _firestore.collection('hairstyles').add({
      'name': name?.trim().isNotEmpty == true ? name!.trim() : cutType,
      'imageUrl': imageUrl,
      'storagePath': storageRef.fullPath,
      'length': length,
      'gender': gender,
      'hairType': hairType,
      'styleType': styleTypes.isEmpty ? '' : styleTypes.first,
      'styleTypes': styleTypes,
      'cutTypeGroup': cutTypeGroup,
      'cutType': cutType,
      'occasion': occasions.isEmpty ? '' : occasions.first,
      'occasions': occasions,
      'colour': colour,
      'maintenanceLevel': maintenanceLevel,
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  Future<void> updateCatalogHairstyle({
    required String docId,
    required String userId,
    Uint8List? imageBytes,
    String? filename,
    required String length,
    required String gender,
    required String hairType,
    required List<String> styleTypes,
    required String cutTypeGroup,
    required String cutType,
    required List<String> occasions,
    required String colour,
    required String maintenanceLevel,
    String? name,
  }) async {
    final docRef = _firestore.collection('hairstyles').doc(docId);
    final updates = <String, dynamic>{
      'name': name?.trim().isNotEmpty == true ? name!.trim() : cutType,
      'length': length,
      'gender': gender,
      'hairType': hairType,
      'styleType': styleTypes.isEmpty ? '' : styleTypes.first,
      'styleTypes': styleTypes,
      'cutTypeGroup': cutTypeGroup,
      'cutType': cutType,
      'occasion': occasions.isEmpty ? '' : occasions.first,
      'occasions': occasions,
      'colour': colour,
      'maintenanceLevel': maintenanceLevel,
      'updatedBy': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (imageBytes != null) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = _safeStorageName(
        filename?.trim().isNotEmpty == true ? filename! : cutType,
      );
      final storageRef = _storage
          .ref()
          .child('hairstyles')
          .child('${timestamp}_$safeName.jpg');

      await storageRef.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uploadedBy': userId, 'catalogType': 'hairstyle'},
        ),
      );
      updates['imageUrl'] = await storageRef.getDownloadURL();
      updates['storagePath'] = storageRef.fullPath;
    }

    await docRef.set(updates, SetOptions(merge: true));
  }

  String _safeStorageName(String value) {
    final cleaned = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return cleaned.isEmpty ? 'hairstyle' : cleaned;
  }
}

class HairstyleGeneration {
  const HairstyleGeneration({
    required this.sourceImageUrl,
    required this.resultImageUrl,
    required this.isPreview,
  });

  final String sourceImageUrl;
  final String resultImageUrl;
  final bool isPreview;
}
