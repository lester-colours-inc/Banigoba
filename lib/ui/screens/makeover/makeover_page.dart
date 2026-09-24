// The Makeover flow, opened from Home's floating Makeover button.
//
// Phase 3 of the work plan, top to bottom on one screen:
//   1. Your photo      — upload or take one (photo comes first)
//   2. What changes?   — Full look · Outfit · Hair · Top · Bottom
//   3. How?            — Describe · Style icon · Weather · Trending
//   4. Create my look  — one image, shown as soon as it exists
//   5. Save            — to My Timeline, or shared (save_look_sheet.dart)
//
// There is no product catalogue here: people see themselves first and buy
// afterwards ("Get this look", Phase 5).
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/look_request.dart';
import '../../../data/models/style_preferences.dart';
import '../../../data/models/weather.dart';
import '../../../data/services/look_generation_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/weather_service.dart';
import '../../../data/style/style_catalogue.dart';
import '../../widgets/save_look_sheet.dart';
import 'widgets/look_source_picker.dart';
import 'widgets/makeover_views.dart';

enum _MakeoverStep { edit, generating, result }

class MakeoverPage extends StatefulWidget {
  const MakeoverPage({
    super.key,
    this.generationService,
    this.initialPhotoUrl,
    this.initialScope,
    this.loadWeather,
  });

  /// Injected in tests; defaults to Gemini.
  final LookGenerationService? generationService;

  /// Skips loading the user's latest photo when given (tests).
  final String? initialPhotoUrl;

  /// Skips reading the saved makeover preference when given (tests).
  final LookScope? initialScope;

  /// Injected in tests; defaults to device location + WeatherService.
  final Future<Weather?> Function()? loadWeather;

  @override
  State<MakeoverPage> createState() => _MakeoverPageState();
}

class _MakeoverPageState extends State<MakeoverPage> {
  static const Color _navy = Color(0xFF0D0140);

  late final LookGenerationService _generator =
      widget.generationService ?? LookGenerationService();
  late final StorageService _storage = StorageService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _describeController = TextEditingController();

  _MakeoverStep _step = _MakeoverStep.edit;
  String _photoUrl = '';
  bool _isLoadingPhoto = true;
  bool _isUploadingPhoto = false;
  LookScope _scope = LookScope.fullLook;
  LookMethod _method = LookMethod.describe;
  StyleArchetype? _archetype;
  StyleTrend? _trend;
  WeatherState _weather = const WeatherState();
  GeneratedLook? _result;
  String _error = '';
  int _elapsedSeconds = 0;
  Timer? _ticker;

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _describeController.addListener(() => setState(() {}));
    if (widget.initialPhotoUrl case final url?) {
      _photoUrl = url;
      _isLoadingPhoto = false;
    } else {
      _loadPhoto();
    }
    if (widget.initialScope case final scope?) {
      _scope = scope;
    } else {
      _loadDefaultScope();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _describeController.dispose();
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
      final existing = await _storage.getLatestFullBodyImageUrl(userId);
      if (!mounted) return;
      setState(() => _photoUrl = existing ?? '');
    } on Exception catch (error) {
      debugPrint('Unable to load existing photo: $error');
    } finally {
      if (mounted) setState(() => _isLoadingPhoto = false);
    }
  }

  /// Defaults the scope to the user's saved preference, if any.
  Future<void> _loadDefaultScope() async {
    final userId = _userId;
    if (userId.isEmpty) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final focus = MakeoverFocus.fromValue(snapshot.data()?['makeoverFocus']);
      if (!mounted || focus == null) return;
      setState(() => _scope = LookScope.fromFocus(focus));
    } on FirebaseException catch (error) {
      debugPrint('Unable to load makeover preference: ${error.code}');
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final userId = _userId;
    if (userId.isEmpty || _isUploadingPhoto) return;

    setState(() {
      _isUploadingPhoto = true;
      _error = '';
    });
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2000,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final problem = photoProblem(bytes.lengthInBytes);
      if (problem != null) {
        if (mounted) setState(() => _error = problem);
        return;
      }
      final url = await _storage.uploadFullBodyImageBytes(bytes, userId);
      if (mounted) setState(() => _photoUrl = url);
    } on Exception catch (error) {
      debugPrint('Unable to use photo: $error');
      if (mounted) setState(() => _error = 'We could not use that photo.');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
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
    LookMethod.styleIcon => ArchetypeSource(_archetype),
    LookMethod.weather => WeatherSource(
      temperatureC: _weather.weather?.temperatureC,
      condition: _weather.weather?.condition ?? '',
    ),
    LookMethod.trending => TrendSource(_trend),
  };

  LookRequest get _request =>
      LookRequest(photoUrl: _photoUrl, scope: _scope, source: _source);

  // ── Generation ──────────────────────────────────────────────────────────

  Future<void> _generate() async {
    final request = _request;
    if (!request.isReady) return;

    _ticker?.cancel();
    setState(() {
      _step = _MakeoverStep.generating;
      _elapsedSeconds = 0;
      _error = '';
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds += 1);
    });

    try {
      final look = await _generator.generate(request);
      if (!mounted) return;
      setState(() {
        _result = look;
        _step = _MakeoverStep.result;
      });
    } on LookGenerationException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        // Keep the previous look on screen if there was one.
        _step = _result == null ? _MakeoverStep.edit : _MakeoverStep.result;
      });
    } finally {
      _ticker?.cancel();
    }
  }

  Future<void> _save() async {
    final look = _result;
    if (look == null) return;
    await saveLookToTimeline(
      context,
      imageUrl: look.imageUrl,
      caption: _request.caption,
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Makeover',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: switch (_step) {
        _MakeoverStep.edit => _buildEditor(context),
        _MakeoverStep.generating => MakeoverGeneratingView(
          photoUrl: _photoUrl,
          elapsedSeconds: _elapsedSeconds,
        ),
        _MakeoverStep.result => MakeoverResultView(
          beforeUrl: _photoUrl,
          afterUrl: _result?.imageUrl ?? '',
          errorMessage: _error,
          onTryAnother: _generate,
          onChangeIdea: () => setState(() {
            _step = _MakeoverStep.edit;
            _error = '';
          }),
          onSave: _save,
        ),
      },
      bottomNavigationBar: _step == _MakeoverStep.edit
          ? _buildGenerateBar()
          : null,
    );
  }

  Widget _buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final trends = curatedTrends
        .where((trend) => trend.fitsScope(_scope))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('1. Your photo', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        MakeoverPhotoCard(
          photoUrl: _photoUrl,
          isLoading: _isLoadingPhoto || _isUploadingPhoto,
          onUpload: _isUploadingPhoto
              ? null
              : () => _pickPhoto(ImageSource.gallery),
          onTakePhoto: _isUploadingPhoto
              ? null
              : () => _pickPhoto(ImageSource.camera),
        ),
        const SizedBox(height: 26),
        Text('2. What should change?', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final scope in LookScope.values)
              ChoiceChip(
                key: ValueKey('look_scope_${scope.name}'),
                label: Text(scope.label),
                selected: scope == _scope,
                onSelected: (_) => _selectScope(scope),
              ),
          ],
        ),
        const SizedBox(height: 26),
        Text('3. How?', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        LookSourcePicker(
          method: _method,
          onMethodChanged: _selectMethod,
          scope: _scope,
          describeController: _describeController,
          archetypes: styleArchetypes,
          selectedArchetype: _archetype,
          onArchetypeChanged: (archetype) =>
              setState(() => _archetype = archetype),
          trends: trends,
          selectedTrend: _trend,
          onTrendChanged: (trend) => setState(() => _trend = trend),
          weather: _weather,
          onRetryWeather: _fetchWeather,
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
    final hint = request.photoUrl.isEmpty
        ? 'Add your photo to continue'
        : !request.source.isComplete
        ? 'Choose how to style your look'
        : '';

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
          FilledButton.icon(
            key: const ValueKey('makeover_generate'),
            style: FilledButton.styleFrom(
              backgroundColor: _navy,
              minimumSize: const Size.fromHeight(54),
            ),
            onPressed: request.isReady ? _generate : null,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Create my look'),
          ),
        ],
      ),
    );
  }
}
