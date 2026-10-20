// My Profile Details: the user's face and full-body photos, clothing and shoe
// size, and body measurements (September 2026 request).
//
// Used by the eFitting Room when shopping online and by Fashion Idol / Style
// twin makeovers. Every detail is optional. Photos are saved as soon as they
// upload (they are slow to redo); sizes and measurements are saved with the
// Save button.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/body_profile.dart';
import '../../../data/services/body_profile_service.dart';
import 'widgets/how_to_measure_sheet.dart';
import 'widgets/measurement_field.dart';
import 'widgets/profile_photo_tile.dart';

typedef ProfileImagePicker =
    Future<Uint8List?> Function(ImageSource source, BodyPhoto photo);

enum _PhotoAction { camera, gallery, remove }

class BodyProfilePage extends StatefulWidget {
  const BodyProfilePage({super.key, this.store, this.pickImage});

  /// Injected in tests; defaults to the signed-in user's Firebase data.
  final BodyProfileStore? store;

  /// Injected in tests; defaults to the device camera and gallery.
  final ProfileImagePicker? pickImage;

  static const int maxPhotoBytes = 12 * 1024 * 1024;

  @override
  State<BodyProfilePage> createState() => _BodyProfilePageState();
}

class _BodyProfilePageState extends State<BodyProfilePage> {
  late final BodyProfileStore _store =
      widget.store ?? FirebaseBodyProfileStore();
  final _formKey = GlobalKey<FormState>();
  final _shoeSizeController = TextEditingController();
  final _notesController = TextEditingController();
  final Map<BodyMeasurement, TextEditingController> _measurementControllers = {
    for (final measurement in BodyMeasurement.values)
      measurement: TextEditingController(),
  };

  /// The profile as last saved. Photos are always saved here straight away.
  BodyProfile _saved = const BodyProfile();
  String _clothingSize = '';
  final Set<BodyPhoto> _uploading = {};
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  String _loadError = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _shoeSizeController.dispose();
    _notesController.dispose();
    for (final controller in _measurementControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = '';
    });
    try {
      final profile = await _store.load();
      if (!mounted) return;
      _fillForm(profile);
      setState(() => _saved = profile);
    } on Exception catch (error) {
      debugPrint('Unable to load profile details: $error');
      if (mounted) {
        setState(() => _loadError = 'Your details could not be loaded.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fillForm(BodyProfile profile) {
    _clothingSize = profile.clothingSize;
    _shoeSizeController.text = profile.shoeSize;
    _notesController.text = profile.notes;
    for (final entry in _measurementControllers.entries) {
      final value = profile[entry.key];
      entry.value.text = value == null ? '' : formatNumber(value);
    }
    _hasUnsavedChanges = false;
  }

  /// Also rebuilds, so the progress bar follows what is typed.
  void _markChanged([Object? _]) {
    setState(() => _hasUnsavedChanges = true);
  }

  /// The form as a profile, keeping the saved photos. Call after validating.
  BodyProfile _formProfile() {
    final shoeSize = _shoeSizeController.text.trim();
    return _saved.copyWith(
      clothingSize: _clothingSize,
      shoeSize: shoeSize.isEmpty ? '' : BodyProfile.normalizeShoeSize(shoeSize),
      measurements: {
        for (final entry in _measurementControllers.entries)
          entry.key: ?entry.key.parse(entry.value.text),
      },
      notes: _notesController.text.trim(),
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showMessage('Check the highlighted details.');
      return;
    }
    final profile = _formProfile();
    setState(() => _isSaving = true);
    try {
      await _store.save(profile);
      if (!mounted) return;
      setState(() {
        _saved = profile;
        _hasUnsavedChanges = false;
      });
      _showMessage('Your details are saved.');
      // pop, not maybePop: PopScope has not rebuilt with canPop yet.
      final navigator = Navigator.of(context);
      if (navigator.canPop()) navigator.pop(profile);
    } on Exception catch (error) {
      debugPrint('Unable to save profile details: $error');
      _showMessage('Your details could not be saved. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Photos ──────────────────────────────────────────────────────────────

  Future<void> _changePhoto(BodyPhoto photo) async {
    final hasPhoto = _saved.photoUrl(photo).isNotEmpty;
    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, _PhotoAction.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, _PhotoAction.gallery),
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove photo'),
                onTap: () => Navigator.pop(sheetContext, _PhotoAction.remove),
              ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    if (action == _PhotoAction.remove) {
      await _savePhoto(photo, '');
      return;
    }
    final source = action == _PhotoAction.camera
        ? ImageSource.camera
        : ImageSource.gallery;
    await _uploadPhoto(photo, source);
  }

  Future<void> _uploadPhoto(BodyPhoto photo, ImageSource source) async {
    final Uint8List? bytes;
    try {
      bytes = await (widget.pickImage ?? _pickFromDevice)(source, photo);
    } on Exception catch (error) {
      debugPrint('Unable to pick profile photo: $error');
      _showMessage('We could not open your photos.');
      return;
    }
    if (bytes == null || !mounted) return;
    if (bytes.lengthInBytes > BodyProfilePage.maxPhotoBytes) {
      _showMessage('That photo is too large. Choose one under 12 MB.');
      return;
    }

    setState(() => _uploading.add(photo));
    try {
      final url = await _store.uploadPhoto(photo, bytes);
      await _savePhoto(photo, url);
    } on Exception catch (error) {
      debugPrint('Unable to upload profile photo: $error');
      _showMessage('Your photo could not be uploaded. Please try again.');
    } finally {
      if (mounted) setState(() => _uploading.remove(photo));
    }
  }

  /// Saves only the photo, so unsaved form edits stay unsaved.
  Future<void> _savePhoto(BodyPhoto photo, String url) async {
    final previousUrl = _saved.photoUrl(photo);
    final updated = _saved.withPhoto(photo, url);
    try {
      await _store.save(updated);
    } on Exception catch (error) {
      debugPrint('Unable to save profile photo: $error');
      _showMessage('Your photo could not be saved. Please try again.');
      return;
    }
    if (!mounted) return;
    setState(() => _saved = updated);
    if (previousUrl.isNotEmpty && previousUrl != url) {
      unawaited(_store.deletePhoto(previousUrl));
    }
  }

  Future<Uint8List?> _pickFromDevice(
    ImageSource source,
    BodyPhoto photo,
  ) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
      preferredCameraDevice: photo == BodyPhoto.face
          ? CameraDevice.front
          : CameraDevice.rear,
    );
    return picked?.readAsBytes();
  }

  // ── Leaving ─────────────────────────────────────────────────────────────

  Future<void> _confirmLeave() async {
    final navigator = Navigator.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'Your sizes and measurements have not been saved yet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => _hasUnsavedChanges = false);
      navigator.pop();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Layout ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('My Profile Details')),
        body: _buildBody(),
        bottomNavigationBar: _isLoading || _loadError.isNotEmpty
            ? null
            : _SaveBar(isSaving: _isSaving, onSave: _save),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_loadError.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      );
    }

    final hasExtras = BodyMeasurement.extra.any(
      (measurement) => _measurementControllers[measurement]!.text.isNotEmpty,
    );
    // Not a lazy ListView: every field must stay mounted so the Form can
    // validate the ones scrolled out of view.
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Counts what is typed as well as what is saved.
            _IntroCard(detailsAdded: _formProfile().detailsAdded),
            const _SectionTitle('Photos'),
            _buildPhotos(),
            const _SectionTitle('Sizes'),
            _buildSizes(),
            _SectionTitle(
              'Measurements',
              action: TextButton.icon(
                onPressed: () => showHowToMeasureSheet(context),
                icon: const Icon(Icons.help_outline, size: 18),
                label: const Text('How to measure'),
              ),
            ),
            _buildMeasurementGrid(BodyMeasurement.requested),
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: const ValueKey('more_measurements'),
                initiallyExpanded: hasExtras,
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: const Text(
                  'More measurements',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Chest, hips and inside leg'),
                children: [_buildMeasurementGrid(BodyMeasurement.extra)],
              ),
            ),
            const _SectionTitle('Anything else'),
            TextFormField(
              key: const ValueKey('profile_notes'),
              controller: _notesController,
              onChanged: _markChanged,
              maxLines: 3,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'e.g. long arms, broad back, prefer a loose fit',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotos() {
    // Two tiles per row so each stays large enough to read on a phone.
    final firstRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ProfilePhotoTile(
            key: const ValueKey('photo_face'),
            label: 'Face',
            hint: 'Front-facing, in good light',
            icon: Icons.face_outlined,
            imageUrl: _saved.facePhotoUrl,
            isUploading: _uploading.contains(BodyPhoto.face),
            onTap: () => _changePhoto(BodyPhoto.face),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ProfilePhotoTile(
            key: const ValueKey('photo_full_body'),
            label: 'Full body',
            hint: 'Head to toe, standing straight',
            icon: Icons.accessibility_new,
            imageUrl: _saved.fullBodyPhotoUrl,
            isUploading: _uploading.contains(BodyPhoto.fullBody),
            onTap: () => _changePhoto(BodyPhoto.fullBody),
          ),
        ),
      ],
    );
    return Column(
      children: [
        firstRow,
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ProfilePhotoTile(
                key: const ValueKey('photo_hand'),
                label: 'Hand',
                hint: 'Back of your hand, fingers apart',
                icon: Icons.back_hand_outlined,
                imageUrl: _saved.handPhotoUrl,
                isUploading: _uploading.contains(BodyPhoto.hand),
                onTap: () => _changePhoto(BodyPhoto.hand),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }

  Widget _buildSizes() {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clothing size',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final size in BodyProfile.clothingSizes)
              ChoiceChip(
                key: ValueKey('clothing_size_$size'),
                label: Text(size),
                selected: _clothingSize == size,
                showCheckmark: false,
                onSelected: (selected) {
                  setState(() {
                    _clothingSize = selected ? size : '';
                    _hasUnsavedChanges = true;
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey('shoe_size'),
          controller: _shoeSizeController,
          onChanged: _markChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) => BodyProfile.validateShoeSize(value ?? ''),
          decoration: const InputDecoration(
            labelText: 'Shoe size',
            prefixText: 'UK ',
            hintText: 'e.g. 8',
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementGrid(List<BodyMeasurement> measurements) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final measurement in measurements)
              SizedBox(
                width: width,
                child: MeasurementField(
                  measurement: measurement,
                  controller: _measurementControllers[measurement]!,
                  onChanged: _markChanged,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.detailsAdded});

  final int detailsAdded;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const total = BodyProfile.requestedDetailCount;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'See clothes on you, at your real size',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your photos and sizes are used in the eFitting Room when you '
            'shop online, and for your Fashion Idol Twin.',
            style: TextStyle(color: colors.onPrimaryContainer, height: 1.35),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: detailsAdded / total,
                    minHeight: 8,
                    backgroundColor: colors.surface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$detailsAdded of $total added',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colors.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 16,
                color: colors.onPrimaryContainer,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Private to you. Never shown on your profile or posts.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.isSaving, required this.onSave});

  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: FilledButton(
          key: const ValueKey('save_profile_details'),
          onPressed: isSaving ? null : onSave,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Text(
                  'Save details',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
        ),
      ),
    );
  }
}
