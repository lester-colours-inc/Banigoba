// Sends makeover requests and stores generated looks for the signed-in user.
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MakeoverService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  /// Uploads the user's original full-body selfie or photo for AI processing.
  Future<String> uploadInputImage(File file, String userId) async {
    final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage
        .ref()
        .child('ai_makeovers')
        .child(userId)
        .child(filename);
    final uploadTask = await ref.putFile(file);
    if (uploadTask.state == TaskState.success) {
      return await ref.getDownloadURL();
    }
    throw Exception('Failed to upload makeover input image.');
  }

  /// Calls the Firebase cloud function to generate makeover result URLs.
  Future<List<String>> generateMakeover({
    required String userId,
    required String style,
    required String imageUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated.');
    }
    if (user.uid != userId) {
      throw Exception('The requested user does not match the signed-in user.');
    }

    try {
      final callable = _functions.httpsCallable('generateMakeover');
      final result = await callable.call(<String, dynamic>{
        'style': style,
        'imageUrl': imageUrl,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      final urls = data['generatedImageUrls'];
      if (urls is List) {
        return urls.map((item) => item.toString()).toList();
      }

      throw Exception('Unexpected response from makeover function.');
    } on FirebaseFunctionsException catch (error) {
      throw Exception(
        error.message ?? 'Makeover generation failed (${error.code}).',
      );
    }
  }

  /// Saves the generated makeover result into Firestore and the user's wardrobe.
  Future<void> saveGeneratedMakeover({
    required String userId,
    required String style,
    required List<String> generatedImageUrls,
    required String sourceImageUrl,
  }) async {
    final docRef = _db.collection('ai_makeovers').doc();
    final data = {
      'userId': userId,
      'style': style,
      'sourceImageUrl': sourceImageUrl,
      'generatedImageUrls': generatedImageUrls,
      'createdAt': FieldValue.serverTimestamp(),
    };
    await docRef.set(data);

    await _db
        .collection('users')
        .doc(userId)
        .collection('wardrobe')
        .doc(docRef.id)
        .set({
          'name': 'AI Makeover',
          'style': style,
          'imageUrls': generatedImageUrls,
          'sourceImageUrl': sourceImageUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'visibility': 'private',
        });
  }
}
