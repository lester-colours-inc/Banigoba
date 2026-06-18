// Generates, stores, and retrieves hairstyle makeover results.
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'photo_edit_api.dart';

class HairstyleService {
  HairstyleService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const String _apiKey = String.fromEnvironment('FASHN_API_KEY');

  bool get isAiConfigured => _apiKey.isNotEmpty;

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

  Future<HairstyleGeneration> generate({
    required String userId,
    required Uint8List sourceBytes,
    required String styleName,
    required String prompt,
    String? sourceImageUrl,
  }) async {
    final directory = _storage
        .ref()
        .child('userImages')
        .child(userId)
        .child('hairStyles');
    final sourceUrl =
        sourceImageUrl ??
        await saveLatestSelfie(userId: userId, imageBytes: sourceBytes);

    if (!isAiConfigured) {
      return HairstyleGeneration(
        sourceImageUrl: sourceUrl,
        resultImageUrl: sourceUrl,
        isPreview: true,
      );
    }

    final output = await PhotoEditApi(
      apiKey: _apiKey,
    ).applyHairStyle(imageUrl: sourceUrl, prompt: prompt, numImages: 1);
    if (output.isEmpty) {
      throw Exception('The hairstyle service returned no image.');
    }

    final response = await http.get(Uri.parse(output.first));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to download the generated hairstyle.');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final resultRef = directory.child('${timestamp}_result.png');
    await resultRef.putData(
      response.bodyBytes,
      SettableMetadata(
        contentType:
            response.headers['content-type']?.split(';').first ?? 'image/png',
      ),
    );

    return HairstyleGeneration(
      sourceImageUrl: sourceUrl,
      resultImageUrl: await resultRef.getDownloadURL(),
      isPreview: false,
    );
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

  Future<String> uploadCatalogHairstyle({
    required String userId,
    required Uint8List imageBytes,
    required String filename,
    required String length,
    required String gender,
    required String hairType,
    required String styleType,
    required String cutTypeGroup,
    required String cutType,
    required String occasion,
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
      'styleType': styleType,
      'cutTypeGroup': cutTypeGroup,
      'cutType': cutType,
      'occasion': occasion,
      'colour': colour,
      'maintenanceLevel': maintenanceLevel,
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
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
