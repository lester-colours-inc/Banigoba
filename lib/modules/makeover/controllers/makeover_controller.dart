// The Makeover flow, opened from Home's floating Makeover button:
//   1. Brief   — your photo, what should change, and how
//   2. Styling — one item at a time; keep, redo, tweak, skip or go back
//   3. Done    — save or share, find the pieces, or edit something
//
// Also opened from a saved look on Home to edit it ([editingPostId]), and
// from someone's post to copy it as a style twin ([initialTwinUrl]).
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:banigoba/core/main_tab.dart';
import 'package:banigoba/core/services/image_crop.dart';
import 'package:banigoba/core/services/storage_service.dart';
import 'package:banigoba/core/style/style_catalogue.dart';
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/home/models/weather.dart';
import 'package:banigoba/modules/home/services/weather_service.dart';
import 'package:banigoba/modules/home/views/main_screen.dart';
import 'package:banigoba/modules/makeover/models/look_session.dart';
import 'package:banigoba/modules/makeover/services/look_generation_service.dart';
import 'package:banigoba/modules/makeover/widgets/discard_look_dialog.dart';
import 'package:banigoba/modules/makeover/widgets/find_pieces_sheet.dart';
import 'package:banigoba/modules/makeover/widgets/look_done_view.dart';
import 'package:banigoba/modules/makeover/widgets/look_source_picker.dart';
import 'package:banigoba/modules/makeover/widgets/look_you_love_picker.dart';
import 'package:banigoba/modules/makeover/widgets/makeover_views.dart';
import 'package:banigoba/modules/profile_details/models/body_profile.dart';
import 'package:banigoba/modules/profile_details/services/body_profile_service.dart';
import 'package:banigoba/modules/provider/models/look_request.dart';
import 'package:banigoba/modules/makeover/services/web_look_search.dart';
import 'package:banigoba/modules/makeover/widgets/web_look_results.dart';
import 'package:banigoba/modules/wardrobe/widgets/save_look_sheet.dart';

enum MakeoverPhase { brief, styling, done }

class MakeoverController extends GetxController {
  MakeoverController({
    required this.confirmAiUse,
    required this.context,
    LookGenerationService? generationService,
    this.initialPhotoUrl,
    this.initialScope,
    this.loadWeather,
    this.editingPostId,
    this.initialTwinUrl,
    this.initialMethod,
    this.initialIdolName,
    this.loadBodyProfile,
  }) : _generator = generationService ?? LookGenerationService();

  /// Asks before photos go to the AI (App Store 5.1.2).
  final Future<bool> Function(BuildContext context) confirmAiUse;

  /// The page's context, for the sheets and dialogs the flow opens.
  final BuildContext Function() context;

  final LookGenerationService _generator;
  final String? initialPhotoUrl;
  final LookScope? initialScope;
  final Future<Weather?> Function()? loadWeather;
  final String? editingPostId;
  final String? initialTwinUrl;
  final LookMethod? initialMethod;
  final String? initialIdolName;
  final Future<BodyProfile> Function()? loadBodyProfile;

  final StorageService _storage = StorageService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController describe = TextEditingController();
  final TextEditingController idol = TextEditingController();

  final Rx<MakeoverPhase> phase = MakeoverPhase.brief.obs;

  // Brief.
  final RxString photoUrl = ''.obs;
  final RxBool isLoadingPhoto = true.obs;
  final RxBool isUploadingPhoto = false.obs;

  /// What should change. Unset until the user picks it: choosing is a
  /// deliberate step before generating (October 2026 review, M-6).
  final Rxn<LookScope> scope = Rxn<LookScope>();
  final Rx<LookMethod> method = LookMethod.describe.obs;
  final Rxn<StyleArchetype> archetype = Rxn<StyleArchetype>();
  final Rxn<StyleTrend> trend = Rxn<StyleTrend>();
  final Rx<WeatherState> weather = const WeatherState().obs;
  final RxString twinUrl = ''.obs;
  final RxBool isUploadingTwin = false.obs;

  /// A look the style idol wore, found on the web and copied to the user's
  /// style references.
  final RxString idolLookUrl = ''.obs;

  /// Profile details: the default photo, the face photo for idol and twin
  /// looks, and sizes to fit clothes to.
  final Rx<BodyProfile> body = const BodyProfile().obs;

  // Styling.
  LookRequest? _activeRequest;
  final Rxn<LookSession> session = Rxn<LookSession>();
  String _stepTweak = '';
  final RxBool isGenerating = false.obs;

  /// Bumped to discard a generation the user has moved on from.
  int _runId = 0;
  final RxInt elapsedSeconds = 0.obs;
  Timer? _ticker;

  // Done.
  final RxString finalUrl = ''.obs;
  final Rx<List<LookPart>> changedParts = Rx(const []);

  final RxString error = ''.obs;

  /// Bumped when the describe or idol text changes, so what depends on the
  /// request follows the typing.
  final RxInt typing = 0.obs;

  late final Future<BodyProfile> _bodyProfile =
      (loadBodyProfile ?? BodyProfileService().loadForCurrentUser)();

  String get _userId => AppAuth.instance.currentUser?.uid ?? '';

  bool get isEditing => editingPostId != null;

  /// Opened from "Try on" on a look: the look to copy is already chosen, so
  /// the page shows it first and drops the other idea sources.
  bool get isTryOn => (initialTwinUrl ?? '').isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    describe.addListener(() => typing.value++);
    idol.addListener(() => typing.value++);
    if (initialPhotoUrl case final url?) {
      photoUrl.value = url;
      isLoadingPhoto.value = false;
    } else {
      _loadPhoto();
    }
    scope.value = initialScope;
    unawaited(
      _bodyProfile.then((profile) {
        if (!isClosed) body.value = profile;
      }),
    );
    if (initialMethod case final chosen?) method.value = chosen;
    if (initialIdolName case final name? when name.trim().isNotEmpty) {
      idol.text = name.trim();
      method.value = LookMethod.idol;
    }
    if (initialTwinUrl case final url? when url.isNotEmpty) {
      twinUrl.value = url;
      method.value = LookMethod.twin;
    }
  }

  @override
  void onClose() {
    _ticker?.cancel();
    describe.dispose();
    idol.dispose();
    super.onClose();
  }

  // ── Setup ───────────────────────────────────────────────────────────────

  Future<void> _loadPhoto() async {
    final userId = _userId;
    if (userId.isEmpty) {
      isLoadingPhoto.value = false;
      return;
    }
    try {
      // The full-body photo from profile details comes first; otherwise the
      // last photo the user used.
      final profilePhoto = (await _bodyProfile).fullBodyPhotoUrl;
      final existing = profilePhoto.isNotEmpty
          ? profilePhoto
          : await _storage.getLatestFullBodyImageUrl(userId);
      if (isClosed) return;
      photoUrl.value = existing ?? '';
    } on Exception catch (e) {
      debugPrint('Unable to load existing photo: $e');
    } finally {
      if (!isClosed) isLoadingPhoto.value = false;
    }
  }

  /// Picks an image and uploads it with [upload]. Returns its URL, or null
  /// when cancelled or unusable (with [error] explaining why).
  Future<String?> _pickAndUpload(
    ImageSource source,
    Future<String> Function(Uint8List bytes, String userId) upload,
  ) async {
    final userId = _userId;
    if (userId.isEmpty) {
      error.value = 'Sign in to use your photos.';
      return null;
    }
    error.value = '';
    try {
      final picked = await _picker.pickAndCropImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2000,
      );
      if (picked == null) return null;

      final bytes = await picked.readAsBytes();
      final problem = photoProblem(bytes.lengthInBytes);
      if (problem != null) {
        if (!isClosed) error.value = problem;
        return null;
      }
      return await upload(bytes, userId);
    } on Exception catch (e) {
      debugPrint('Unable to use photo: $e');
      if (!isClosed) error.value = 'We could not use that photo.';
      return null;
    }
  }

  Future<void> pickPhoto(ImageSource source) async {
    if (isUploadingPhoto.value) return;
    isUploadingPhoto.value = true;
    final url = await _pickAndUpload(source, _storage.uploadFullBodyImageBytes);
    if (isClosed) return;
    if (url != null) photoUrl.value = url;
    isUploadingPhoto.value = false;
  }

  Future<void> pickTwinFromPhotos() async {
    if (isUploadingTwin.value) return;
    isUploadingTwin.value = true;
    final url = await _pickAndUpload(
      ImageSource.gallery,
      _storage.uploadStyleReferenceBytes,
    );
    if (isClosed) return;
    if (url != null) twinUrl.value = url;
    isUploadingTwin.value = false;
  }

  Future<void> pickTwinFromCommunity() async {
    final url = await showLookYouLovePicker(context());
    if (url == null || isClosed) return;
    twinUrl.value = url;
  }

  /// Searches the web for the idol's looks, starting from the typed name.
  Future<void> pickIdolLookFromWeb() async {
    final name = idol.text.trim();
    final url = await showWebLookSearch(
      context(),
      initialQuery: idolLookQuery(name),
      title: name.isEmpty ? 'Find your idol on the web' : "$name's looks",
    );
    if (url == null || isClosed) return;
    idolLookUrl.value = url;
  }

  void clearIdolLook() => idolLookUrl.value = '';

  /// Returns a message when a photo file is unusable, or null. It describes
  /// the file, never the person.
  static String? photoProblem(int sizeInBytes) {
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

  // ── Choices ─────────────────────────────────────────────────────────────

  void selectScope(LookScope chosen) {
    scope.value = chosen;
    // A trend that no longer fits the scope would contradict the prompt.
    if (trend.value case final current? when !current.fitsScope(chosen)) {
      trend.value = null;
    }
  }

  void selectMethod(LookMethod chosen) {
    method.value = chosen;
    if (chosen == LookMethod.weather &&
        weather.value.weather == null &&
        !weather.value.isLoading) {
      fetchWeather();
    }
  }

  void selectArchetype(StyleArchetype? chosen) => archetype.value = chosen;

  void selectTrend(StyleTrend? chosen) => trend.value = chosen;

  Future<void> fetchWeather() async {
    weather.value = const WeatherState(isLoading: true);
    try {
      final found = await (loadWeather ?? _weatherHere)();
      if (isClosed) return;
      weather.value = WeatherState(weather: found);
    } on Exception catch (e) {
      if (isClosed) return;
      weather.value = WeatherState(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  static Future<Weather?> _weatherHere() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Turn on location to style for the weather.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Allow location access to style for the weather.');
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
    return WeatherService().fetchOptionalWeather(
      '${position.latitude},${position.longitude}',
    );
  }

  LookSource get source {
    typing.value; // follow the describe and idol text
    return switch (method.value) {
      LookMethod.describe => DescribeSource(describe.text),
      LookMethod.idol => IdolSource(
        idolName: idol.text,
        archetype: archetype.value,
        imageUrl: idolLookUrl.value,
      ),
      LookMethod.twin => TwinSource(imageUrl: twinUrl.value),
      LookMethod.weather => WeatherSource(
        temperatureC: weather.value.weather?.temperatureC,
        condition: weather.value.weather?.condition ?? '',
      ),
      LookMethod.trending => TrendSource(trend.value),
    };
  }

  /// The request so far; null until the user has chosen what should change.
  LookRequest? get request => switch (scope.value) {
    final chosen? => LookRequest(
      photoUrl: photoUrl.value,
      scope: chosen,
      source: source,
      body: body.value,
    ),
    null => null,
  };

  /// Why the generate button is waiting, or '' when it is ready.
  String get generateHint {
    final current = request;
    if (photoUrl.value.isEmpty) return 'Add your photo to continue';
    if (!source.isComplete) {
      return switch (method.value) {
        LookMethod.describe => 'Describe the look you want',
        LookMethod.idol => 'Name your style idol or pick a vibe',
        LookMethod.twin => 'Choose a look to copy',
        LookMethod.weather => 'Waiting for the weather',
        LookMethod.trending => 'Pick a trend',
      };
    }
    return current == null ? 'Choose what should change' : '';
  }

  // ── Styling, one item at a time ─────────────────────────────────────────

  void start() {
    final current = request;
    if (current == null || !current.isReady) return;
    _activeRequest = current;
    finalUrl.value = '';
    changedParts.value = const [];
    _runSession(
      LookSession(originalUrl: current.photoUrl, parts: current.parts),
    );
  }

  void _runSession(LookSession next, {String tweak = ''}) {
    session.value = next;
    _stepTweak = tweak;
    phase.value = MakeoverPhase.styling;
    error.value = '';
    generateCurrent();
  }

  Future<void> generateCurrent() async {
    final current = session.value;
    final active = _activeRequest;
    final part = current?.currentPart;
    if (current == null || active == null || part == null) return;
    if (!await confirmAiUse(context()) || isClosed) return;

    final runId = ++_runId;
    _ticker?.cancel();
    isGenerating.value = true;
    elapsedSeconds.value = 0;
    error.value = '';
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed) elapsedSeconds.value += 1;
    });

    try {
      final look = await _generator.generate(
        active,
        part: part,
        baseImageUrl: current.baseUrl,
        tweak: _stepTweak,
      );
      if (isClosed || runId != _runId) return;
      session.value = session.value?.withPending(look.imageUrl);
    } on LookGenerationException catch (e) {
      if (isClosed || runId != _runId) return;
      error.value = e.message;
    } finally {
      if (!isClosed && runId == _runId) {
        _ticker?.cancel();
        isGenerating.value = false;
      }
    }
  }

  /// Drops any generation in flight; its result will be ignored.
  void _cancelGeneration() {
    _runId++;
    _ticker?.cancel();
    isGenerating.value = false;
  }

  void keep() {
    final current = session.value;
    if (current == null || !current.hasPending || isGenerating.value) return;
    _advance(current.keep());
  }

  void skip() {
    final current = session.value;
    if (current == null) return;
    _cancelGeneration();
    _advance(current.skip());
  }

  /// Moves to [next]. The new step waits for the user to press its "Style
  /// my ..." button: nothing is generated, and nothing is charged, until
  /// they ask.
  void _advance(LookSession next) {
    _stepTweak = '';
    if (next.isFinished) {
      finish(next);
      return;
    }
    session.value = next;
    error.value = '';
  }

  void undo() {
    final current = session.value;
    if (current == null || !current.canUndo) return;
    _cancelGeneration();
    session.value = current.undo();
    _stepTweak = '';
    error.value = '';
  }

  /// Jumps to the step tapped in the progress strip.
  void jumpTo(int index) {
    final current = session.value;
    if (current == null || index == current.stepIndex) return;
    final next = current.jumpTo(index);
    if (index > current.stepIndex) {
      _cancelGeneration();
      _advance(next);
      return;
    }
    _cancelGeneration();
    session.value = next;
    _stepTweak = '';
    error.value = '';
  }

  Future<void> tweakCurrent() async {
    final part = session.value?.currentPart;
    if (part == null) return;
    final edit = await showLookEditSheet(context(), fixedPart: part);
    if (edit == null || isClosed) return;
    _stepTweak = edit.note;
    generateCurrent();
  }

  void finish(LookSession current) {
    final done = current.finish();
    final changed = done.changedParts;
    _cancelGeneration();
    session.value = null;
    if (changed.isEmpty) {
      // Everything was skipped: return to where the user came from.
      phase.value = finalUrl.value.isEmpty
          ? MakeoverPhase.brief
          : MakeoverPhase.done;
      error.value =
          'Nothing was changed. Keep an item you like, or try another idea.';
      return;
    }
    finalUrl.value = done.baseUrl;
    changedParts.value = [
      for (final part in LookPart.values)
        if (changedParts.value.contains(part) || changed.contains(part)) part,
    ];
    phase.value = MakeoverPhase.done;
    error.value = '';
  }

  // ── Done ────────────────────────────────────────────────────────────────

  Future<void> save() async {
    await saveLookToTimeline(
      context(),
      imageUrl: finalUrl.value,
      caption: _activeRequest?.caption ?? 'My new look',
      replacePostId: editingPostId,
      avatarImageUrl: photoUrl.value,
    );
  }

  void findPieces() =>
      showFindPiecesSheet(context(), parts: changedParts.value);

  Future<void> editLook() async {
    final edit = await showLookEditSheet(
      context(),
      initialPart: changedParts.value.isEmpty
          ? LookPart.outfit
          : changedParts.value.last,
    );
    if (edit == null || isClosed) return;
    _runSession(
      LookSession(originalUrl: finalUrl.value, parts: [edit.part]),
      tweak: edit.note,
    );
  }

  void newIdea() => phase.value = MakeoverPhase.brief;

  void startAgain() {
    final active = _activeRequest;
    if (active == null) return;
    finalUrl.value = '';
    changedParts.value = const [];
    _runSession(LookSession(originalUrl: active.photoUrl, parts: active.parts));
  }

  // ── Back ────────────────────────────────────────────────────────────────

  Future<void> handleBack() async {
    switch (phase.value) {
      case MakeoverPhase.brief:
        Get.back<void>();
      case MakeoverPhase.styling:
        _cancelGeneration();
        session.value = null;
        error.value = '';
        phase.value = finalUrl.value.isEmpty
            ? MakeoverPhase.brief
            : MakeoverPhase.done;
      case MakeoverPhase.done:
        final discard = await confirmDiscardLook();
        if (discard && !isClosed) phase.value = MakeoverPhase.brief;
    }
  }

  /// Leaves the makeover for a main tab, checking first when a look is in
  /// progress.
  Future<void> openMainTab(int index) async {
    if (phase.value != MakeoverPhase.brief && !await confirmDiscardLook()) {
      return;
    }
    if (isClosed) return;
    MainScreen.selectTab(MainTab.fromIndex(index));
    Get.until((route) => route.isFirst);
  }

  /// The header title for the current phase.
  String get title {
    final current = session.value;
    if (phase.value == MakeoverPhase.done) return 'Your look';
    if (phase.value == MakeoverPhase.styling && current != null) {
      if (current.parts.length == 1) return current.parts.single.label;
      return 'Step ${current.stepIndex + 1} of ${current.parts.length}';
    }
    if (isEditing) return 'Edit look';
    return isTryOn ? 'Try on this look' : 'My New Look';
  }
}
