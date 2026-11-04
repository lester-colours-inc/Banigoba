// What the guided first run (see first_run_guide_screen.dart) really does at
// each step: save a photo, ask for style preferences, add wardrobe pieces from
// photos (the AI fills in the details), and open the makeover.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/garment_tags.dart';
import '../../../data/services/garment_tagger.dart';
import '../../../data/services/product_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/style_preferences_service.dart';
import '../makeover/makeover_start_sheet.dart';
import 'first_run_guide_screen.dart';
import 'style_preferences_screen.dart';

class AppGuideActions implements GuideActions {
  AppGuideActions({
    required this.userId,
    StylePreferencesService? preferences,
    StorageService? storage,
    ProductService? products,
    GarmentTagger? tagger,
    ImagePicker? picker,
  }) : _preferences = preferences ?? StylePreferencesService(),
       _storage = storage ?? StorageService(),
       _products = products ?? ProductService(),
       _tagger = tagger ?? GeminiGarmentTagger(),
       _picker = picker ?? ImagePicker();

  final String userId;
  final StylePreferencesService _preferences;
  final StorageService _storage;
  final ProductService _products;
  final GarmentTagger _tagger;
  final ImagePicker _picker;

  Future<Uint8List?> _pickPhoto(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheet, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from photos'),
              onTap: () => Navigator.pop(sheet, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return null;
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    return file?.readAsBytes();
  }

  @override
  Future<bool> addPhoto(BuildContext context) async {
    final bytes = await _pickPhoto(context);
    if (bytes == null) return false;
    // The newest full-body photo is the one makeovers start from.
    await _storage.uploadFullBodyImageBytes(bytes, userId);
    return true;
  }

  @override
  Future<bool> pickStyle(BuildContext context) async {
    var saved = false;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (routeContext) => StylePreferencesScreen(
          onSave: (answers) async {
            await _preferences.saveAnswers(userId, answers);
            saved = true;
            if (routeContext.mounted) Navigator.pop(routeContext);
          },
          onSkip: () async => Navigator.pop(routeContext),
        ),
      ),
    );
    return saved;
  }

  @override
  Future<bool> addPiece(BuildContext context) async {
    final bytes = await _pickPhoto(context);
    if (bytes == null) return false;
    // Let the AI describe it; with no answer the piece is still added with
    // plain defaults, and everything can be edited in the wardrobe later.
    final tags =
        (_tagger.isConfigured ? await _tagger.tag(bytes) : null) ??
        const GarmentTags();
    final imageUrl = await _products.uploadCatalogProductImageBytes(
      userId: userId,
      bytes: bytes,
      customFilename: tags.name,
    );
    await _products.uploadUserProduct(
      userId: userId,
      name: tags.name.isEmpty ? 'My piece' : tags.name,
      imageUrl: imageUrl,
      rawImageUrl: imageUrl,
      visibility: 'private',
      category: tags.category ?? 'tops',
      subcategory: tags.subcategory,
      styleTag: tags.styleTag ?? 'casual',
      colours: tags.colours,
      gender: tags.gender ?? 'unisex',
      weatherTags: tags.weatherTags,
      functionalTags: tags.functionalTags,
    );
    return true;
  }

  @override
  Future<bool> tryMakeover(BuildContext context) async {
    await startMakeover(context);
    // Opening the makeover is the step; they may come back with or without a
    // finished look.
    return true;
  }

  @override
  Future<void> finish() => _preferences.skip(userId);
}
