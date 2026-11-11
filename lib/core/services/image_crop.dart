// Every picture the user picks goes through a crop screen before it's used,
// so they can trim it to just the outfit, face or flyer they mean.
// Call sites use `picker.pickAndCropImage(...)` in place of `pickImage`.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// The shape the crop box starts as.
enum CropShape {
  /// Any shape; the user can pick a preset ratio or drag freely.
  free,

  /// A square, for profile photos.
  square,
}

/// Crops the file at [path]; returns the cropped file's path, or null when
/// the user backs out of the crop screen.
typedef CropImageFn = Future<String?> Function(String path, CropShape shape);

const _brandNavy = Color(0xFF13104A);

class ImageCrop {
  ImageCrop._();

  /// Swapped in tests, where there is no native crop screen.
  @visibleForTesting
  static CropImageFn? override;

  static Future<String?> crop(String path, CropShape shape) {
    return (override ?? _cropNatively)(path, shape);
  }

  static Future<String?> _cropNatively(String path, CropShape shape) async {
    final isSquare = shape == CropShape.square;
    final presets = isSquare
        ? const [CropAspectRatioPreset.square]
        : const [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ];
    final cropped = await ImageCropper().cropImage(
      sourcePath: path,
      aspectRatio: isSquare
          ? const CropAspectRatio(ratioX: 1, ratioY: 1)
          : null,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop photo',
          toolbarColor: _brandNavy,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: _brandNavy,
          lockAspectRatio: isSquare,
          initAspectRatio: isSquare
              ? CropAspectRatioPreset.square
              : CropAspectRatioPreset.original,
          aspectRatioPresets: presets,
          cropStyle: isSquare ? CropStyle.circle : CropStyle.rectangle,
        ),
        IOSUiSettings(
          title: 'Crop photo',
          doneButtonTitle: 'Use photo',
          aspectRatioLockEnabled: isSquare,
          resetAspectRatioEnabled: !isSquare,
          aspectRatioPresets: presets,
          cropStyle: isSquare ? CropStyle.circle : CropStyle.rectangle,
        ),
      ],
    );
    return cropped?.path;
  }
}

extension PickAndCrop on ImagePicker {
  /// [pickImage], then the crop screen. Null when the user cancels either
  /// step. If the crop screen can't open (no native support on this
  /// platform), the picked picture is used as it is.
  Future<XFile?> pickAndCropImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    CropShape shape = CropShape.free,
  }) async {
    final picked = await pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
      preferredCameraDevice: preferredCameraDevice,
    );
    if (picked == null) return null;

    try {
      final croppedPath = await ImageCrop.crop(picked.path, shape);
      if (croppedPath == null) return null;
      return XFile(croppedPath);
    } on MissingPluginException {
      return picked;
    } on PlatformException catch (error) {
      debugPrint('Crop screen failed, using the photo uncropped: $error');
      return picked;
    }
  }
}
