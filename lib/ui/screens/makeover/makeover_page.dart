// The Makeover flow, opened from Home's floating Makeover button.
//
// Phase 3 of the work plan, reworked after the September 2026 feedback:
//   1. Brief     — your photo, what should change, and how (Describe · Style
//                  idol · Style twin · Weather · Trending)
//   2. Styling   — one item at a time (hair, clothes, shoes, accessories).
//                  Each result shows as soon as it exists; the user keeps it,
//                  redoes it, tweaks it, skips it or goes back. A new step
//                  only generates when the user presses "Style my ..."
//   3. Done      — save or share, find the pieces, or edit something
//
// Also opened from a saved look on Home to edit it ([editingPostId]), and
// from someone's post to copy it as a style twin ([initialTwinUrl]).
//
// There is no product catalogue here: people see themselves first and buy
// afterwards ("Find pieces", then "Get this look" in Phase 5).
import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../data/models/body_profile.dart';
import '../../../data/models/look_request.dart';
import '../../../data/models/look_session.dart';
import '../../../data/models/weather.dart';
import '../../../data/services/body_profile_service.dart';
import '../../../data/services/gallery_scanner.dart';
import '../../../data/services/look_generation_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/weather_service.dart';
import '../../../core/main_tab.dart';
import '../../../core/theme_provider.dart';
import '../../../data/style/style_catalogue.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/find_pieces_sheet.dart';
import '../../widgets/gallery_suggestions_strip.dart';
import '../../widgets/save_look_sheet.dart';
import '../main/main_screen.dart';
import 'widgets/look_you_love_picker.dart';
import 'widgets/look_done_view.dart';
import 'widgets/look_source_picker.dart';
import 'widgets/look_step_view.dart';
import 'widgets/makeover_controls.dart';
import 'widgets/makeover_views.dart';

enum _Stage { brief, styling, done }

class MakeoverPage extends StatefulWidget {
  const MakeoverPage({
    super.key,
    this.generationService,
    this.initialPhotoUrl,
    this.initialScope,
    this.loadWeather,
    this.editingPostId,
    this.initialTwinUrl,
    this.initialMethod,
    this.initialIdolName,
    this.loadBodyProfile,
  });

  /// Injected in tests; defaults to Gemini.
  final LookGenerationService? generationService;

  /// Skips loading the user's latest photo when given. When editing, this is
  /// the saved look.
  final String? initialPhotoUrl;

  /// Skips reading the saved makeover preference when given (tests).
  final LookScope? initialScope;

  /// Injected in tests; defaults to device location + WeatherService.
  final Future<Weather?> Function()? loadWeather;

  /// The saved look being edited, so saving can update it in place.
  final String? editingPostId;

  /// Starts on Style twin with this look to copy.
  final String? initialTwinUrl;

  /// Starts on this idea source, e.g. Style idol for "My Fashion Idols".
  final LookMethod? initialMethod;

  /// Starts on Style idol with this person filled in ("Style me like …"
  /// from My Fashion Idols).
  final String? initialIdolName;

  /// Injected in tests; defaults to the signed-in user's profile details.
  final Future<BodyProfile> Function()? loadBodyProfile;

  @override
  State<MakeoverPage> createState() => _MakeoverPageState();
}

class _MakeoverPageState extends State<MakeoverPage> {
  late final LookGenerationService _generator =
      widget.generationService ?? LookGenerationService();
  late final StorageService _storage = StorageService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _describeController = TextEditingController();
  final TextEditingController _idolController = TextEditingController();

  _Stage _stage = _Stage.brief;

  // Brief.
  String _photoUrl = '';
  bool _isLoadingPhoto = true;
  bool _isUploadingPhoto = false;
  // What should change. Unset until the user picks it: choosing is a
  // deliberate step before generating (October 2026 review, M-6).
  LookScope? _scope;
  LookMethod _method = LookMethod.describe;
  StyleArchetype? _archetype;
  StyleTrend? _trend;
  WeatherState _weather = const WeatherState();
  String _twinUrl = '';
  bool _isUploadingTwin = false;

  /// Profile details: the default photo, the face photo for idol and twin
  /// looks, and sizes to fit clothes to.
  late final Future<BodyProfile> _bodyProfile =
      (widget.loadBodyProfile ?? BodyProfileService().loadForCurrentUser)();
  BodyProfile _body = const BodyProfile();

  // Styling.
  LookRequest? _activeRequest;
  LookSession? _session;
  String _stepTweak = '';
  bool _isGenerating = false;

  /// Bumped to discard a generation the user has moved on from.
  int _runId = 0;
  int _elapsedSeconds = 0;
  Timer? _ticker;

  // Done.
  String _finalUrl = '';
  List<LookPart> _changedParts = const [];

  String _error = '';

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  bool get _isEditing => widget.editingPostId != null;

  @override
  void initState() {
    super.initState();
    _describeController.addListener(() => setState(() {}));
    _idolController.addListener(() => setState(() {}));
    if (widget.initialPhotoUrl case final url?) {
      _photoUrl = url;
      _isLoadingPhoto = false;
    } else {
      _loadPhoto();
    }
    _scope = widget.initialScope;
    unawaited(
      _bodyProfile.then((profile) {
        if (mounted) setState(() => _body = profile);
      }),
    );
    if (widget.initialMethod case final method?) _method = method;
    if (widget.initialIdolName case final idol? when idol.trim().isNotEmpty) {
      _idolController.text = idol.trim();
      _method = LookMethod.idol;
    }
    if (widget.initialTwinUrl case final url? when url.isNotEmpty) {
      _twinUrl = url;
      _method = LookMethod.twin;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _describeController.dispose();
    _idolController.dispose();
    super.dispose();
  }

  // ── Setup ───────────────────────────────────────────────────────────────

  Future<void> _loadPhoto() async {
    final userId = _userId;
    if (userId.isEmpty) {
      setState(() => _isLoadingPhoto = false);
      return;
    }
    try {
      // The full-body photo from profile details comes first; otherwise the
      // last photo the user used.
      final profilePhoto = (await _bodyProfile).fullBodyPhotoUrl;
      final existing = profilePhoto.isNotEmpty
          ? profilePhoto
          : await _storage.getLatestFullBodyImageUrl(userId);
      if (!mounted) return;
      setState(() => _photoUrl = existing ?? '');
    } on Exception catch (error) {
      debugPrint('Unable to load existing photo: $error');
    } finally {
      if (mounted) setState(() => _isLoadingPhoto = false);
    }
  }

  /// Picks an image and uploads it with [upload]. Returns its URL, or null
  /// when cancelled or unusable (with [_error] explaining why).
  Future<String?> _pickAndUpload(
    ImageSource source,
    Future<String> Function(Uint8List bytes, String userId) upload,
  ) async {
    final userId = _userId;
    if (userId.isEmpty) {
      setState(() => _error = 'Sign in to use your photos.');
      return null;
    }
    setState(() => _error = '');
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2000,
      );
      if (picked == null) return null;

      final bytes = await picked.readAsBytes();
      final problem = photoProblem(bytes.lengthInBytes);
      if (problem != null) {
        if (mounted) setState(() => _error = problem);
        return null;
      }
      return await upload(bytes, userId);
    } on Exception catch (error) {
      debugPrint('Unable to use photo: $error');
      if (mounted) setState(() => _error = 'We could not use that photo.');
      return null;
    }
  }

  /// A photo tapped in the gallery strip (E-5): read in full and uploaded
  /// only now, because the person chose it.
  Future<void> _useGalleryPhoto(GalleryPhoto photo) async {
    if (_isUploadingPhoto) return;
    final userId = _userId;
    if (userId.isEmpty) {
      setState(() => _error = 'Sign in to use your photos.');
      return;
    }
    setState(() {
      _isUploadingPhoto = true;
      _error = '';
    });
    String? url;
    try {
      final bytes = await photo.bytes();
      final problem = bytes == null
          ? 'We could not use that photo.'
          : photoProblem(bytes.lengthInBytes);
      if (problem != null) {
        if (mounted) setState(() => _error = problem);
      } else {
        url = await _storage.uploadFullBodyImageBytes(bytes!, userId);
      }
    } on Exception catch (error) {
      debugPrint('Unable to use gallery photo: $error');
      if (mounted) setState(() => _error = 'We could not use that photo.');
    }
    if (!mounted) return;
    setState(() {
      if (url != null) _photoUrl = url;
      _isUploadingPhoto = false;
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_isUploadingPhoto) return;
    setState(() => _isUploadingPhoto = true);
    final url = await _pickAndUpload(source, _storage.uploadFullBodyImageBytes);
    if (!mounted) return;
    setState(() {
      if (url != null) _photoUrl = url;
      _isUploadingPhoto = false;
    });
  }

  Future<void> _pickTwinFromPhotos() async {
    if (_isUploadingTwin) return;
    setState(() => _isUploadingTwin = true);
    final url = await _pickAndUpload(
      ImageSource.gallery,
      _storage.uploadStyleReferenceBytes,
    );
    if (!mounted) return;
    setState(() {
      if (url != null) _twinUrl = url;
      _isUploadingTwin = false;
    });
  }

  Future<void> _pickTwinFromCommunity() async {
    final url = await showLookYouLovePicker(context);
    if (url == null || !mounted) return;
    setState(() => _twinUrl = url);
  }

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

  void _selectScope(LookScope scope) {
    setState(() {
      _scope = scope;
      // A trend that no longer fits the scope would contradict the prompt.
      if (_trend case final trend? when !trend.fitsScope(scope)) {
        _trend = null;
      }
    });
  }

  void _selectMethod(LookMethod method) {
    setState(() => _method = method);
    if (method == LookMethod.weather &&
        _weather.weather == null &&
        !_weather.isLoading) {
      _fetchWeather();
    }
  }

  Future<void> _fetchWeather() async {
    setState(() => _weather = const WeatherState(isLoading: true));
    try {
      final weather = await (widget.loadWeather ?? _weatherHere)();
      if (!mounted) return;
      setState(() => _weather = WeatherState(weather: weather));
    } on Exception catch (error) {
      if (!mounted) return;
      setState(
        () => _weather = WeatherState(
          error: error.toString().replaceFirst('Exception: ', ''),
        ),
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

  LookSource get _source => switch (_method) {
    LookMethod.describe => DescribeSource(_describeController.text),
    LookMethod.idol => IdolSource(
      idolName: _idolController.text,
      archetype: _archetype,
    ),
    LookMethod.twin => TwinSource(imageUrl: _twinUrl),
    LookMethod.weather => WeatherSource(
      temperatureC: _weather.weather?.temperatureC,
      condition: _weather.weather?.condition ?? '',
    ),
    LookMethod.trending => TrendSource(_trend),
  };

  /// The request so far; null until the user has chosen what should change.
  LookRequest? get _request => switch (_scope) {
    final scope? => LookRequest(
      photoUrl: _photoUrl,
      scope: scope,
      source: _source,
      body: _body,
    ),
    null => null,
  };

  // ── Styling, one item at a time ─────────────────────────────────────────

  void _start() {
    final request = _request;
    if (request == null || !request.isReady) return;
    _activeRequest = request;
    _finalUrl = '';
    _changedParts = const [];
    _runSession(
      LookSession(originalUrl: request.photoUrl, parts: request.parts),
    );
  }

  void _runSession(LookSession session, {String tweak = ''}) {
    setState(() {
      _session = session;
      _stepTweak = tweak;
      _stage = _Stage.styling;
      _error = '';
    });
    _generateCurrent();
  }

  Future<void> _generateCurrent() async {
    final session = _session;
    final request = _activeRequest;
    final part = session?.currentPart;
    if (session == null || request == null || part == null) return;

    final runId = ++_runId;
    _ticker?.cancel();
    setState(() {
      _isGenerating = true;
      _elapsedSeconds = 0;
      _error = '';
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds += 1);
    });

    try {
      final look = await _generator.generate(
        request,
        part: part,
        baseImageUrl: session.baseUrl,
        tweak: _stepTweak,
      );
      if (!mounted || runId != _runId) return;
      setState(() => _session = _session?.withPending(look.imageUrl));
    } on LookGenerationException catch (error) {
      if (!mounted || runId != _runId) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted && runId == _runId) {
        _ticker?.cancel();
        setState(() => _isGenerating = false);
      }
    }
  }

  /// Drops any generation in flight; its result will be ignored.
  void _cancelGeneration() {
    _runId++;
    _ticker?.cancel();
    _isGenerating = false;
  }

  void _keep() {
    final session = _session;
    if (session == null || !session.hasPending || _isGenerating) return;
    _advance(session.keep());
  }

  void _skip() {
    final session = _session;
    if (session == null) return;
    _cancelGeneration();
    _advance(session.skip());
  }

  /// Moves to [next]. The new step waits for the user to press its "Style
  /// my ..." button: nothing is generated, and nothing is charged, until
  /// they ask.
  void _advance(LookSession next) {
    _stepTweak = '';
    if (next.isFinished) {
      _finish(next);
      return;
    }
    setState(() {
      _session = next;
      _error = '';
    });
  }

  void _undo() {
    final session = _session;
    if (session == null || !session.canUndo) return;
    setState(() {
      _cancelGeneration();
      _session = session.undo();
      _stepTweak = '';
      _error = '';
    });
  }

  /// Jumps to the step tapped in the progress strip.
  void _jumpTo(int index) {
    final session = _session;
    if (session == null || index == session.stepIndex) return;
    final next = session.jumpTo(index);
    if (index > session.stepIndex) {
      _cancelGeneration();
      _advance(next);
      return;
    }
    setState(() {
      _cancelGeneration();
      _session = next;
      _stepTweak = '';
      _error = '';
    });
  }

  Future<void> _tweakCurrent() async {
    final part = _session?.currentPart;
    if (part == null) return;
    final edit = await showLookEditSheet(context, fixedPart: part);
    if (edit == null || !mounted) return;
    _stepTweak = edit.note;
    _generateCurrent();
  }

  void _finish(LookSession session) {
    final done = session.finish();
    final changed = done.changedParts;
    setState(() {
      _cancelGeneration();
      _session = null;
      if (changed.isEmpty) {
        // Everything was skipped: return to where the user came from.
        _stage = _finalUrl.isEmpty ? _Stage.brief : _Stage.done;
        _error =
            'Nothing was changed. Keep an item you like, or try '
            'another idea.';
        return;
      }
      _finalUrl = done.baseUrl;
      _changedParts = [
        for (final part in LookPart.values)
          if (_changedParts.contains(part) || changed.contains(part)) part,
      ];
      _stage = _Stage.done;
      _error = '';
    });
  }

  // ── Done ────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    await saveLookToTimeline(
      context,
      imageUrl: _finalUrl,
      caption: _activeRequest?.caption ?? 'My new look',
      replacePostId: widget.editingPostId,
      avatarImageUrl: _photoUrl,
    );
  }

  Future<void> _editLook() async {
    final edit = await showLookEditSheet(
      context,
      initialPart: _changedParts.isEmpty ? LookPart.outfit : _changedParts.last,
    );
    if (edit == null || !mounted) return;
    _runSession(
      LookSession(originalUrl: _finalUrl, parts: [edit.part]),
      tweak: edit.note,
    );
  }

  void _startAgain() {
    final request = _activeRequest;
    if (request == null) return;
    _finalUrl = '';
    _changedParts = const [];
    _runSession(
      LookSession(originalUrl: request.photoUrl, parts: request.parts),
    );
  }

  // ── Back ────────────────────────────────────────────────────────────────

  Future<void> _handleBack() async {
    switch (_stage) {
      case _Stage.brief:
        Navigator.of(context).pop();
      case _Stage.styling:
        setState(() {
          _cancelGeneration();
          _session = null;
          _error = '';
          _stage = _finalUrl.isEmpty ? _Stage.brief : _Stage.done;
        });
      case _Stage.done:
        final discard = await _confirmDiscard();
        if (discard && mounted) setState(() => _stage = _Stage.brief);
    }
  }

  /// Leaves the makeover for a main tab, checking first when a look is in
  /// progress.
  Future<void> _openMainTab(int index) async {
    if (_stage != _Stage.brief && !await _confirmDiscard()) return;
    if (!mounted) return;
    MainScreen.selectTab(MainTab.fromIndex(index));
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave this look?'),
        content: const Text("It hasn't been saved yet."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final session = _session;

    return PopScope(
      canPop: _stage == _Stage.brief,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        drawer: AppDrawer(themeProvider: themeProvider),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MakeoverHeader(
              title: _title(session),
              onBack: _handleBack,
              trailing: _stage == _Stage.styling && session != null
                  ? TextButton(
                      key: const ValueKey('makeover_finish_now'),
                      onPressed: session.changedParts.isEmpty
                          ? null
                          : () => _finish(session),
                      style: TextButton.styleFrom(
                        foregroundColor: kMakeoverNavy,
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : null,
            ),
            Expanded(child: _buildStage(context, session)),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_stage == _Stage.brief) _buildGenerateBar(),
            CustomBottomNavigation(
              currentIndex: MainTab.home.index,
              onTap: _openMainTab,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStage(BuildContext context, LookSession? session) {
    return switch (_stage) {
      _Stage.brief => _buildBrief(context),
      _Stage.styling when session != null => LookStepView(
        session: session,
        isGenerating: _isGenerating,
        elapsedSeconds: _elapsedSeconds,
        errorMessage: _error,
        onKeep: _keep,
        onTryAgain: _generateCurrent,
        onTweak: _tweakCurrent,
        onSkip: _skip,
        onUndo: _undo,
        onJumpTo: _jumpTo,
        onGenerate: _generateCurrent,
      ),
      _Stage.styling => const SizedBox.shrink(),
      _Stage.done => LookDoneView(
        beforeUrl: _photoUrl,
        afterUrl: _finalUrl,
        changedParts: _changedParts,
        isEditingSavedLook: _isEditing,
        onSave: _save,
        onFindPieces: () => showFindPiecesSheet(context, parts: _changedParts),
        onEdit: _editLook,
        onNewIdea: () => setState(() => _stage = _Stage.brief),
        onStartAgain: _startAgain,
      ),
    };
  }

  String _title(LookSession? session) {
    if (_stage == _Stage.done) return 'Your look';
    if (_stage == _Stage.styling && session != null) {
      if (session.parts.length == 1) return session.parts.single.label;
      return 'Step ${session.stepIndex + 1} of ${session.parts.length}';
    }
    return _isEditing ? 'Edit look' : 'My New Look';
  }

  Widget _buildBrief(BuildContext context) {
    final scope = _scope;
    final trends = curatedTrends
        .where((trend) => scope == null || trend.fitsScope(scope))
        .toList();
    final steps = scope?.parts ?? const <LookPart>[];

    // Photo, then how (describe it, or a look you love), then what should
    // change: one clear path from top to bottom (October 2026 review, M-4).
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        MakeoverPhotoCard(
          photoUrl: _photoUrl,
          isLoading: _isLoadingPhoto || _isUploadingPhoto,
          isEditingLook: _isEditing,
          onUpload: _isUploadingPhoto
              ? null
              : () => _pickPhoto(ImageSource.gallery),
          onTakePhoto: _isUploadingPhoto
              ? null
              : () => _pickPhoto(ImageSource.camera),
        ),
        const SizedBox(height: 12),
        GallerySuggestionsStrip(
          onPick: _useGalleryPhoto,
          onOpenSettings: openAppSettings,
        ),
        const SizedBox(height: 28),
        const MakeoverSectionTitle('How do you want to create your look?'),
        const SizedBox(height: 14),
        LookSourcePicker(
          method: _method,
          onMethodChanged: _selectMethod,
          scope: scope ?? LookScope.fullLook,
          describeController: _describeController,
          idolController: _idolController,
          archetypes: styleArchetypes,
          selectedArchetype: _archetype,
          onArchetypeChanged: (archetype) =>
              setState(() => _archetype = archetype),
          twin: TwinState(
            imageUrl: _twinUrl,
            isUploading: _isUploadingTwin,
            onPickFromCommunity: _pickTwinFromCommunity,
            onPickFromPhotos: _pickTwinFromPhotos,
          ),
          trends: trends,
          selectedTrend: _trend,
          onTrendChanged: (trend) => setState(() => _trend = trend),
          weather: _weather,
          onRetryWeather: _fetchWeather,
        ),
        const SizedBox(height: 32),
        MakeoverSectionTitle(
          'What should change?',
          subtitle: steps.length > 1
              ? 'One item at a time: '
                    '${steps.map((part) => part.label).join(' · ')}'
              : 'Pick one before you generate.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final option in LookScope.values)
              MakeoverPill(
                key: ValueKey('look_scope_${option.name}'),
                label: option.label,
                selected: option == scope,
                onTap: () => _selectScope(option),
              ),
          ],
        ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 16),
          MakeoverErrorBanner(message: _error),
        ],
      ],
    );
  }

  Widget _buildGenerateBar() {
    final request = _request;
    final hint = _photoUrl.isEmpty
        ? 'Add your photo to continue'
        : !_source.isComplete
        ? switch (_method) {
            LookMethod.describe => 'Describe the look you want',
            LookMethod.idol => 'Name your style idol or pick a vibe',
            LookMethod.twin => 'Choose a look to copy',
            LookMethod.weather => 'Waiting for the weather',
            LookMethod.trending => 'Pick a trend',
          }
        : request == null
        ? 'Choose what should change'
        : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hint.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                hint,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          MakeoverPrimaryButton(
            key: const ValueKey('makeover_generate'),
            label: _isEditing ? 'Edit my look' : 'Generate my look',
            onPressed: request != null && request.isReady ? _start : null,
          ),
        ],
      ),
    );
  }
}
