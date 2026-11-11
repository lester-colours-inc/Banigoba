// Saves a finished quick-add draft, and picks the photo for it.
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import 'package:banigoba/core/services/image_crop.dart';
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/shop/models/quick_add.dart';
import 'package:banigoba/modules/shop/services/product_service.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';

/// Saves a finished draft. The real one uploads the photo and adds the
/// product; tests use a fake.
abstract interface class QuickAddSaver {
  Future<void> save(QuickAddDraft draft, Uint8List photo);
}

class ProductQuickAddSaver implements QuickAddSaver {
  ProductQuickAddSaver({ProductService? products, ProfileService? profiles})
    : _products = products ?? ProductService(),
      _profiles = profiles ?? ProfileService();

  final ProductService _products;
  final ProfileService _profiles;

  @override
  Future<void> save(QuickAddDraft draft, Uint8List photo) async {
    final userId = AppAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) throw Exception('Sign in first.');
    final profile = await _profiles.get(userId);
    final shop = profile['shop'];
    final shopName =
        (shop is Map ? shop['name'] : null)?.toString().trim().isNotEmpty ==
            true
        ? (shop as Map)['name'].toString()
        : (profile['displayName'] ?? 'Boutique').toString();
    final imageUrl = await _products.uploadCatalogProductImageBytes(
      userId: userId,
      bytes: photo,
      customFilename: draft.displayName,
    );
    await _products.addProduct(
      draft.toProduct(imageUrl: imageUrl, shopName: shopName),
    );
  }
}

/// Picks a photo from the camera or the gallery; null when cancelled.
typedef PickPhoto = Future<Uint8List?> Function(ImageSource source);

Future<Uint8List?> pickWithImagePicker(ImageSource source) async {
  final file = await ImagePicker().pickAndCropImage(
    source: source,
    imageQuality: 85,
    maxWidth: 1600,
  );
  return file?.readAsBytes();
}
