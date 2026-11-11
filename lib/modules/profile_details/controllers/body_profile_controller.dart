// My Profile Details: loading the saved profile, the form (sizes,
// measurements, notes), uploading photos, saving, and leaving with unsaved
// changes.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:banigoba/core/services/image_crop.dart';
import 'package:banigoba/modules/profile_details/models/body_profile.dart';
import 'package:banigoba/modules/profile_details/services/body_profile_service.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

typedef ProfileImagePicker =
    Future<Uint8List?> Function(ImageSource source, BodyPhoto photo);

enum PhotoAction { camera, gallery, remove }

class BodyProfileController extends GetxController {
  BodyProfileController({BodyProfileStore? store, this.pickImage})
    : _store = store ?? SupabaseBodyProfileStore();

  static const int maxPhotoBytes = 12 * 1024 * 1024;

  final BodyProfileStore _store;

  /// Injected in tests; defaults to the device camera and gallery.
  final ProfileImagePicker? pickImage;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController shoeSize = TextEditingController();
  final TextEditingController notes = TextEditingController();
  final Map<BodyMeasurement, TextEditingController> measurements = {
    for (final measurement in BodyMeasurement.values)
      measurement: TextEditingController(),
  };

  /// The profile as last saved. Photos are always saved here straight away.
  final Rx<BodyProfile> saved = const BodyProfile().obs;
  final RxString clothingSize = ''.obs;
  final RxSet<BodyPhoto> uploading = <BodyPhoto>{}.obs;
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxBool hasUnsavedChanges = false.obs;
  final RxString loadError = ''.obs;

  // Bumped on every edit, so the progress card follows what is typed.
  final RxInt edits = 0.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    shoeSize.dispose();
    notes.dispose();
    for (final controller in measurements.values) {
      controller.dispose();
    }
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    loadError.value = '';
    try {
      final profile = await _store.load();
      if (isClosed) return;
      _fillForm(profile);
      saved.value = profile;
    } on Exception catch (error) {
      debugPrint('Unable to load profile details: $error');
      if (!isClosed) loadError.value = 'Your details could not be loaded.';
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  void _fillForm(BodyProfile profile) {
    clothingSize.value = profile.clothingSize;
    shoeSize.text = profile.shoeSize;
    notes.text = profile.notes;
    for (final entry in measurements.entries) {
      final value = profile[entry.key];
      entry.value.text = value == null ? '' : formatNumber(value);
    }
    hasUnsavedChanges.value = false;
  }

  /// Any edit: marks the form changed and updates the progress.
  void markChanged([Object? _]) {
    hasUnsavedChanges.value = true;
    edits.value++;
  }

  void selectClothingSize(String size, {required bool selected}) {
    clothingSize.value = selected ? size : '';
    markChanged();
  }

  /// The form as a profile, keeping the saved photos. Call after validating.
  BodyProfile formProfile() {
    final shoe = shoeSize.text.trim();
    return saved.value.copyWith(
      clothingSize: clothingSize.value,
      shoeSize: shoe.isEmpty ? '' : BodyProfile.normalizeShoeSize(shoe),
      measurements: {
        for (final entry in measurements.entries)
          entry.key: ?entry.key.parse(entry.value.text),
      },
      notes: notes.text.trim(),
    );
  }

  Future<void> save() async {
    if (isSaving.value) return;
    if (!(formKey.currentState?.validate() ?? false)) {
      _say('Check the highlighted details.');
      return;
    }
    final profile = formProfile();
    isSaving.value = true;
    try {
      await _store.save(profile);
      if (isClosed) return;
      saved.value = profile;
      hasUnsavedChanges.value = false;
      _say('Your details are saved.');
      // pop, not maybePop: PopScope has not rebuilt with canPop yet.
      if (Get.key.currentState?.canPop() ?? false) {
        Get.back<BodyProfile>(result: profile);
      }
    } on Exception catch (error) {
      debugPrint('Unable to save profile details: $error');
      _say('Your details could not be saved. Please try again.');
    } finally {
      if (!isClosed) isSaving.value = false;
    }
  }

  // ── Photos ──────────────────────────────────────────────────────────────

  Future<void> changePhoto(BodyPhoto photo) async {
    final context = Get.context;
    if (context == null) return;
    final hasPhoto = saved.value.photoUrl(photo).isNotEmpty;
    final action = await showModalBottomSheet<PhotoAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, PhotoAction.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, PhotoAction.gallery),
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove photo'),
                onTap: () => Navigator.pop(sheetContext, PhotoAction.remove),
              ),
          ],
        ),
      ),
    );
    if (action == null || isClosed) return;

    if (action == PhotoAction.remove) {
      await _savePhoto(photo, '');
      return;
    }
    final source = action == PhotoAction.camera
        ? ImageSource.camera
        : ImageSource.gallery;
    await _uploadPhoto(photo, source);
  }

  Future<void> _uploadPhoto(BodyPhoto photo, ImageSource source) async {
    final Uint8List? bytes;
    try {
      bytes = await (pickImage ?? _pickFromDevice)(source, photo);
    } on Exception catch (error) {
      debugPrint('Unable to pick profile photo: $error');
      _say('We could not open your photos.');
      return;
    }
    if (bytes == null || isClosed) return;
    if (bytes.lengthInBytes > maxPhotoBytes) {
      _say('That photo is too large. Choose one under 12 MB.');
      return;
    }

    uploading.add(photo);
    try {
      final url = await _store.uploadPhoto(photo, bytes);
      await _savePhoto(photo, url);
    } on Exception catch (error) {
      debugPrint('Unable to upload profile photo: $error');
      _say('Your photo could not be uploaded. Please try again.');
    } finally {
      if (!isClosed) uploading.remove(photo);
    }
  }

  /// Saves only the photo, so unsaved form edits stay unsaved.
  Future<void> _savePhoto(BodyPhoto photo, String url) async {
    final previousUrl = saved.value.photoUrl(photo);
    final updated = saved.value.withPhoto(photo, url);
    try {
      await _store.save(updated);
    } on Exception catch (error) {
      debugPrint('Unable to save profile photo: $error');
      _say('Your photo could not be saved. Please try again.');
      return;
    }
    if (isClosed) return;
    saved.value = updated;
    if (previousUrl.isNotEmpty && previousUrl != url) {
      unawaited(_store.deletePhoto(previousUrl));
    }
  }

  Future<Uint8List?> _pickFromDevice(
    ImageSource source,
    BodyPhoto photo,
  ) async {
    final picked = await ImagePicker().pickAndCropImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
      preferredCameraDevice: photo == BodyPhoto.face
          ? CameraDevice.front
          : CameraDevice.rear,
    );
    return picked?.readAsBytes();
  }

  // ── Leaving ─────────────────────────────────────────────────────────────

  Future<void> confirmLeave() async {
    final discard = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'Your sizes and measurements have not been saved yet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Get.back<bool>(result: true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && !isClosed) {
      hasUnsavedChanges.value = false;
      Get.back<void>();
    }
  }

  void _say(String message) {
    if (isClosed) return;
    AppToast.say(message);
  }
}
