import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

class MakeoverService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _functionUrl = 'https://europe-west1-internshipproject-68c13.cloudfunctions.net/generateMakeover';

  /// Uploads the user's original full-body selfie or photo for AI processing.
  Future<String> uploadInputImage(File file, String userId) async {
    final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('ai_makeovers').child(userId).child(filename);
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

    final idToken = await user.getIdToken();
    final response = await http.post(
      Uri.parse(_functionUrl),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer $idToken',
      },
      body: jsonEncode({
        'userId': userId,
        'style': style,
        'imageUrl': imageUrl,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Makeover service returned ${response.statusCode}: ${response.body}');
    }

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
    final urls = data['generatedImageUrls'];
    if (urls is List) {
      return urls.map((item) => item.toString()).toList();
    }

    throw Exception('Unexpected response from makeover function.');
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

    await _db.collection('users').doc(userId).collection('wardrobe').doc(docRef.id).set({
      'name': 'AI Makeover',
      'style': style,
      'imageUrls': generatedImageUrls,
      'sourceImageUrl': sourceImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'visibility': 'private',
    });
  }
}
