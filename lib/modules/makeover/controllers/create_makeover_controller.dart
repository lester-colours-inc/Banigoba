// The coordinated clothing-and-hair makeover journey: brief, generate, compare,
// refine, save (UI-04 to UI-09).
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:banigoba/core/services/image_crop.dart';
import 'package:banigoba/core/services/storage_service.dart';
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/makeover/models/makeover_job.dart';
import 'package:banigoba/modules/makeover/services/coordinated_makeover_service.dart';
import 'package:banigoba/modules/makeover/widgets/ai_photo_consent.dart';
import 'package:banigoba/modules/makeover/widgets/hair_goal_dialog.dart';
import 'package:banigoba/modules/makeover/widgets/try_on_product_picker.dart';
import 'package:banigoba/modules/wardrobe/widgets/save_look_sheet.dart';

/// Steps of the coordinated journey.
enum CreateStep { brief, generating, compare }

class CreateMakeoverController extends GetxController {
  CreateMakeoverController({
    CoordinatedMakeoverService? service,
    StorageService? storage,
    ImagePicker? picker,
  }) : _service = service ?? CoordinatedMakeoverService(),
       _storage = storage ?? StorageService(),
       _picker = picker ?? ImagePicker();

  final CoordinatedMakeoverService _service;
  final StorageService _storage;
  final ImagePicker _picker;

  final TextEditingController occasion = TextEditingController();
  final TextEditingController feeling = TextEditingController();
  final TextEditingController hair = TextEditingController();
  final TextEditingController modesty = TextEditingController();
  final TextEditingController exclusions = TextEditingController();

  final Rx<CreateStep> step = CreateStep.brief.obs;
  final RxString sourceImageUrl = ''.obs;
  final Rx<List<Map<String, dynamic>>> garments = Rx(const []);
  final Rxn<MakeoverJob> job = Rxn<MakeoverJob>();
  final RxInt selectedAlternative = 0.obs;
  final Rxn<MakeoverDomain> compareFocus = Rxn<MakeoverDomain>();
  final RxBool isBusy = false.obs;
  final RxBool isLoadingSource = true.obs;
  final RxString error = ''.obs;

  /// Bumped when the occasion or hair text changes, so the start button and
  /// the hair card follow what is typed.
  final RxInt typing = 0.obs;

  /// Follows the stored job while the server works on it, so each stage's
  /// progress shows as it happens.
  StreamSubscription<MakeoverJob?>? _progress;

  String get _userId => AppAuth.instance.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    occasion.addListener(_typed);
    hair.addListener(_typed);
    _loadExistingPhoto();
  }

  void _typed() => typing.value++;

  @override
  void onClose() {
    unawaited(_progress?.cancel());
    occasion.dispose();
    feeling.dispose();
    hair.dispose();
    modesty.dispose();
    exclusions.dispose();
    super.onClose();
  }

  void _followProgress(String jobId) {
    unawaited(_progress?.cancel());
    _progress = _service.watchJob(jobId).listen((update) {
      if (isClosed || update == null || !isBusy.value) return;
      job.value = update;
    });
  }

  void _stopFollowing() {
    unawaited(_progress?.cancel());
    _progress = null;
  }

  Future<void> _loadExistingPhoto() async {
    final userId = _userId;
    if (userId.isEmpty) {
      isLoadingSource.value = false;
      return;
    }
    try {
      final existing = await _storage.getLatestFullBodyImageUrl(userId);
      if (isClosed) return;
      sourceImageUrl.value = existing ?? '';
    } on Exception catch (e) {
      debugPrint('Unable to load existing photo: $e');
    }
    if (!isClosed) isLoadingSource.value = false;
  }

  void goTo(CreateStep next) => step.value = next;

  void selectAlternative(int index) => selectedAlternative.value = index;

  void focusOn(MakeoverDomain? domain) => compareFocus.value = domain;

  void clearGarments() => garments.value = const [];

  // ── UI-05 capture ───────────────────────────────────────────────────────

  Future<void> pickPhoto(ImageSource source) async {
    final userId = _userId;
    if (userId.isEmpty || isBusy.value) return;

    isBusy.value = true;
    error.value = '';

    try {
      final picked = await _picker.pickAndCropImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2000,
      );
      if (picked == null) {
        if (!isClosed) isBusy.value = false;
        return;
      }

      final bytes = await picked.readAsBytes();
      final validation = validateSourcePhoto(bytes.lengthInBytes);
      if (validation != null) {
        if (isClosed) return;
        error.value = validation;
        isBusy.value = false;
        return;
      }

      final url = await _storage.uploadFullBodyImageBytes(bytes, userId);
      if (isClosed) return;
      sourceImageUrl.value = url;
      isBusy.value = false;
    } on Exception catch (e) {
      if (isClosed) return;
      error.value = 'We could not use that photo. $e';
      isBusy.value = false;
    }
  }

  /// Basic pre-generation check (AI-001). Returns an actionable message, or
  /// null when the photo is usable. The wording describes the file, never the
  /// person.
  @visibleForTesting
  static String? validateSourcePhoto(int sizeInBytes) {
    const minBytes = 20 * 1024;
    const maxBytes = 12 * 1024 * 1024;
    if (sizeInBytes < minBytes) {
      return 'That image is too small to style. Try a clearer, larger photo.';
    }
    if (sizeInBytes > maxBytes) {
      return 'That image is larger than 12 MB. Try a smaller file.';
    }
    return null;
  }

  Future<void> chooseGarments() async {
    final context = Get.context;
    if (context == null) return;
    final selected = await showTryOnProductPicker(
      context,
      initialProducts: garments.value,
      outfitLabel: 'Your look',
    );
    if (selected == null || isClosed) return;
    garments.value = selected;
  }

  MakeoverIntent buildIntent() {
    final avoid = exclusions.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    return MakeoverIntent(
      occasion: occasion.text.trim(),
      desiredFeeling: feeling.text.trim(),
      hairPrompt: hair.text.trim(),
      garments: garments.value,
      modestyPreference: modesty.text.trim(),
      exclusions: avoid,
    );
  }

  bool get canStart =>
      sourceImageUrl.value.isNotEmpty &&
      !buildIntent().isEmpty &&
      !isBusy.value;

  String get startButtonLabel {
    if (sourceImageUrl.value.isEmpty) return 'Add a photo to continue';
    return switch ((buildIntent().wantsClothing, buildIntent().wantsHair)) {
      (true, true) => 'Create clothing and hair look',
      (true, false) => 'Create clothing look',
      (false, true) => 'Create hair look',
      (false, false) => 'Choose a clothing or hair change',
    };
  }

  // ── UI-06 generation ────────────────────────────────────────────────────

  Future<void> start() async {
    final context = Get.context;
    if (context == null || !await ensureAiPhotoConsent(context) || isClosed) {
      return;
    }
    if (isBusy.value) return;
    final intent = buildIntent();

    isBusy.value = true;
    error.value = '';

    try {
      final created = await _service.createJob(
        sourceImageUrl: sourceImageUrl.value,
        intent: intent,
      );
      if (isClosed) return;
      job.value = created;
      step.value = CreateStep.generating;
      _followProgress(created.id);

      final finished = await _service.run(created);
      _stopFollowing();
      if (isClosed) return;
      job.value = finished;
      isBusy.value = false;
      selectedAlternative.value = 0;
      step.value = finished.alternatives.isEmpty
          ? CreateStep.generating
          : CreateStep.compare;
    } on StateError catch (e) {
      if (isClosed) return;
      error.value = e.message;
      isBusy.value = false;
      step.value = CreateStep.brief;
    } on Exception catch (e) {
      if (isClosed) return;
      error.value = 'Something went wrong. $e';
      isBusy.value = false;
    }
  }

  // ── UI-08 refine one domain ─────────────────────────────────────────────

  Future<void> refine(MakeoverDomain domain) async {
    final context = Get.context;
    if (context == null || !await ensureAiPhotoConsent(context) || isClosed) {
      return;
    }
    final current = job.value;
    if (current == null || isBusy.value) return;

    isBusy.value = true;
    error.value = '';
    step.value = CreateStep.generating;

    _followProgress(current.id);
    try {
      final refined = await _service.refine(
        current,
        domain: domain,
        updatedIntent: buildIntent(),
      );
      _stopFollowing();
      if (isClosed) return;
      job.value = refined;
      isBusy.value = false;
      selectedAlternative.value = 0;
      step.value = refined.alternatives.isEmpty
          ? CreateStep.generating
          : CreateStep.compare;
    } on StateError catch (e) {
      if (isClosed) return;
      error.value = e.message;
      isBusy.value = false;
      step.value = CreateStep.compare;
    } on Exception catch (e) {
      if (isClosed) return;
      error.value = 'Refinement failed. $e';
      isBusy.value = false;
      step.value = CreateStep.compare;
    }
  }

  Future<void> chooseGarmentsThenRefine() async {
    final context = Get.context;
    if (context == null) return;
    final selected = await showTryOnProductPicker(
      context,
      initialProducts: garments.value,
      outfitLabel: 'Your look',
    );
    if (selected == null || selected.isEmpty || isClosed) return;
    garments.value = selected;
    await refine(MakeoverDomain.clothing);
  }

  Future<void> editHairThenRefine() async {
    final updated = await askHairGoal(hair.text);
    if (updated == null || updated.trim().isEmpty || isClosed) return;
    hair.text = updated.trim();
    await refine(MakeoverDomain.hair);
  }

  // ── UI-09 save and visibility ───────────────────────────────────────────

  Future<void> saveAndChooseVisibility(MakeoverAlternative alternative) async {
    final context = Get.context;
    if (context == null) return;
    final text = occasion.text.trim();
    await saveLookToTimeline(
      context,
      imageUrl: alternative.imageUrl,
      caption: text.isEmpty ? 'My makeover' : 'My $text look',
    );
  }
}
