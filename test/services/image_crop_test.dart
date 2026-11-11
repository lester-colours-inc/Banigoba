import 'package:banigoba/core/services/image_crop.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class _FakePicker extends ImagePicker {
  _FakePicker(this.result);

  final XFile? result;
  int calls = 0;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    calls++;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => ImageCrop.override = null);

  test('returns the cropped picture', () async {
    CropShape? seenShape;
    ImageCrop.override = (path, shape) async {
      seenShape = shape;
      return '/tmp/cropped.jpg';
    };
    final picker = _FakePicker(XFile('/tmp/look.jpg', name: 'look.jpg'));

    final result = await picker.pickAndCropImage(
      source: ImageSource.gallery,
      shape: CropShape.square,
    );

    expect(result?.path, '/tmp/cropped.jpg');
    expect(seenShape, CropShape.square);
  });

  test('backing out of the crop screen cancels the pick', () async {
    ImageCrop.override = (path, shape) async => null;
    final picker = _FakePicker(XFile('/tmp/look.jpg'));

    final result = await picker.pickAndCropImage(source: ImageSource.camera);

    expect(result, isNull);
  });

  test('cancelling the picker never opens the crop screen', () async {
    var cropCalls = 0;
    ImageCrop.override = (path, shape) async {
      cropCalls++;
      return path;
    };
    final picker = _FakePicker(null);

    final result = await picker.pickAndCropImage(source: ImageSource.gallery);

    expect(result, isNull);
    expect(cropCalls, 0);
  });

  test('uses the picture uncropped when the crop screen is missing', () async {
    ImageCrop.override = (path, shape) async =>
        throw MissingPluginException('no cropper');
    final picker = _FakePicker(XFile('/tmp/look.jpg'));

    final result = await picker.pickAndCropImage(source: ImageSource.gallery);

    expect(result?.path, '/tmp/look.jpg');
  });

  test('uses the picture uncropped when the crop screen fails', () async {
    ImageCrop.override = (path, shape) async =>
        throw PlatformException(code: 'crop_error');
    final picker = _FakePicker(XFile('/tmp/look.jpg'));

    final result = await picker.pickAndCropImage(source: ImageSource.gallery);

    expect(result?.path, '/tmp/look.jpg');
  });
}
