// The start of the AI makeover: choose or reuse a full-body photo.
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'package:banigoba/app/routes/app_routes.dart';
import 'package:banigoba/core/services/image_crop.dart';
import 'package:banigoba/core/services/storage_service.dart';
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/wardrobe/views/measurement_page.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class AiUploadController extends GetxController {
  AiUploadController({
    this.plannedDate,
    this.eventId,
    this.eventName,
    this.returnWhenSaved = false,
    ImagePicker? picker,
    StorageService? storageService,
  }) : _picker = picker ?? ImagePicker(),
       _storageService = storageService ?? StorageService();

  final DateTime? plannedDate;
  final String? eventId;
  final String? eventName;

  /// Opened just to set the avatar (from Avatar Try-On): once a photo is
  /// saved or the saved one is kept, go back instead of starting a makeover.
  final bool returnWhenSaved;
  final ImagePicker _picker;
  final StorageService _storageService;

  final Rxn<Uint8List> selectedImageBytes = Rxn<Uint8List>();
  final Rxn<Uint8List> existingImageBytes = Rxn<Uint8List>();
  final RxnString existingImageUrl = RxnString();
  final RxBool isPicking = false.obs;
  final RxBool isLoadingExisting = false.obs;
  final RxnString existingImageError = RxnString();

  /// Index of the selected styling preference chip.
  final RxInt selectedPreference = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadExistingFullBodyImage();
  }

  void openCart() => Get.toNamed<void>(AppRoutes.cart);

  void selectPreference(int index) => selectedPreference.value = index;

  Future<void> loadExistingFullBodyImage() async {
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      debugPrint('[AiUpload] Cannot load image: no authenticated user');
      return;
    }

    debugPrint('[AiUpload] Loading image for user ${user.uid}');
    isLoadingExisting.value = true;
    existingImageError.value = null;
    existingImageBytes.value = null;

    try {
      // The newest full-body photo in the person's own folder.
      final existingUrl = await _storageService.getLatestFullBodyImageUrl(
        user.uid,
      );

      if (existingUrl != null) {
        await _storageService.debugImageAccess(existingUrl);
        if (kIsWeb) {
          debugPrint(
            '[AiUpload] Web detected; using an HTML image element to bypass CORS byte-fetch restrictions',
          );
        } else {
          debugPrint('[AiUpload] Downloading saved image');
          final bytes = await _storageService.downloadImageBytes(existingUrl);
          if (bytes == null) {
            throw StateError('Storage returned no bytes for the saved image.');
          }
          debugPrint('[AiUpload] Saved image bytes loaded: ${bytes.length}');
          existingImageBytes.value = bytes;
        }
      } else {
        debugPrint('[AiUpload] No saved full-body image URL was found');
      }
      if (isClosed) return;
      existingImageUrl.value = existingUrl;
    } on PostgrestException catch (e, stackTrace) {
      debugPrint(
        '[AiUpload] Image lookup failed: code=${e.code}, message=${e.message}',
      );
      debugPrintStack(stackTrace: stackTrace);
      if (!isClosed) {
        existingImageError.value = 'Saved photo could not be loaded.';
      }
    } catch (e, stackTrace) {
      debugPrint('[AiUpload] Saved image lookup failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!isClosed) {
        existingImageError.value = 'Saved photo could not be loaded.';
      }
    } finally {
      if (!isClosed) isLoadingExisting.value = false;
    }
  }

  Future<void> pickImage(ImageSource source) async {
    isPicking.value = true;
    try {
      final image = await _picker.pickAndCropImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1400,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      debugPrint('[AiUpload] Picked ${bytes.length} bytes from ${source.name}');
      selectedImageBytes.value = bytes;
      existingImageError.value = null;

      await _saveFullBodyImage(bytes);

      if (isClosed) return;
      if (returnWhenSaved) {
        Get.back<void>();
        return;
      }
      _openMeasurement(imageBytes: bytes);
    } catch (e, stackTrace) {
      debugPrint('[AiUpload] Pick/upload flow failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!isClosed) AppToast.say('Unable to pick or save image: $e');
    } finally {
      if (!isClosed) isPicking.value = false;
    }
  }

  Future<void> _saveFullBodyImage(Uint8List bytes) async {
    final user = AppAuth.instance.currentUser;
    if (user == null) return;

    final imageUrl = await _storageService.uploadFullBodyImageBytes(
      bytes,
      user.uid,
    );
    debugPrint(
      '[AiUpload] Upload returned URL: ${StorageService.describeDownloadUrl(imageUrl)}',
    );

    // The newest file in the person's folder is their current full-body photo.
    debugPrint('[AiUpload] Saved full-body photo for ${user.uid}');
  }

  void clearSelectedImage() {
    selectedImageBytes.value = null;
    existingImageBytes.value = null;
    existingImageUrl.value = null;
    existingImageError.value = null;
  }

  Future<void> useExistingSavedPhoto() async {
    final savedUrl = existingImageUrl.value;
    if (savedUrl == null) return;
    // The saved photo already is the avatar; nothing to upload.
    if (returnWhenSaved) {
      Get.back<void>();
      return;
    }

    if (kIsWeb) {
      debugPrint(
        '[AiUpload] Passing saved image URL to style selection on web',
      );
      if (isClosed) return;
      _openMeasurement(imageUrl: savedUrl);
      return;
    }

    final cached = existingImageBytes.value;
    if (cached != null) {
      debugPrint(
        '[AiUpload] Reusing ${cached.length} cached saved-image bytes',
      );
      if (isClosed) return;
      _openMeasurement(imageBytes: cached);
      return;
    }

    debugPrint(
      '[AiUpload] Loading saved image bytes from '
      '${StorageService.describeDownloadUrl(savedUrl)}',
    );
    isPicking.value = true;
    final saved = await _storageService.downloadImageBytes(savedUrl);
    if (isClosed) return;
    isPicking.value = false;

    if (saved == null) {
      debugPrint('[AiUpload] Saved image byte download returned null');
      AppToast.say('Saved image could not be loaded. Please upload it again.');
      return;
    }

    debugPrint('[AiUpload] Saved image ready: ${saved.length} bytes');
    _openMeasurement(imageBytes: saved);
  }

  void _openMeasurement({Uint8List? imageBytes, String? imageUrl}) {
    Get.to<void>(
      () => MeasurementPage(
        imageBytes: imageBytes,
        imageUrl: imageUrl,
        plannedDate: plannedDate,
        eventId: eventId,
        eventName: eventName,
      ),
    );
  }
}
