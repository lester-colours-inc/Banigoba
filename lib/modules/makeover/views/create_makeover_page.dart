// The original coordinated clothing-and-hair makeover, built on chosen
// catalogue items.
//
// Superseded as the entry point by MakeoverPage (Phase 3), which starts from
// the user's photo and an idea rather than products. Kept because choosing
// real items to try on is what "Get this look" (Phase 5) will need; it is
// reachable at AppRoutes.makeoverWithItems.
//
// Covers UI-04 (intent) through UI-09 (save and visibility) from BNG SRS 001,
// and the JRN-01 journey. Clothing and hair are presented as equal sections of
// a single brief, never as two separate products, and either can be refined
// afterwards without discarding the other's selection.
//
// Deliberately absent: any score, rating, ranking or "best look" marker. The
// compare step offers alternatives and an explanation of what changed.
import 'dart:async';

import 'package:banigoba/modules/makeover/widgets/ai_photo_consent.dart';
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:banigoba/modules/makeover/models/makeover_job.dart';
import 'package:banigoba/modules/makeover/services/coordinated_makeover_service.dart';
import 'package:banigoba/core/services/storage_service.dart';
import 'package:banigoba/modules/wardrobe/widgets/save_look_sheet.dart';
import 'package:banigoba/modules/makeover/widgets/try_on_product_picker.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';
import 'package:banigoba/core/services/image_crop.dart';

/// Steps of the coordinated journey.
enum _CreateStep { brief, generating, compare }

class CreateMakeoverPage extends StatefulWidget {
  const CreateMakeoverPage({super.key});

  @override
  State<CreateMakeoverPage> createState() => _CreateMakeoverPageState();
}

class _CreateMakeoverPageState extends State<CreateMakeoverPage> {
  final CoordinatedMakeoverService _service = CoordinatedMakeoverService();
  final StorageService _storage = StorageService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _occasionController = TextEditingController();
  final TextEditingController _feelingController = TextEditingController();
  final TextEditingController _hairController = TextEditingController();
  final TextEditingController _modestyController = TextEditingController();
  final TextEditingController _exclusionsController = TextEditingController();

  _CreateStep _step = _CreateStep.brief;
  String _sourceImageUrl = '';
  List<Map<String, dynamic>> _garments = const [];
  MakeoverJob? _job;
  int _selectedAlternative = 0;
  MakeoverDomain? _compareFocus;
  bool _isBusy = false;
  bool _isLoadingSource = true;
  String _error = '';

  /// Follows the stored job while the server works on it, so each stage's
  /// progress shows as it happens.
  StreamSubscription<MakeoverJob?>? _progress;

  @override
  void initState() {
    super.initState();
    _loadExistingPhoto();
  }

  @override
  void dispose() {
    unawaited(_progress?.cancel());
    _occasionController.dispose();
    _feelingController.dispose();
    _hairController.dispose();
    _modestyController.dispose();
    _exclusionsController.dispose();
    super.dispose();
  }

  String get _userId => AppAuth.instance.currentUser?.uid ?? '';

  void _followProgress(String jobId) {
    unawaited(_progress?.cancel());
    _progress = _service.watchJob(jobId).listen((job) {
      if (!mounted || job == null || !_isBusy) return;
      setState(() => _job = job);
    });
  }

  void _stopFollowing() {
    unawaited(_progress?.cancel());
    _progress = null;
  }

  Future<void> _loadExistingPhoto() async {
    final userId = _userId;
    if (userId.isEmpty) {
      if (mounted) setState(() => _isLoadingSource = false);
      return;
    }
    try {
      final existing = await _storage.getLatestFullBodyImageUrl(userId);
      if (!mounted) return;
      setState(() {
        _sourceImageUrl = existing ?? '';
        _isLoadingSource = false;
      });
    } on Exception catch (error) {
      debugPrint('Unable to load existing photo: $error');
      if (!mounted) return;
      setState(() => _isLoadingSource = false);
    }
  }

  // ── UI-05 capture ───────────────────────────────────────────────────────

  Future<void> _pickPhoto(ImageSource source) async {
    final userId = _userId;
    if (userId.isEmpty || _isBusy) return;

    setState(() {
      _isBusy = true;
      _error = '';
    });

    try {
      final picked = await _picker.pickAndCropImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2000,
      );
      if (picked == null) {
        if (mounted) setState(() => _isBusy = false);
        return;
      }

      final bytes = await picked.readAsBytes();
      final validation = validateSourcePhoto(bytes.lengthInBytes);
      if (validation != null) {
        if (!mounted) return;
        setState(() {
          _error = validation;
          _isBusy = false;
        });
        return;
      }

      final url = await _storage.uploadFullBodyImageBytes(bytes, userId);
      if (!mounted) return;
      setState(() {
        _sourceImageUrl = url;
        _isBusy = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'We could not use that photo. $error';
        _isBusy = false;
      });
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

  Future<void> _chooseGarments() async {
    final selected = await showTryOnProductPicker(
      context,
      initialProducts: _garments,
      outfitLabel: 'Your look',
    );
    if (selected == null || !mounted) return;
    setState(() => _garments = selected);
  }

  MakeoverIntent _buildIntent() {
    final exclusions = _exclusionsController.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    return MakeoverIntent(
      occasion: _occasionController.text.trim(),
      desiredFeeling: _feelingController.text.trim(),
      hairPrompt: _hairController.text.trim(),
      garments: _garments,
      modestyPreference: _modestyController.text.trim(),
      exclusions: exclusions,
    );
  }

  // ── UI-06 generation ────────────────────────────────────────────────────

  Future<void> _start() async {
    if (!await ensureAiPhotoConsent(context) || !mounted) return;
    if (_isBusy) return;
    final intent = _buildIntent();

    setState(() {
      _isBusy = true;
      _error = '';
    });

    try {
      final created = await _service.createJob(
        sourceImageUrl: _sourceImageUrl,
        intent: intent,
      );
      if (!mounted) return;
      setState(() {
        _job = created;
        _step = _CreateStep.generating;
      });
      _followProgress(created.id);

      final finished = await _service.run(created);
      _stopFollowing();
      if (!mounted) return;
      setState(() {
        _job = finished;
        _isBusy = false;
        _selectedAlternative = 0;
        _step = finished.alternatives.isEmpty
            ? _CreateStep.generating
            : _CreateStep.compare;
      });
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _isBusy = false;
        _step = _CreateStep.brief;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. $error';
        _isBusy = false;
      });
    }
  }

  // ── UI-08 refine one domain ─────────────────────────────────────────────

  Future<void> _refine(MakeoverDomain domain) async {
    if (!await ensureAiPhotoConsent(context) || !mounted) return;
    final job = _job;
    if (job == null || _isBusy) return;

    setState(() {
      _isBusy = true;
      _error = '';
      _step = _CreateStep.generating;
    });

    _followProgress(job.id);
    try {
      final refined = await _service.refine(
        job,
        domain: domain,
        updatedIntent: _buildIntent(),
      );
      _stopFollowing();
      if (!mounted) return;
      setState(() {
        _job = refined;
        _isBusy = false;
        _selectedAlternative = 0;
        _step = refined.alternatives.isEmpty
            ? _CreateStep.generating
            : _CreateStep.compare;
      });
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _isBusy = false;
        _step = _CreateStep.compare;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Refinement failed. $error';
        _isBusy = false;
        _step = _CreateStep.compare;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: const Text(
          'Create your look',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: _step == _CreateStep.brief
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _isBusy
                    ? null
                    : () => setState(() => _step = _CreateStep.brief),
              ),
      ),
      body: switch (_step) {
        _CreateStep.brief => _buildBrief(context),
        _CreateStep.generating => _buildGenerating(context),
        _CreateStep.compare => _buildCompare(context),
      },
    );
  }

  // ── UI-04 the single brief ──────────────────────────────────────────────

  Widget _buildBrief(BuildContext context) {
    final theme = Theme.of(context);
    final intent = _buildIntent();
    final canStart = _sourceImageUrl.isNotEmpty && !intent.isEmpty && !_isBusy;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Where are you going, and how do you want to feel?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _occasionController,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Occasion',
            hintText: 'Wedding, work, dinner, a normal Tuesday',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _feelingController,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'How you want to feel (optional)',
            hintText: 'Relaxed, sharp, celebratory',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 24),
        _buildSectionHeader(
          context,
          'Clothing and hair',
          'Choose either or both. Anything you leave empty stays exactly as '
              'it is in your photo.',
        ),
        const SizedBox(height: 12),
        _buildClothingSection(context),
        const SizedBox(height: 12),
        _buildHairSection(context),

        const SizedBox(height: 24),
        _buildSectionHeader(context, 'Your photo', ''),
        const SizedBox(height: 12),
        _buildPhotoSection(context),

        const SizedBox(height: 24),
        _buildSectionHeader(
          context,
          'Preferences',
          'These constrain what the styling may suggest.',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _modestyController,
          decoration: const InputDecoration(
            labelText: 'Coverage or modesty preference (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _exclusionsController,
          decoration: const InputDecoration(
            labelText: 'Anything to avoid (optional)',
            hintText: 'Comma separated',
            border: OutlineInputBorder(),
          ),
        ),

        if (_error.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildErrorBanner(context, _error),
        ],

        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: canStart ? _start : null,
          icon: _isBusy
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(_startButtonLabel(intent)),
        ),
        const SizedBox(height: 8),
        Text(
          'Your photo and results stay private until you choose to share them.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  String _startButtonLabel(MakeoverIntent intent) {
    if (_sourceImageUrl.isEmpty) return 'Add a photo to continue';
    return switch ((intent.wantsClothing, intent.wantsHair)) {
      (true, true) => 'Create clothing and hair look',
      (true, false) => 'Create clothing look',
      (false, true) => 'Create hair look',
      (false, false) => 'Choose a clothing or hair change',
    };
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  /// Clothing and hair render as visually equal cards — neither is the
  /// primary domain.
  Widget _buildClothingSection(BuildContext context) {
    final theme = Theme.of(context);
    final names = _garments
        .map((garment) => (garment['name'] ?? 'Item').toString())
        .toList();

    return _DomainCard(
      icon: Icons.checkroom_outlined,
      title: 'Clothing',
      isActive: _garments.isNotEmpty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (names.isEmpty)
            Text(
              'No items chosen. Your clothing will not be changed.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: names
                  .map(
                    (name) => Chip(
                      label: Text(name),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _isBusy ? null : _chooseGarments,
                icon: const Icon(Icons.add, size: 18),
                label: Text(names.isEmpty ? 'Choose items' : 'Change items'),
              ),
              if (names.isNotEmpty) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _isBusy
                      ? null
                      : () => setState(() => _garments = const []),
                  child: const Text('Clear'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHairSection(BuildContext context) {
    return _DomainCard(
      icon: Icons.content_cut_outlined,
      title: 'Hair',
      isActive: _hairController.text.trim().isNotEmpty,
      child: TextField(
        controller: _hairController,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Hair goal',
          hintText: 'Shoulder-length braids, faded cut, natural curls',
          border: OutlineInputBorder(),
          helperText: 'Leave empty to keep your hair as it is',
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildPhotoSection(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_isLoadingSource) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 120,
          width: 92,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: _sourceImageUrl.isEmpty
              ? Icon(Icons.person_outline, color: colors.onSurfaceVariant)
              : AppNetworkImage(
                  _sourceImageUrl,
                  fit: BoxFit.cover,
                  fallback: const Icon(Icons.broken_image_outlined),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: _isBusy
                    ? null
                    : () => _pickPhoto(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Take a photo'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isBusy
                    ? null
                    : () => _pickPhoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Choose from gallery'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── UI-06 progress, per domain ──────────────────────────────────────────

  Widget _buildGenerating(BuildContext context) {
    final theme = Theme.of(context);
    final job = _job;
    if (job == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Working on your look',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'You can leave this screen. The work carries on and your saved '
          'looks will be waiting.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),

        // Independent per-domain state, so one domain failing is legible.
        for (final domain in MakeoverDomain.values)
          if (job.stageFor(domain).isRequested)
            _StageTile(stage: job.stageFor(domain)),

        if (job.isPartial) ...[
          const SizedBox(height: 16),
          _buildErrorBanner(
            context,
            'Part of this look could not be created. What succeeded is kept '
            'below — nothing has been substituted.',
          ),
        ],

        if (_error.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildErrorBanner(context, _error),
        ],

        const SizedBox(height: 24),
        if (job.hasFailure && !_isBusy) ...[
          for (final domain in MakeoverDomain.values)
            if (job.stageFor(domain).status == MakeoverStageStatus.failed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilledButton.tonalIcon(
                  onPressed: () => _refine(domain),
                  icon: const Icon(Icons.refresh),
                  label: Text('Retry ${domain.label.toLowerCase()}'),
                ),
              ),
          OutlinedButton(
            onPressed: () => setState(() => _step = _CreateStep.brief),
            child: const Text('Change the brief instead'),
          ),
        ],
        if (job.alternatives.isNotEmpty && !_isBusy)
          FilledButton(
            onPressed: () => setState(() => _step = _CreateStep.compare),
            child: const Text('See what worked'),
          ),
      ],
    );
  }

  // ── UI-07 compare and UI-08 refine ──────────────────────────────────────

  Widget _buildCompare(BuildContext context) {
    final theme = Theme.of(context);
    final job = _job;
    if (job == null || job.alternatives.isEmpty) {
      return const SizedBox.shrink();
    }

    final selected =
        job.alternatives[_selectedAlternative.clamp(
          0,
          job.alternatives.length - 1,
        )];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Original is always present and always labelled.
        Text(
          'Compare',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _ComparePanel(
                label: 'Original',
                imageUrl: job.sourceImageUrl,
                isSelected: false,
                onTap: null,
              ),
              for (final alternative in job.alternatives)
                _ComparePanel(
                  label: alternative.label,
                  imageUrl: alternative.imageUrl,
                  isSelected: alternative.index == selected.index,
                  onTap: () =>
                      setState(() => _selectedAlternative = alternative.index),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        _buildFocusSelector(context, job),

        const SizedBox(height: 16),
        _buildWhyThisWorks(context, job),

        const SizedBox(height: 20),
        Text(
          'Refine',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Change one domain and keep the other. Your selections are '
          'preserved either way.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (job.intent.wantsClothing)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton.icon(
              onPressed: _isBusy ? null : _chooseGarmentsThenRefine,
              icon: const Icon(Icons.checkroom_outlined, size: 18),
              label: const Text('Change clothing only'),
            ),
          ),
        if (job.intent.wantsHair)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton.icon(
              onPressed: _isBusy ? null : _editHairThenRefine,
              icon: const Icon(Icons.content_cut_outlined, size: 18),
              label: const Text('Change hair only'),
            ),
          ),

        if (_error.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildErrorBanner(context, _error),
        ],

        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _isBusy ? null : () => _saveAndChooseVisibility(selected),
          icon: const Icon(Icons.bookmark_outline),
          label: const Text('Save this look'),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  /// Segmented control for whole look / clothing / hair (UI-07).
  Widget _buildFocusSelector(BuildContext context, MakeoverJob job) {
    final domains = job.intent.requestedDomains;
    if (domains.length < 2) return const SizedBox.shrink();

    return SegmentedButton<MakeoverDomain?>(
      segments: [
        const ButtonSegment(value: null, label: Text('Whole look')),
        for (final domain in domains)
          ButtonSegment(value: domain, label: Text(domain.label)),
      ],
      selected: {_compareFocus},
      onSelectionChanged: (selection) =>
          setState(() => _compareFocus = selection.first),
    );
  }

  /// Explains coordination and context rather than attractiveness.
  Widget _buildWhyThisWorks(BuildContext context, MakeoverJob job) {
    final theme = Theme.of(context);
    final intent = job.intent;
    final focus = _compareFocus;

    final reasons = <String>[
      if (focus == null || focus == MakeoverDomain.clothing)
        if (intent.wantsClothing)
          'Clothing: ${intent.garments.map((g) => (g['name'] ?? 'item').toString()).join(', ')}',
      if (focus == null || focus == MakeoverDomain.hair)
        if (intent.wantsHair) 'Hair: ${intent.hairPrompt}',
      if (intent.occasion.isNotEmpty) 'Chosen for: ${intent.occasion}',
      if (intent.desiredFeeling.isNotEmpty)
        'You wanted to feel: ${intent.desiredFeeling}',
      if (intent.modestyPreference.isNotEmpty)
        'Respecting: ${intent.modestyPreference}',
      if (intent.exclusions.isNotEmpty)
        'Avoiding: ${intent.exclusions.join(', ')}',
    ];

    if (reasons.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why this works',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          for (final reason in reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(reason, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }

  Future<void> _chooseGarmentsThenRefine() async {
    final selected = await showTryOnProductPicker(
      context,
      initialProducts: _garments,
      outfitLabel: 'Your look',
    );
    if (selected == null || selected.isEmpty || !mounted) return;
    setState(() => _garments = selected);
    await _refine(MakeoverDomain.clothing);
  }

  Future<void> _editHairThenRefine() async {
    final controller = TextEditingController(text: _hairController.text);
    final updated = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change hair'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Hair goal',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Regenerate hair'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (updated == null || updated.trim().isEmpty || !mounted) return;
    _hairController.text = updated.trim();
    await _refine(MakeoverDomain.hair);
  }

  // ── UI-09 save and visibility ───────────────────────────────────────────

  Future<void> _saveAndChooseVisibility(MakeoverAlternative alternative) async {
    final occasion = _occasionController.text.trim();
    await saveLookToTimeline(
      context,
      imageUrl: alternative.imageUrl,
      caption: occasion.isEmpty ? 'My makeover' : 'My $occasion look',
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: colors.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Equal-weight card for a transformation domain.
class _DomainCard extends StatelessWidget {
  const _DomainCard({
    required this.icon,
    required this.title,
    required this.isActive,
    required this.child,
  });

  final IconData icon;
  final String title;
  final bool isActive;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? colors.primary : colors.outlineVariant,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colors.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Per-domain progress row.
class _StageTile extends StatelessWidget {
  const _StageTile({required this.stage});

  final MakeoverStage stage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final (icon, label) = switch (stage.status) {
      MakeoverStageStatus.queued => (Icons.schedule, 'Waiting'),
      MakeoverStageStatus.running => (Icons.autorenew, 'Working'),
      MakeoverStageStatus.succeeded => (Icons.check_circle_outline, 'Done'),
      MakeoverStageStatus.failed => (Icons.error_outline, 'Could not finish'),
      MakeoverStageStatus.skipped => (Icons.remove, 'Not requested'),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (stage.status == MakeoverStageStatus.running)
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              icon,
              size: 18,
              color: stage.status == MakeoverStageStatus.failed
                  ? colors.error
                  : colors.onSurfaceVariant,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.domain.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  stage.errorMessage.isNotEmpty ? stage.errorMessage : label,
                  style: TextStyle(
                    fontSize: 12,
                    color: stage.status == MakeoverStageStatus.failed
                        ? colors.error
                        : colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One panel in the horizontal compare strip.
class _ComparePanel extends StatelessWidget {
  const _ComparePanel({
    required this.label,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String imageUrl;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 168,
        margin: const EdgeInsets.only(right: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colors.primary : colors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: imageUrl.isEmpty
                  ? const Center(child: Icon(Icons.image_outlined))
                  : AppNetworkImage(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      fallback: const Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
