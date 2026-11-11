// The add / edit product form: every field, the size rows, image choices,
// validation and the upload + save.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/services/storage_service.dart';
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/core/supabase/rows.dart';
import 'package:banigoba/modules/shop/models/size_inventory_entry.dart';
import 'package:banigoba/modules/shop/services/product_service.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/modules/wardrobe/models/fit_check.dart';
import 'package:banigoba/modules/wardrobe/models/piece_details.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';
import 'package:banigoba/modules/profile_details/models/body_profile.dart';

class ProductFormController extends GetxController {
  ProductFormController({this.docId, this.existingData})
    : name = TextEditingController(text: existingData?['name'] ?? ''),
      price = TextEditingController(
        text: ((existingData?['price'] as num?)?.toDouble() ?? 0)
            .toStringAsFixed(2),
      ),
      stock = TextEditingController(
        text: ((existingData?['stock'] as num?)?.toInt() ?? 0).toString(),
      ),
      category = ((existingData?['category'] ?? 'tops') as String).obs,
      subcategory = ((existingData?['subcategory'] ?? 'none') as String).obs,
      styleTag =
          ((existingData?['styleTag'] ?? existingData?['style'] ?? 'casual')
                  as String)
              .obs,
      gender = ((existingData?['gender'] ?? 'unisex') as String).obs,
      colours = List<String>.from(existingData?['colours'] ?? []).obs,
      weatherTags = List<String>.from(existingData?['weatherTags'] ?? []).obs,
      functionalTags = List<String>.from(
        existingData?['functionalTags'] ?? [],
      ).obs,
      existingImageUrl = ((existingData?['imageUrl'] ?? '') as String).obs,
      existingBackImageUrl = (existingData?['backImageUrl'] ?? '')
          .toString()
          .obs {
    final details = PieceDetails.fromMap(existingData);
    shoulder = TextEditingController(text: details.shoulderMeasurement);
    heightMeasurement = TextEditingController(text: details.heightMeasurement);
    linenType = TextEditingController(text: details.linenType);
    madeWhere = TextEditingController(text: details.madeWhere);
    otherDetails.assignAll([
      for (final detail in details.otherDetails)
        TextEditingController(text: detail),
    ]);
    sizeEntries.assignAll(_sizeEntriesFor(existingData ?? const {}));
  }

  final String? docId;
  final Map<String, dynamic>? existingData;

  bool get isEditing => docId != null;

  static const List<String> availableColours = [
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
  static const List<String> weatherOptions = [
    'hot',
    'mild',
    'cool',
    'cold',
    'rainy',
  ];
  static const List<String> functionalOptions = [
    'waterproof',
    'breathable',
    'insulated',
    'windproof',
  ];
  static const List<String> genderOptions = ['male', 'female', 'unisex'];
  static const List<String> styleOptions = [
    'casual',
    'afrochic',
    'corporate',
    'streetwear',
    'glamour',
  ];
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

  // Preset sizes speed up entry while still allowing custom labels in the
  // editable size rows.
  static const List<String> suggestedSizes = [
    'XXS',
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'XXXL',
    'UK 4',
    'UK 6',
    'UK 8',
    'UK 10',
    'UK 12',
    'UK 14',
    'UK 16',
    'UK 18',
    'UK 20',
    'UK 22',
    'UK 24',
  ];

  // Shoes are sold by UK shoe size, which is what buyers save on their
  // profile, so they get their own suggestions.
  static const List<String> suggestedShoeSizes = [
    'UK 3',
    'UK 4',
    'UK 5',
    'UK 6',
    'UK 7',
    'UK 8',
    'UK 9',
    'UK 10',
    'UK 11',
    'UK 12',
  ];

  final String userId = AppAuth.instance.currentUser?.uid ?? '';
  final ProductService _products = ProductService();

  final TextEditingController name;
  final TextEditingController price;
  final TextEditingController stock;
  late final TextEditingController shoulder;
  late final TextEditingController heightMeasurement;
  late final TextEditingController linenType;
  late final TextEditingController madeWhere;
  final RxList<TextEditingController> otherDetails =
      <TextEditingController>[].obs;
  final RxList<SizeInventoryEntry> sizeEntries = <SizeInventoryEntry>[].obs;

  final RxString category;
  final RxString subcategory;
  final RxString styleTag;
  final RxString gender;
  final RxList<String> colours;
  final RxList<String> weatherTags;
  final RxList<String> functionalTags;

  final Rxn<File> selectedImage = Rxn<File>();
  final RxString existingImageUrl;
  final Rxn<File> selectedBackImage = Rxn<File>();
  final RxString existingBackImageUrl;

  @override
  void onClose() {
    name.dispose();
    price.dispose();
    stock.dispose();
    shoulder.dispose();
    heightMeasurement.dispose();
    linenType.dispose();
    madeWhere.dispose();
    for (final c in otherDetails) {
      c.dispose();
    }
    for (final entry in sizeEntries) {
      entry.dispose();
    }
    super.onClose();
  }

  void setCategory(String value) {
    category.value = value;
    subcategory.value = categoryData[value]![0];
  }

  void toggle(RxList<String> list, String value, {required bool on}) {
    if (on) {
      list.add(value);
    } else {
      list.remove(value);
    }
  }

  void addDetail() => otherDetails.add(TextEditingController());

  void removeDetail(int index) => otherDetails.removeAt(index).dispose();

  void addSize() {
    final used = sizeEntries
        .map((e) => e.sizeController.text.trim().toUpperCase())
        .toSet();
    final nextSize =
        (category.value == 'shoes' ? suggestedShoeSizes : suggestedSizes)
            .firstWhere((size) => !used.contains(size), orElse: () => '');
    sizeEntries.add(
      SizeInventoryEntry(size: nextSize, quantity: nextSize.isEmpty ? 0 : 1),
    );
  }

  void removeSize(int index) => sizeEntries.removeAt(index).dispose();

  void removeBackPhoto() {
    selectedBackImage.value = null;
    existingBackImageUrl.value = '';
  }

  List<SizeInventoryEntry> _sizeEntriesFor(Map<String, dynamic> data) {
    final inventory = _sizeInventoryFor(data);
    final chart = SizeChart.fromProduct(data);
    return [
      for (final entry in inventory.entries)
        SizeInventoryEntry(
          size: entry.key,
          quantity: entry.value,
          measures: chart.sizes[entry.key] ?? const {},
        ),
    ];
  }

  static Map<String, int> _sizeInventoryFor(Map<String, dynamic> data) {
    final raw = data['sizeInventory'];
    if (raw is! Map) return <String, int>{};
    final inventory = <String, int>{};
    raw.forEach((key, value) {
      final size = key.toString().trim().toUpperCase();
      final quantity = value is num
          ? value.toInt()
          : int.tryParse(value.toString().trim()) ?? 0;
      if (size.isNotEmpty) inventory[size] = quantity;
    });
    return inventory;
  }

  Map<String, int> _sizeInventoryFromEntries() {
    final inventory = <String, int>{};
    for (final entry in sizeEntries) {
      final size = entry.sizeController.text.trim().toUpperCase();
      final quantity = int.tryParse(entry.quantityController.text.trim()) ?? -1;
      if (size.isNotEmpty && quantity >= 0) inventory[size] = quantity;
    }
    return inventory;
  }

  /// The size chart typed into the form: only sizes with a valid size label
  /// and at least one measurement.
  SizeChart _sizeChartFromEntries() {
    final sizes = <String, Map<BodyMeasurement, double>>{};
    for (final entry in sizeEntries) {
      final size = entry.sizeController.text.trim().toUpperCase();
      if (size.isEmpty) continue;
      final measures = <BodyMeasurement, double>{};
      for (final part in kChartParts) {
        final text = entry.measureControllers[part]!.text.trim().replaceAll(
          ',',
          '.',
        );
        final cm = double.tryParse(text);
        if (cm != null && cm > 0) measures[part] = cm;
      }
      if (measures.isNotEmpty) sizes[size] = measures;
    }
    return SizeChart(sizes);
  }

  Future<void> submit() async {
    final sizeInventory = _sizeInventoryFromEntries();
    // Duplicate or malformed size rows would make checkout stock checks
    // unreliable, so validate before saving.
    final hasInvalidSizes =
        sizeEntries.any((entry) {
          final quantity = int.tryParse(entry.quantityController.text.trim());
          return entry.sizeController.text.trim().isEmpty ||
              quantity == null ||
              quantity < 0;
        }) ||
        sizeInventory.length != sizeEntries.length;
    final stockCount = sizeInventory.isNotEmpty
        ? sizeInventory.values.fold<int>(0, (total, q) => total + q)
        : int.tryParse(stock.text) ?? -1;
    if ((selectedImage.value == null && !isEditing) ||
        name.text.isEmpty ||
        double.tryParse(price.text) == null ||
        stockCount < 0 ||
        hasInvalidSizes ||
        colours.isEmpty) {
      AppToast.say('Add an image, name, valid price, inventory, and colour.');
      return;
    }
    Get.dialog<void>(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    try {
      debugPrint(
        '[ProductUpload] Submit started: isEditing=$isEditing, '
        'userId=$userId, hasSelectedImage=${selectedImage.value != null}, '
        'docId=$docId',
      );
      var imageUrl = existingImageUrl.value;
      var rawImageUrl = (existingData?['rawImageUrl'] ?? '') as String;

      final picked = selectedImage.value;
      if (picked != null) {
        debugPrint('[ProductUpload] Uploading selected image: ${picked.path}');
        final uploaded = await _products.uploadCatalogProductImage(
          userId: userId,
          image: picked,
          customFilename: name.text,
        );
        imageUrl = uploaded;
        rawImageUrl = uploaded;
        debugPrint(
          '[ProductUpload] Image upload returned URL: '
          '${imageUrl.split('?').first}',
        );
        if (imageUrl.isEmpty) {
          throw Exception('Storage returned an empty image URL');
        }
      }

      // The optional back photo goes up as it is (no background removal): it
      // is only a reference for the turn-around view.
      var backImageUrl = existingBackImageUrl.value;
      final back = selectedBackImage.value;
      if (back != null) {
        backImageUrl = await StorageService().uploadProductImageBytes(
          await back.readAsBytes(),
          userId,
          filename: 'back_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      final chart = _sizeChartFromEntries();
      final data = <String, dynamic>{
        'uploaderId': userId,
        'name': name.text,
        'price': double.parse(price.text),
        'stock': stockCount,
        'imageUrl': imageUrl,
        'rawImageUrl': rawImageUrl,
        if (backImageUrl.isNotEmpty)
          'backImageUrl': backImageUrl
        else if (isEditing)
          'backImageUrl': kRemoveField,
        'category': category.value,
        'subcategory': subcategory.value == 'none' ? null : subcategory.value,
        'styleTag': styleTag.value,
        'colours': colours.toList(),
        'gender': gender.value,
        'weatherTags': weatherTags.toList(),
        'functionalTags': functionalTags.toList(),
        if (sizeInventory.isNotEmpty)
          'sizeInventory': sizeInventory
        else if (isEditing)
          'sizeInventory': kRemoveField,
        if (!chart.isEmpty)
          'sizeChart': chart.toMap()
        else if (isEditing)
          'sizeChart': kRemoveField,
        ...PieceDetails.fromControllerText(
          shoulderMeasurement: shoulder.text,
          heightMeasurement: heightMeasurement.text,
          linenType: linenType.text,
          madeWhere: madeWhere.text,
          otherDetails: otherDetails.map((c) => c.text),
        ).toMap(),
      };

      debugPrint('[ProductUpload] Loading seller profile.');
      final seller = await ProfileService().get(userId);
      final shop = Map<String, dynamic>.from(
        seller['shop'] as Map? ?? const {},
      );
      data['shopName'] = (shop['name'] ?? seller['displayName'] ?? 'Boutique')
          .toString();
      debugPrint(
        '[ProductUpload] Saving product document: isEditing=$isEditing, '
        'shopName=${data['shopName']}, imageUrl=${imageUrl.split('?').first}',
      );

      final id = docId;
      if (id != null) {
        await _products.updateCatalogProduct(id, data);
      } else {
        await _products.addProduct(data);
      }
      debugPrint('[ProductUpload] Product document saved.');

      if (!isClosed) {
        Get.back<void>(); // Close loading
        Get.back<void>(); // Close sheet
        AppToast.say(
          isEditing
              ? 'Product successfully updated!'
              : 'Product added to your boutique!',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[ProductUpload] Product save failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!isClosed) {
        Get.back<void>();
        AppToast.say('Action failed: $e');
      }
    }
  }
}
