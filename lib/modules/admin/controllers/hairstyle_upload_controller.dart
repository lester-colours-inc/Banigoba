// Uploading or editing a catalogue hairstyle: the choices, the picture and
// the save.
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:banigoba/core/services/image_crop.dart';
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/admin/models/hairstyle_catalog_options.dart';
import 'package:banigoba/modules/admin/views/hairstyle_catalog_upload_page.dart';
import 'package:banigoba/modules/makeover/services/hairstyle_service.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class HairstyleUploadController extends GetxController {
  HairstyleUploadController({
    this.docId,
    this.initialData,
    this.curatorMode = false,
    HairstyleService? service,
  }) : _service = service ?? HairstyleService();

  final String? docId;
  final Map<String, dynamic>? initialData;
  final bool curatorMode;
  final HairstyleService _service;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController name = TextEditingController();

  final Rxn<XFile> image = Rxn<XFile>();
  final Rxn<Uint8List> previewBytes = Rxn<Uint8List>();
  final RxBool saving = false.obs;
  final RxString length = hairCatalogLengths.first.obs;
  final RxString gender = hairCatalogGenders.first.obs;
  final RxString hairType = hairCatalogTypes.first.obs;
  final Rx<Set<String>> styleTypes = Rx({hairCatalogStyleTypes.first});
  final RxString cutTypeGroup = hairCatalogCutTypes.keys.first.obs;
  final RxString cutType = hairCatalogCutTypes.values.first.first.obs;
  final Rx<Set<String>> occasions = Rx({hairCatalogOccasions.first});
  final RxString colour = hairCatalogColours.first.obs;
  final RxString maintenanceLevel = hairCatalogMaintenanceLevels.first.obs;
  final RxString existingImageUrl = ''.obs;

  bool get isEditing => docId?.isNotEmpty == true;

  @override
  void onInit() {
    super.onInit();
    final data = initialData;
    if (data == null) return;

    name.text = (data['name'] ?? '').toString();
    existingImageUrl.value = (data['imageUrl'] ?? '').toString();
    length.value = _optionOrDefault(data['length'], hairCatalogLengths);
    gender.value = _optionOrDefault(data['gender'], hairCatalogGenders);
    hairType.value = _optionOrDefault(data['hairType'], hairCatalogTypes);
    styleTypes.value = _selectedOptions(
      values: data['styleTypes'],
      fallback: data['styleType'],
      options: hairCatalogStyleTypes,
    );
    cutTypeGroup.value = _optionOrDefault(
      data['cutTypeGroup'],
      hairCatalogCutTypes.keys.toList(),
    );
    cutType.value = _optionOrDefault(
      data['cutType'],
      hairCatalogCutTypes[cutTypeGroup.value] ??
          hairCatalogCutTypes.values.first,
    );
    occasions.value = _selectedOptions(
      values: data['occasions'],
      fallback: data['occasion'],
      options: hairCatalogOccasions,
    );
    colour.value = _optionOrDefault(data['colour'], hairCatalogColours);
    maintenanceLevel.value = _optionOrDefault(
      data['maintenanceLevel'],
      hairCatalogMaintenanceLevels,
    );
  }

  @override
  void onClose() {
    name.dispose();
    super.onClose();
  }

  /// Choosing a group resets the cut to the group's first.
  void chooseCutGroup(String value) {
    cutTypeGroup.value = value;
    cutType.value = hairCatalogCutTypes[value]!.first;
  }

  Future<void> pickImage() async {
    final picked = await _picker.pickAndCropImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1800,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (isClosed) return;
    image.value = picked;
    previewBytes.value = bytes;
  }

  Future<void> save() async {
    if (saving.value) return;
    final bytes = previewBytes.value;
    if (!isEditing && (image.value == null || bytes == null)) {
      AppToast.say('Choose a hairstyle image first.');
      return;
    }
    if (styleTypes.value.isEmpty || occasions.value.isEmpty) {
      AppToast.say('Choose at least one style and one occasion.');
      return;
    }

    final user = AppAuth.instance.currentUser;
    if (user == null) {
      AppToast.say('Sign in to upload hairstyles.');
      return;
    }

    saving.value = true;
    try {
      final styles = _ordered(styleTypes.value, hairCatalogStyleTypes);
      final occasionList = _ordered(occasions.value, hairCatalogOccasions);
      final id = docId;
      if (isEditing && id != null) {
        await _service.updateCatalogHairstyle(
          docId: id,
          userId: user.uid,
          imageBytes: bytes,
          filename: image.value?.name,
          length: length.value,
          gender: gender.value,
          hairType: hairType.value,
          styleTypes: styles,
          cutTypeGroup: cutTypeGroup.value,
          cutType: cutType.value,
          occasions: occasionList,
          colour: colour.value,
          maintenanceLevel: maintenanceLevel.value,
          name: name.text,
        );
      } else {
        await _service.uploadCatalogHairstyle(
          userId: user.uid,
          imageBytes: bytes!,
          filename: image.value!.name,
          length: length.value,
          gender: gender.value,
          hairType: hairType.value,
          styleTypes: styles,
          cutTypeGroup: cutTypeGroup.value,
          cutType: cutType.value,
          occasions: occasionList,
          colour: colour.value,
          maintenanceLevel: maintenanceLevel.value,
          name: name.text,
        );
      }
      if (isClosed) return;
      AppToast.say(isEditing ? 'Hairstyle updated.' : 'Hairstyle uploaded.');
      if (isEditing) {
        Get.back<void>();
      } else {
        image.value = null;
        previewBytes.value = null;
        name.clear();
      }
    } catch (error) {
      if (!isClosed) AppToast.say('Hairstyle upload failed: $error');
    } finally {
      if (!isClosed) saving.value = false;
    }
  }

  void openEditor(String id, Map<String, dynamic> data) {
    Get.to<void>(
      () => TemporaryHairstyleUploadPage(
        docId: id,
        initialData: data,
        curatorMode: curatorMode,
      ),
    );
  }

  static String _optionOrDefault(Object? value, Iterable<String> options) {
    final text = value?.toString() ?? '';
    return options.contains(text) ? text : options.first;
  }

  static Set<String> _selectedOptions({
    required Object? values,
    required Object? fallback,
    required List<String> options,
  }) {
    final selected = stringListFromDynamic(
      values,
    ).where(options.contains).toSet();
    if (selected.isNotEmpty) return selected;

    final fallbackText = fallback?.toString() ?? '';
    if (options.contains(fallbackText)) return {fallbackText};
    return {options.first};
  }

  static List<String> _ordered(Set<String> selected, List<String> options) {
    return options.where(selected.contains).toList();
  }
}
