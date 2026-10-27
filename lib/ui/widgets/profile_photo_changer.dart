// Changing the signed-in user's profile photo: pick from camera or gallery,
// upload, then save the URL on the user's auth profile and Firestore record.
// Shared by the Profile page avatar and Settings.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/services/storage_service.dart';

/// Asks where the photo should come from, uploads it and saves it.
/// Returns the new photo URL, or null if the user cancelled or it failed
/// (a failure is reported in a snack bar).
Future<String?> changeProfilePhoto(
  BuildContext context, {
  ImagePicker? picker,
  StorageService? storage,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from photos'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;

  final image = await (picker ?? ImagePicker()).pickImage(
    source: source,
    imageQuality: 85,
    maxWidth: 1000,
  );
  if (image == null) return null;

  try {
    final url = await (storage ?? StorageService()).uploadProfileImageBytes(
      await image.readAsBytes(),
      user.uid,
    );
    await Future.wait([
      user.updatePhotoURL(url),
      FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'profileImageURL': url,
        'profileImageUrl': url,
        'profileImageUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    ]);
    return url;
  } on FirebaseException catch (error) {
    debugPrint('Profile photo update failed: ${error.code} ${error.message}');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your photo could not be updated. Please try again.'),
        ),
      );
    }
    return null;
  }
}
