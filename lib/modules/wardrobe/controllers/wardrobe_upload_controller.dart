// The "Upload to Wardrobe" form: the photo, what the AI suggests from it, the
// piece's details, and saving it.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:banigoba/core/services/image_crop.dart';
import 'package:banigoba/core/utils/garment_colour.dart';
import 'package:banigoba/modules/makeover/widgets/ai_photo_consent.dart';
import 'package:banigoba/modules/shop/services/product_service.dart';
import 'package:banigoba/modules/wardrobe/models/piece_details.dart';
import 'package:banigoba/modules/wardrobe/services/garment_tagger.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class WardrobeUploadController extends GetxController {
  WardrobeUploadController({
    required this.userId,
    ProductService? productService,
    GarmentTagger? tagger,
    ImagePicker? picker,
  }) : _productService = productService ?? ProductService(),
       _tagger = tagger ?? ServerGarmentTagger(),
       _picker = picker ?? ImagePicker();

  static const Map<String, List<String>> categoryData = {
    'accessories': ['none', 'caps', 'glasses', 'hats'],
    'bottoms': ['none', 'jeans', 'joggers', 'leggings', 'shorts', 'skirts'],
    'dresses': ['none'],
    'outerwear': ['none', 'blazers', 'jackets'],
    'shoes': ['none', 'boots', 'flats', 'heels', 'sandals', 'sneakers'],
    'tops': [
      'none',
      'hoodies',
      'polo shirts',
      'shirts',
      'sweatshirts',
      't-shirts',
      'tank tops',
    ],
    'other': ['none'],
  };
  static const availableColours = [
    'black',
    'white',
    'grey',
    'blue',
    'red',
    'green',
    'yellow',
    'orange',
    'pink',
    'purple',
    'brown',
    'beige',
  ];
  static const weatherTagOptions = ['hot', 'mild', 'cool', 'cold', 'rainy'];
  static const functionalTagOptions = [
    'waterproof',
    'breathable',
    'insulated',
    'windproof',
  ];
  static const genderOptions = ['male', 'female', 'unisex'];
  static const visibilityOptions = ['private', 'public'];
  static const styleOptions = [
    'casual',
    'afrochic',
    'corporate',
    'streetwear',
    'glamour',
  ];

  final String userId;
  final ProductService _productService;
  final GarmentTagger _tagger;
  final ImagePicker _picker;

  final TextEditingController name = TextEditingController();
  final TextEditingController shoulders = TextEditingController();
  final TextEditingController length = TextEditingController();

  final RxString visibility = 'private'.obs;
  final RxString category = 'tops'.obs;
  final RxString subcategory = 'none'.obs;
  final RxString styleTag = 'casual'.obs;
  final RxString gender = 'unisex'.obs;
  final RxString size = ''.obs;
  final RxList<String> colours = <String>[].obs;
  final RxList<String> weatherTags = <String>[].obs;
  final RxList<String> functionalTags = <String>[].obs;
  final Rxn<File> image = Rxn<File>();

  /// Colours picked from the photo, until the user changes them (W-3).
  final RxBool coloursFromPhoto = false.obs;

  /// The AI's suggestion from the photo, while it is working and once used.
  final RxBool tagging = false.obs;
  final RxBool taggedFromPhoto = false.obs;

  @override
  void onClose() {
    name.dispose();
    shoulders.dispose();
    length.dispose();
    super.onClose();
  }

  void setCategory(String value) {
    category.value = value;
    subcategory.value = categoryData[value]![0];
  }

  void selectSize(String option, {required bool selected}) =>
      size.value = selected ? option : '';

  void toggleColour(String colour, {required bool selected}) {
    coloursFromPhoto.value = false;
    _toggle(colours, colour, selected);
  }

  void toggleWeather(String tag, {required bool selected}) =>
      _toggle(weatherTags, tag, selected);

  void toggleFunctional(String tag, {required bool selected}) =>
      _toggle(functionalTags, tag, selected);

  void _toggle(RxList<String> list, String value, bool selected) {
    if (selected) {
      list.add(value);
    } else {
      list.remove(value);
    }
  }

  /// Picks a photo, suggests its colours, then lets the AI fill in the rest.
  Future<void> pickPhoto() async {
    final picked = await _pickImageSource();
    if (picked == null) return;
    image.value = picked;
    // Suggest the colours from the photo, unless the user has already chosen
    // some.
    final found = await coloursFromFile(picked);
    if (!isClosed && found.isNotEmpty && colours.isEmpty) {
      colours.addAll(found);
      coloursFromPhoto.value = true;
    }
    // Then let the AI fill in the rest from the photo. Only fields the person
    // has not touched are filled.
    if (!_tagger.isConfigured || isClosed) return;
    // Photos go to the AI only with permission (5.1.2).
    final context = Get.context;
    if (context == null || !context.mounted) return;
    if (!await ensureAiPhotoConsent(context) || isClosed) return;
    tagging.value = true;
    final tags = await _tagger.tag(await picked.readAsBytes());
    if (isClosed) return;
    tagging.value = false;
    if (tags == null) return;
    if (name.text.trim().isEmpty && tags.name.isNotEmpty) {
      name.text = tags.name;
    }
    if (category.value == 'tops' && subcategory.value == 'none') {
      if (tags.category != null) category.value = tags.category!;
      subcategory.value = tags.subcategory ?? 'none';
    }
    if (styleTag.value == 'casual' && tags.styleTag != null) {
      styleTag.value = tags.styleTag!;
    }
    if (gender.value == 'unisex' && tags.gender != null) {
      gender.value = tags.gender!;
    }
    if (weatherTags.isEmpty) weatherTags.addAll(tags.weatherTags);
    if (functionalTags.isEmpty) functionalTags.addAll(tags.functionalTags);
    if ((colours.isEmpty || coloursFromPhoto.value) &&
        tags.colours.isNotEmpty) {
      colours.assignAll(tags.colours);
      coloursFromPhoto.value = true;
    }
    taggedFromPhoto.value = true;
  }

  /// Camera or gallery, then crop.
  Future<File?> _pickImageSource() async {
    final source = await Get.bottomSheet<ImageSource>(
      SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Gallery'),
              onTap: () => Get.back<ImageSource>(result: ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () => Get.back<ImageSource>(result: ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return null;
    final XFile? picked = await _picker.pickAndCropImage(source: source);
    return picked == null ? null : File(picked.path);
  }

  Future<void> upload() async {
    final photo = image.value;
    if (photo == null || name.text.isEmpty || colours.isEmpty) {
      AppToast.say(
        'Missing info (ensure image, name, and at least one colour)',
      );
      return;
    }
    final context = Get.context;
    if (context == null || !context.mounted) return;
    if (!await ensureAiPhotoConsent(context) || isClosed) return;
    Get.dialog<void>(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    try {
      // Process image with background remover API using item name as filename
      final urls = await _productService.removeBackground(
        photo,
        customFilename: name.text,
      );
      final imageUrl = urls['processed_url'] ?? '';
      final rawImageUrl = urls['raw_url'] ?? '';

      if (imageUrl.isEmpty) {
        throw Exception('API returned empty processed image URL');
      }

      // Save the piece to the wardrobe
      await _productService.uploadUserProduct(
        userId: userId,
        name: name.text,
        imageUrl: imageUrl,
        rawImageUrl: rawImageUrl,
        category: category.value,
        subcategory: subcategory.value == 'none' ? null : subcategory.value,
        styleTag: styleTag.value,
        colours: colours.toList(),
        gender: gender.value,
        visibility: visibility.value,
        weatherTags: weatherTags.toList(),
        functionalTags: functionalTags.toList(),
        size: size.value,
        details: PieceDetails.fromControllerText(
          shoulderMeasurement: shoulders.text,
          heightMeasurement: length.text,
          linenType: '',
          madeWhere: '',
          otherDetails: const [],
        ),
      );
      if (isClosed) return;
      // The progress dialog, then the form.
      Get.back<void>();
      Get.back<void>();
      AppToast.say('Uploaded successfully!');
    } catch (e) {
      if (isClosed) return;
      Get.back<void>();
      AppToast.say('Failed: $e');
    }
  }
}
