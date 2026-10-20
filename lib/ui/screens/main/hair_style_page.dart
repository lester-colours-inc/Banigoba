// Provides the complete AI hairstyle flow from photo upload to saved looks.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/app_routes.dart';
import '../../../core/main_tab.dart';
import '../../../core/theme_provider.dart';
import '../../../data/models/affirmation.dart';
import '../../../data/models/post.dart';
import '../../../data/services/friend_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/hairstyle_service.dart';
import '../../widgets/affirmation_row.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/cart_badge_button.dart';
import 'main_screen.dart';
import 'notifications_page.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/menu_or_back_button.dart';

const _hairNavy = Color(0xFF17008A);
const _hairOrange = Color(0xFFFFB51B);
const _hairTextureStorageFolder = 'hairstyles/textures';
const _allFilterValue = 'All';

const _styleOptions = [
  _HairStyleOption(
    name: 'Braids',
    prompt:
        'Give the person a neat braided hairstyle with realistic texture, preserving their face, pose, skin tone, and background.',
    imageUrl: '',
  ),
  _HairStyleOption(
    name: 'Locs',
    prompt:
        'Give the person natural locs with realistic texture, preserving their face, pose, skin tone, and background.',
    imageUrl: '',
  ),
  _HairStyleOption(
    name: 'Straight',
    prompt:
        'Give the person a sleek straight hairstyle with realistic shine and movement, preserving their face, pose, skin tone, and background.',
    imageUrl: '',
  ),
  _HairStyleOption(
    name: 'Wavy',
    prompt:
        'Give the person a soft wavy hairstyle with natural volume and realistic strands, preserving their face, pose, skin tone, and background.',
    imageUrl: '',
  ),
  _HairStyleOption(
    name: 'Curly',
    prompt:
        'Give the person a defined curly hairstyle with realistic curl pattern and volume, preserving their face, pose, skin tone, and background.',
    imageUrl: '',
  ),
  _HairStyleOption(
    name: 'Afro',
    prompt:
        'Give the person a full afro hairstyle with realistic natural texture and shape, preserving their face, pose, skin tone, and background.',
    imageUrl: '',
  ),
];

const _hairCatalogLengths = [
  'Bald',
  'Very Short',
  'Short',
  'Medium',
  'Long',
  'Extra Long',
  'Other',
];

const _hairCatalogGenders = [
  "Women's Hairstyles",
  "Men's Hairstyles",
  'Unisex Hairstyles',
  'Other',
];

const _hairCatalogTypes = [
  'Afro',
  'Braids',
  'Curly',
  'Locs',
  'Straight',
  'Wavy',

  'Other',
];

const _hairstylePreferenceOptions = [
  'Casual',
  'Corporate',
  'Formal',
  'Glamour',
  'Afro-Chic',
  'Edgy',
  'Sporty',
  'Bohemian',
];

const _hairCatalogStyleTypes = [..._hairstylePreferenceOptions, 'Other'];

const _hairCatalogCutTypes = {
  "Women's": [
    'Bob',
    'Lob',
    'Pixie Cut',
    'Layered Cut',
    'Blunt Cut',
    'Shag Cut',
    'Wolf Cut',
    'Butterfly Cut',
    'Curtain Layers',
    'Other',
  ],
  "Men's": [
    'Buzz Cut',
    'Crew Cut',
    'Fade',
    'Taper Fade',
    'Skin Fade',
    'Undercut',
    'Pompadour',
    'Quiff',
    'Comb Over',
    'French Crop',
    'Caesar Cut',
    'Mullet',
    'Other',
  ],
  'Afro & Protective Styles': [
    'Box Braids',
    'Knotless Braids',
    'Cornrows',
    'Fulani Braids',
    'Ghana Braids',
    'Twists',
    'Senegalese Twists',
    'Passion Twists',
    'Faux Locs',
    'Dreadlocks',
    'Bantu Knots',
    'Afro',
    'High Puff',
    'Finger Coils',
    'Other',
  ],
  'Updos': [
    'Bun',
    'High Bun',
    'Low Bun',
    'Chignon',
    'Ponytail',
    'High Ponytail',
    'Braided Updo',
    'Half Up Half Down',
    'Other',
  ],
  'Other': ['Other'],
};

const _hairCatalogOccasions = [
  'Everyday',
  'Work',
  'Wedding',
  'Party',
  'Prom',
  'Festival',
  'Vacation',
  'Photoshoot',
  'Other',
];

const _hairCatalogColours = [
  'Black',
  'Brown',
  'Blonde',
  'Red',
  'Auburn',
  'Grey',
  'Platinum',
  'Ombre',
  'Balayage',
  'Highlights',
  'Fantasy Colours',
  'Other',
];

const _hairCatalogMaintenanceLevels = [
  'Low Maintenance',
  'Medium Maintenance',
  'High Maintenance',
  'Other',
];

List<String> _stringListFromDynamic(Object? value) {
  if (value is Iterable) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? const [] : [text];
}

class HairStylePage extends StatefulWidget {
  const HairStylePage({super.key});

  @override
  State<HairStylePage> createState() => _HairStylePageState();
}

class _HairStylePageState extends State<HairStylePage> {
  final _picker = ImagePicker();
  final _hairstyleService = HairstyleService();
  bool _isPicking = false;
  bool _isLoadingLatest = true;
  bool _isSavingPreferences = false;
  String? _latestSelfieUrl;
  Set<String> _selectedStylePreferences = {};

  @override
  void initState() {
    super.initState();
    _loadLatestSelfie();
    _loadStylePreferences();
  }

  Future<void> _loadLatestSelfie() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingLatest = false);
      return;
    }

    try {
      final url = await _hairstyleService.getLatestSelfieUrl(user.uid);
      if (!mounted) return;
      setState(() {
        _latestSelfieUrl = url;
        _isLoadingLatest = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingLatest = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load saved selfie: $error')),
      );
    }
  }

  Future<void> _loadStylePreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final value = snapshot.data()?['hairstylePreference'];
      if (value is! List || !mounted) return;
      setState(() {
        _selectedStylePreferences = value
            .whereType<String>()
            .where(_hairstylePreferenceOptions.contains)
            .toSet();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load hairstyle preferences: $error')),
      );
    }
  }

  Future<void> _toggleStylePreference(String preference) async {
    if (_isSavingPreferences) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save hairstyle preferences.')),
      );
      return;
    }

    final previous = Set<String>.from(_selectedStylePreferences);
    final next = Set<String>.from(previous);
    if (next.contains(preference)) {
      next.remove(preference);
    } else {
      next.add(preference);
    }
    final ordered = _hairstylePreferenceOptions
        .where((option) => next.contains(option))
        .toList();

    setState(() {
      _selectedStylePreferences = next;
      _isSavingPreferences = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'hairstylePreference': ordered,
        'hairstylePreferenceUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      if (!mounted) return;
      setState(() => _selectedStylePreferences = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save hairstyle preferences: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSavingPreferences = false);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1600,
      );
      if (image == null || !mounted) return;

      final bytes = await image.readAsBytes();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Sign in to save your hairstyle selfie.');
      }
      final imageUrl = await _hairstyleService.saveLatestSelfie(
        userId: user.uid,
        imageBytes: bytes,
      );
      if (!mounted) return;
      setState(() => _latestSelfieUrl = imageUrl);
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              HairAnalysisPage(sourceBytes: bytes, sourceImageUrl: imageUrl),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open the photo: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _useLatestSelfie() async {
    final imageUrl = _latestSelfieUrl;
    if (imageUrl == null || _isPicking) return;

    setState(() => _isPicking = true);
    try {
      final bytes = kIsWeb
          ? null
          : await _hairstyleService.downloadSelfie(imageUrl);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              HairAnalysisPage(sourceBytes: bytes, sourceImageUrl: imageUrl),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saved selfie could not be loaded. Upload it again. $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      // This page is only reachable as a standalone route (see
      // AppRoutes.hairStyle), so it needs its own Scaffold and drawer
      // rather than relying on MainScreen's.
      drawer: AppDrawer(themeProvider: themeProvider),
      body: SafeArea(
        child: Column(
          children: [
            _HairHeader(
              title: 'My Hair Style',
              onMenu: () => Scaffold.of(context).openDrawer(),
              onBack: () => Navigator.of(context).maybePop(),
              fashionStyleLayout: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_buildMineContent()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMineContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 230,
          decoration: BoxDecoration(
            color: _latestSelfieUrl == null
                ? Theme.of(context).colorScheme.surfaceContainerLow
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _buildSelfiePreview(),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _HairButton(
                label: 'Upload Photo',
                icon: Icons.photo_outlined,
                color: _hairNavy,
                loading: _isPicking,
                onPressed: () => _pickPhoto(ImageSource.gallery),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HairButton(
                label: 'Take a Photo',
                icon: Icons.add_rounded,
                color: _hairOrange,
                loading: _isPicking,
                onPressed: () => _pickPhoto(ImageSource.camera),
              ),
            ),
          ],
        ),
        if (_latestSelfieUrl != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isPicking ? null : _useLatestSelfie,
              style: OutlinedButton.styleFrom(
                foregroundColor: _hairNavy,
                side: const BorderSide(color: _hairNavy),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              icon: const Icon(Icons.history_rounded),
              label: const Text(
                'Use Latest Selfie',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        const Text(
          'Styling Preferences',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _HairstylePreferenceGrid(
          options: _hairstylePreferenceOptions,
          selectedOptions: _selectedStylePreferences,
          saving: _isSavingPreferences,
          onToggle: _toggleStylePreference,
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const AllSavedHairStylesPage(),
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _hairNavy,
              side: const BorderSide(color: _hairNavy),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            icon: const Icon(Icons.history_rounded),
            label: const Text(
              'Styling History',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelfiePreview() {
    if (_isLoadingLatest) {
      return const Center(child: CircularProgressIndicator(color: _hairNavy));
    }

    final imageUrl = _latestSelfieUrl;
    if (imageUrl == null) return _buildUploadPlaceholder();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppNetworkImage(
            imageUrl,
            fit: BoxFit.cover,
            fallback: _buildUploadPlaceholder(),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text(
                'Latest selfie',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.upload_rounded,
          size: 78,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(height: 10),
        Text(
          'Upload Your Photo to Begin',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class TemporaryHairstyleUploadPage extends StatefulWidget {
  const TemporaryHairstyleUploadPage({
    super.key,
    this.docId,
    this.initialData,
    this.curatorMode = false,
  });

  final String? docId;
  final Map<String, dynamic>? initialData;
  final bool curatorMode;

  @override
  State<TemporaryHairstyleUploadPage> createState() =>
      _TemporaryHairstyleUploadPageState();
}

class _TemporaryHairstyleUploadPageState
    extends State<TemporaryHairstyleUploadPage> {
  final _picker = ImagePicker();
  final _service = HairstyleService();
  final _nameController = TextEditingController();

  XFile? _image;
  Uint8List? _previewBytes;
  bool _saving = false;
  String _length = _hairCatalogLengths.first;
  String _gender = _hairCatalogGenders.first;
  String _hairType = _hairCatalogTypes.first;
  Set<String> _styleTypes = {_hairCatalogStyleTypes.first};
  String _cutTypeGroup = _hairCatalogCutTypes.keys.first;
  String _cutType = _hairCatalogCutTypes.values.first.first;
  Set<String> _occasions = {_hairCatalogOccasions.first};
  String _colour = _hairCatalogColours.first;
  String _maintenanceLevel = _hairCatalogMaintenanceLevels.first;
  String _existingImageUrl = '';

  bool get _isEditing => widget.docId?.isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data == null) return;

    _nameController.text = (data['name'] ?? '').toString();
    _existingImageUrl = (data['imageUrl'] ?? '').toString();
    _length = _optionOrDefault(data['length'], _hairCatalogLengths);
    _gender = _optionOrDefault(data['gender'], _hairCatalogGenders);
    _hairType = _optionOrDefault(data['hairType'], _hairCatalogTypes);
    _styleTypes = _selectedOptions(
      values: data['styleTypes'],
      fallback: data['styleType'],
      options: _hairCatalogStyleTypes,
    );
    _cutTypeGroup = _optionOrDefault(
      data['cutTypeGroup'],
      _hairCatalogCutTypes.keys.toList(),
    );
    _cutType = _optionOrDefault(
      data['cutType'],
      _hairCatalogCutTypes[_cutTypeGroup] ?? _hairCatalogCutTypes.values.first,
    );
    _occasions = _selectedOptions(
      values: data['occasions'],
      fallback: data['occasion'],
      options: _hairCatalogOccasions,
    );
    _colour = _optionOrDefault(data['colour'], _hairCatalogColours);
    _maintenanceLevel = _optionOrDefault(
      data['maintenanceLevel'],
      _hairCatalogMaintenanceLevels,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1800,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _image = image;
      _previewBytes = bytes;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final bytes = _previewBytes;
    if (!_isEditing && (_image == null || bytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a hairstyle image first.')),
      );
      return;
    }
    if (_styleTypes.isEmpty || _occasions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose at least one style and one occasion.'),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to upload hairstyles.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final styleTypes = _orderedSelection(_styleTypes, _hairCatalogStyleTypes);
      final occasions = _orderedSelection(_occasions, _hairCatalogOccasions);
      final docId = widget.docId;
      if (_isEditing && docId != null) {
        await _service.updateCatalogHairstyle(
          docId: docId,
          userId: user.uid,
          imageBytes: bytes,
          filename: _image?.name,
          length: _length,
          gender: _gender,
          hairType: _hairType,
          styleTypes: styleTypes,
          cutTypeGroup: _cutTypeGroup,
          cutType: _cutType,
          occasions: occasions,
          colour: _colour,
          maintenanceLevel: _maintenanceLevel,
          name: _nameController.text,
        );
      } else {
        await _service.uploadCatalogHairstyle(
          userId: user.uid,
          imageBytes: bytes!,
          filename: _image!.name,
          length: _length,
          gender: _gender,
          hairType: _hairType,
          styleTypes: styleTypes,
          cutTypeGroup: _cutTypeGroup,
          cutType: _cutType,
          occasions: occasions,
          colour: _colour,
          maintenanceLevel: _maintenanceLevel,
          name: _nameController.text,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Hairstyle updated.' : 'Hairstyle uploaded.',
          ),
        ),
      );
      if (_isEditing) {
        Navigator.pop(context);
      } else {
        setState(() {
          _image = null;
          _previewBytes = null;
          _nameController.clear();
        });
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hairstyle upload failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _HairFlowScaffold(
      title: _isEditing ? 'Edit Hairstyle' : 'Upload Hairstyle',
      backOnly: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _saving ? null : _pickImage,
            child: Container(
              width: double.infinity,
              height: 260,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: _buildImagePreview(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: _fieldDecoration('Display Name'),
          ),
          const SizedBox(height: 14),
          _UploadDropdown(
            label: 'Length',
            value: _length,
            options: _hairCatalogLengths,
            onChanged: (value) => setState(() => _length = value),
          ),
          _UploadDropdown(
            label: 'Gender',
            value: _gender,
            options: _hairCatalogGenders,
            onChanged: (value) => setState(() => _gender = value),
          ),
          _UploadDropdown(
            label: 'Hair Type / Texture',
            value: _hairType,
            options: _hairCatalogTypes,
            onChanged: (value) => setState(() => _hairType = value),
          ),
          _UploadMultiSelect(
            label: 'Style Type',
            selected: _styleTypes,
            options: _hairCatalogStyleTypes,
            onChanged: (values) => setState(() => _styleTypes = values),
          ),
          _UploadDropdown(
            label: 'Cut Type Group',
            value: _cutTypeGroup,
            options: _hairCatalogCutTypes.keys.toList(),
            onChanged: (value) {
              final firstCut = _hairCatalogCutTypes[value]!.first;
              setState(() {
                _cutTypeGroup = value;
                _cutType = firstCut;
              });
            },
          ),
          _UploadDropdown(
            label: 'Cut Type',
            value: _cutType,
            options: _hairCatalogCutTypes[_cutTypeGroup]!,
            onChanged: (value) => setState(() => _cutType = value),
          ),
          _UploadMultiSelect(
            label: 'Occasion',
            selected: _occasions,
            options: _hairCatalogOccasions,
            onChanged: (values) => setState(() => _occasions = values),
          ),
          _UploadDropdown(
            label: 'Colour',
            value: _colour,
            options: _hairCatalogColours,
            onChanged: (value) => setState(() => _colour = value),
          ),
          _UploadDropdown(
            label: 'Maintenance Level',
            value: _maintenanceLevel,
            options: _hairCatalogMaintenanceLevels,
            onChanged: (value) => setState(() => _maintenanceLevel = value),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _hairNavy,
                    side: const BorderSide(color: _hairNavy),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HairButton(
                  label: _isEditing ? 'Update' : 'Save',
                  icon: _isEditing
                      ? Icons.save_outlined
                      : Icons.cloud_upload_outlined,
                  color: _hairOrange,
                  loading: _saving,
                  onPressed: _save,
                ),
              ),
            ],
          ),
          if (!_isEditing) ...[
            const SizedBox(height: 28),
            _UploadedHairstylesSection(
              curatorMode: widget.curatorMode,
              onEdit: _openEditor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_previewBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(_previewBytes!, fit: BoxFit.cover),
      );
    }
    if (_existingImageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AppNetworkImage(
          _existingImageUrl,
          fit: BoxFit.cover,
          fallback: _buildImagePlaceholder(),
        ),
      );
    }
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 58,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(height: 10),
        Text(
          _isEditing ? 'Tap to replace image' : 'Choose Hairstyle Image',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  void _openEditor(String docId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TemporaryHairstyleUploadPage(
          docId: docId,
          initialData: data,
          curatorMode: widget.curatorMode,
        ),
      ),
    );
  }

  String _optionOrDefault(Object? value, Iterable<String> options) {
    final text = value?.toString() ?? '';
    return options.contains(text) ? text : options.first;
  }

  Set<String> _selectedOptions({
    required Object? values,
    required Object? fallback,
    required List<String> options,
  }) {
    final selected = _stringListFromDynamic(
      values,
    ).where(options.contains).toSet();
    if (selected.isNotEmpty) return selected;

    final fallbackText = fallback?.toString() ?? '';
    if (options.contains(fallbackText)) return {fallbackText};
    return {options.first};
  }

  List<String> _orderedSelection(Set<String> selected, List<String> options) {
    return options.where(selected.contains).toList();
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

class _UploadDropdown extends StatelessWidget {
  const _UploadDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        items: options
            .map(
              (option) => DropdownMenuItem<String>(
                value: option,
                child: Text(option, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _HairCatalogFilters extends StatelessWidget {
  const _HairCatalogFilters({
    required this.gender,
    required this.occasion,
    required this.maintenance,
    required this.onGenderChanged,
    required this.onOccasionChanged,
    required this.onMaintenanceChanged,
    required this.onClear,
  });

  final String gender;
  final String occasion;
  final String maintenance;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<String> onOccasionChanged;
  final ValueChanged<String> onMaintenanceChanged;
  final VoidCallback onClear;

  bool get _hasFilters {
    return [
      gender,
      occasion,
      maintenance,
    ].any((value) => value != _allFilterValue);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton.filledTonal(
          onPressed: () => _openFilters(context),
          icon: const Icon(Icons.tune_rounded, size: 20),
          tooltip: 'Filter hairstyles',
          style: IconButton.styleFrom(
            backgroundColor: colors.surfaceContainerLow,
            foregroundColor: _hairNavy,
            minimumSize: const Size(36, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        if (_hasFilters)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  void _openFilters(BuildContext context) {
    var selectedGender = gender;
    var selectedOccasion = occasion;
    var selectedMaintenance = maintenance;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Hairstyles',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  _HairFilterDropdown(
                    width: double.infinity,
                    label: 'Gender',
                    value: selectedGender,
                    options: _filterOptions(_hairCatalogGenders),
                    onChanged: (value) =>
                        setSheetState(() => selectedGender = value),
                  ),
                  const SizedBox(height: 10),
                  _HairFilterDropdown(
                    width: double.infinity,
                    label: 'Occasion',
                    value: selectedOccasion,
                    options: _filterOptions(_hairCatalogOccasions),
                    onChanged: (value) =>
                        setSheetState(() => selectedOccasion = value),
                  ),
                  const SizedBox(height: 10),
                  _HairFilterDropdown(
                    width: double.infinity,
                    label: 'Maintenance',
                    value: selectedMaintenance,
                    options: _filterOptions(_hairCatalogMaintenanceLevels),
                    onChanged: (value) =>
                        setSheetState(() => selectedMaintenance = value),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            onClear();
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _hairNavy,
                            side: const BorderSide(color: _hairNavy),
                          ),
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            onGenderChanged(selectedGender);
                            onOccasionChanged(selectedOccasion);
                            onMaintenanceChanged(selectedMaintenance);
                            Navigator.pop(context);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _hairNavy,
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<String> _filterOptions(Iterable<String> options) {
    return [_allFilterValue, ...options];
  }
}

class _HairFilterDropdown extends StatelessWidget {
  const _HairFilterDropdown({
    required this.width,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final double width;
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
        ),
        items: options
            .map(
              (option) => DropdownMenuItem<String>(
                value: option,
                child: Text(option, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _UploadMultiSelect extends StatelessWidget {
  const _UploadMultiSelect({
    required this.label,
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final Set<String> selected;
  final List<String> options;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              selectedColor: _hairNavy.withValues(alpha: 0.14),
              checkmarkColor: _hairNavy,
              labelStyle: TextStyle(
                color: isSelected ? _hairNavy : colors.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              onSelected: (value) {
                final next = {...selected};
                if (value) {
                  next.add(option);
                } else if (next.length > 1) {
                  next.remove(option);
                }
                onChanged(next);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _UploadedHairstylesSection extends StatelessWidget {
  const _UploadedHairstylesSection({
    required this.curatorMode,
    required this.onEdit,
  });

  final bool curatorMode;
  final void Function(String docId, Map<String, dynamic> data) onEdit;

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          curatorMode ? 'Uploaded Hairstyles' : 'Your Uploaded Hairstyles',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: curatorMode
              ? FirebaseFirestore.instance.collection('hairstyles').snapshots()
              : FirebaseFirestore.instance
                    .collection('hairstyles')
                    .where('createdBy', isEqualTo: userId)
                    .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: CircularProgressIndicator(color: _hairNavy),
                ),
              );
            }
            if (snapshot.hasError) {
              return _HairCatalogMessage(
                message: 'Uploaded hairstyles could not be loaded.',
                detail: snapshot.error.toString(),
              );
            }

            final docs = snapshot.data?.docs.toList() ?? [];
            docs.sort((a, b) {
              final aTime = a.data()['createdAt'];
              final bTime = b.data()['createdAt'];
              final aDate = aTime is Timestamp
                  ? aTime.toDate()
                  : DateTime.fromMillisecondsSinceEpoch(0);
              final bDate = bTime is Timestamp
                  ? bTime.toDate()
                  : DateTime.fromMillisecondsSinceEpoch(0);
              return bDate.compareTo(aDate);
            });

            if (docs.isEmpty) {
              return _HairCatalogMessage(
                message: curatorMode
                    ? 'Uploaded hairstyles will appear here.'
                    : 'Your uploaded hairstyles will appear here.',
              );
            }

            return Column(
              children: docs.map((doc) {
                return _UploadedHairstyleTile(
                  data: doc.data(),
                  onEdit: () => onEdit(doc.id, doc.data()),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _UploadedHairstyleTile extends StatelessWidget {
  const _UploadedHairstyleTile({required this.data, required this.onEdit});

  final Map<String, dynamic> data;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final imageUrl = (data['imageUrl'] ?? '').toString();
    final name = (data['name'] ?? data['cutType'] ?? 'Hairstyle').toString();
    final details =
        [
              data['hairType'],
              _stringListFromDynamic(data['styleTypes']).isEmpty
                  ? data['styleType']
                  : _stringListFromDynamic(data['styleTypes']).join(', '),
              _stringListFromDynamic(data['occasions']).isEmpty
                  ? data['occasion']
                  : _stringListFromDynamic(data['occasions']).join(', '),
            ]
            .map((value) => value?.toString().trim() ?? '')
            .where((value) {
              return value.isNotEmpty && value != 'Other';
            })
            .join(' • ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: SizedBox(
            width: 58,
            height: 58,
            child: imageUrl.isEmpty
                ? Container(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: const Icon(Icons.content_cut_outlined),
                  )
                : AppNetworkImage(imageUrl, fit: BoxFit.cover),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: details.isEmpty
            ? null
            : Text(details, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: TextButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Edit'),
          style: TextButton.styleFrom(foregroundColor: _hairNavy),
        ),
      ),
    );
  }
}

class RecommendedHairTryOnPage extends StatefulWidget {
  const RecommendedHairTryOnPage({
    super.key,
    required this.styleName,
    required this.styleImageUrl,
  });

  final String styleName;
  final String styleImageUrl;

  @override
  State<RecommendedHairTryOnPage> createState() =>
      _RecommendedHairTryOnPageState();
}

class _RecommendedHairTryOnPageState extends State<RecommendedHairTryOnPage> {
  final _picker = ImagePicker();
  final _service = HairstyleService();
  bool _loadingLatest = true;
  bool _picking = false;
  String? _error;

  _HairStyleOption get _style {
    return _HairStyleOption(
      name: widget.styleName,
      imageUrl: widget.styleImageUrl,
      prompt:
          'Give the person the ${widget.styleName} hairstyle with realistic texture and salon-quality detail, preserving their face, pose, skin tone, and background.',
    );
  }

  @override
  void initState() {
    super.initState();
    _startFromLatestSelfie();
  }

  Future<void> _startFromLatestSelfie() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loadingLatest = false;
        _error = 'Sign in to try on this hairstyle.';
      });
      return;
    }

    try {
      final sourceImageUrl = await _service.getLatestSelfieUrl(user.uid);
      if (!mounted) return;
      if (sourceImageUrl?.isNotEmpty == true) {
        _openResult(sourceImageUrl: sourceImageUrl!);
        return;
      }
    } catch (_) {
      // Fall through to the upload prompt.
    }

    if (mounted) setState(() => _loadingLatest = false);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_picking) return;
    setState(() {
      _picking = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Sign in to try on this hairstyle.');
      }
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1600,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final sourceImageUrl = await _service.saveLatestSelfie(
        userId: user.uid,
        imageBytes: bytes,
      );
      if (!mounted) return;
      _openResult(sourceBytes: bytes, sourceImageUrl: sourceImageUrl);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _openResult({Uint8List? sourceBytes, required String sourceImageUrl}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _HairResultPage(
          sourceBytes: sourceBytes,
          sourceImageUrl: sourceImageUrl,
          style: _style,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingLatest) {
      return const _HairFlowScaffold(
        title: 'Try On Hairstyle',
        backOnly: true,
        child: Center(child: CircularProgressIndicator(color: _hairNavy)),
      );
    }

    return _HairFlowScaffold(
      title: 'Try On Hairstyle',
      backOnly: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Continue with this hairstyle',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 1,
              child: _HairCatalogImage(
                imageUrl: widget.styleImageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.styleName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload or take a hair photo to try this hairstyle on yourself.',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HairButton(
                  label: 'Upload Photo',
                  icon: Icons.photo_outlined,
                  color: _hairNavy,
                  loading: _picking,
                  onPressed: () => _pickPhoto(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HairButton(
                  label: 'Take a Photo',
                  icon: Icons.add_rounded,
                  color: _hairOrange,
                  loading: _picking,
                  onPressed: () => _pickPhoto(ImageSource.camera),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HairAnalysisPage extends StatefulWidget {
  const HairAnalysisPage({
    super.key,
    required this.sourceImageUrl,
    this.sourceBytes,
  });

  final Uint8List? sourceBytes;
  final String sourceImageUrl;

  @override
  State<HairAnalysisPage> createState() => _HairAnalysisPageState();
}

class _HairAnalysisPageState extends State<HairAnalysisPage> {
  double _eyes = 0.72;
  double _cheeks = 0.58;
  double _lips = 0.55;

  @override
  Widget build(BuildContext context) {
    return _HairFlowScaffold(
      title: 'Start Your Makeover',
      backOnly: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analyzing Your Look',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: AspectRatio(
              aspectRatio: 1.25,
              child: _HairSourceImage(
                sourceBytes: widget.sourceBytes,
                sourceImageUrl: widget.sourceImageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 22),
          _FaceSlider(
            label: 'Eyes',
            value: _eyes,
            onChanged: (value) => setState(() => _eyes = value),
          ),
          _FaceSlider(
            label: 'Cheeks',
            value: _cheeks,
            onChanged: (value) => setState(() => _cheeks = value),
          ),
          _FaceSlider(
            label: 'Lips',
            value: _lips,
            onChanged: (value) => setState(() => _lips = value),
          ),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: 180,
              child: _HairButton(
                label: 'Confirm Features',
                color: _hairNavy,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => HairStyleSelectionPage(
                      sourceBytes: widget.sourceBytes,
                      sourceImageUrl: widget.sourceImageUrl,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HairStyleSelectionPage extends StatefulWidget {
  const HairStyleSelectionPage({
    super.key,
    required this.sourceImageUrl,
    this.sourceBytes,
  });

  final Uint8List? sourceBytes;
  final String sourceImageUrl;

  @override
  State<HairStyleSelectionPage> createState() => _HairStyleSelectionPageState();
}

class _HairStyleSelectionPageState extends State<HairStyleSelectionPage> {
  int _selectedTexture = 0;
  int _selectedHairstyle = 0;
  String _genderFilter = _allFilterValue;
  String _occasionFilter = _allFilterValue;
  String _maintenanceFilter = _allFilterValue;
  late final Future<List<_HairStyleOption>> _textureOptionsFuture;

  @override
  void initState() {
    super.initState();
    _textureOptionsFuture = _loadTextureOptionsFromStorage();
  }

  @override
  Widget build(BuildContext context) {
    return _HairFlowScaffold(
      title: 'Choose Your Style',
      backOnly: true,
      leadingCancel: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Hair Texture',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<_HairStyleOption>>(
            future: _textureOptionsFuture,
            builder: (context, snapshot) {
              final textureOptions = snapshot.data ?? _styleOptions;
              return _StyleRow(
                options: textureOptions,
                selectedIndex: _selectedTexture,
                onSelected: (index) => setState(() => _selectedTexture = index),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Select Your Hairstyle',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              _HairCatalogFilters(
                gender: _genderFilter,
                occasion: _occasionFilter,
                maintenance: _maintenanceFilter,
                onGenderChanged: (value) =>
                    _setFilter(() => _genderFilter = value),
                onOccasionChanged: (value) =>
                    _setFilter(() => _occasionFilter = value),
                onMaintenanceChanged: (value) =>
                    _setFilter(() => _maintenanceFilter = value),
                onClear: _clearFilters,
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('hairstyles')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(color: _hairNavy),
                  ),
                );
              }
              if (snapshot.hasError) {
                return _HairCatalogMessage(
                  message: 'Hairstyles could not be loaded.',
                  detail: snapshot.error.toString(),
                );
              }

              final selectedTextureName = _styleOptions[_selectedTexture].name;
              final docs = (snapshot.data?.docs ?? []).where((doc) {
                final data = doc.data();
                return _matchesSelectedTexture(data, selectedTextureName) &&
                    _matchesFilters(data);
              }).toList();
              final catalogStyles = docs
                  .map((doc) => _catalogStyleFromDoc(doc.data()))
                  .whereType<_HairStyleOption>()
                  .toList();
              if (catalogStyles.isEmpty) {
                final filtersActive = _filtersActive;
                return _HairCatalogMessage(
                  message: filtersActive
                      ? 'No hairstyles match these filters.'
                      : 'No $selectedTextureName hairstyles uploaded yet.',
                  detail: filtersActive
                      ? 'Clear filters or try a different texture.'
                      : 'Curators can add matching styles from Curators Workspace.',
                );
              }

              final selectedHairstyle = _selectedHairstyle.clamp(
                0,
                catalogStyles.length - 1,
              );
              if (selectedHairstyle != _selectedHairstyle) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _selectedHairstyle = selectedHairstyle);
                  }
                });
              }

              return Column(
                children: [
                  _StyleRow(
                    options: catalogStyles,
                    selectedIndex: selectedHairstyle,
                    onSelected: (index) =>
                        setState(() => _selectedHairstyle = index),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: SizedBox(
                      width: 220,
                      child: _HairButton(
                        label: 'Start My Makeover',
                        icon: Icons.keyboard_double_arrow_right_rounded,
                        color: _hairNavy,
                        onPressed: () {
                          final texture = _styleOptions[_selectedTexture];
                          final hairstyle = catalogStyles[selectedHairstyle];
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => _HairResultPage(
                                sourceBytes: widget.sourceBytes,
                                sourceImageUrl: widget.sourceImageUrl,
                                style: hairstyle.withTexture(texture.name),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _setFilter(VoidCallback update) {
    setState(() {
      update();
      _selectedHairstyle = 0;
    });
  }

  bool get _filtersActive {
    return [
      _genderFilter,
      _occasionFilter,
      _maintenanceFilter,
    ].any((value) => value != _allFilterValue);
  }

  void _clearFilters() {
    setState(() {
      _genderFilter = _allFilterValue;
      _occasionFilter = _allFilterValue;
      _maintenanceFilter = _allFilterValue;
      _selectedHairstyle = 0;
    });
  }

  Future<List<_HairStyleOption>> _loadTextureOptionsFromStorage() async {
    final textureRefs = await _textureRefs();
    return Future.wait(
      _styleOptions.map((option) async {
        final textureRef = _textureRefForName(textureRefs, option.name);
        if (textureRef == null) return option;

        try {
          return option.withImageUrl(await textureRef.getDownloadURL());
        } catch (_) {
          return option;
        }
      }),
    );
  }

  Future<List<Reference>> _textureRefs() async {
    try {
      final result = await FirebaseStorage.instance
          .ref(_hairTextureStorageFolder)
          .listAll();
      return result.items;
    } catch (_) {
      return [];
    }
  }

  Reference? _textureRefForName(List<Reference> refs, String name) {
    final expected = _storageNameKey(name);
    for (final ref in refs) {
      final actual = _storageNameKey(ref.name);
      if (actual == expected || actual.endsWith(expected)) return ref;
    }
    return null;
  }

  String _storageNameKey(String value) {
    final withoutExtension = value.split('.').first;
    return withoutExtension.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  bool _matchesSelectedTexture(Map<String, dynamic> data, String texture) {
    final haystack = [
      data['name'],
      data['hairType'],
      data['texture'],
      data['styleType'],
      ..._stringListFromDynamic(data['styleTypes']),
      data['cutTypeGroup'],
      data['cutType'],
    ].map((value) => value?.toString().toLowerCase() ?? '').join(' ');
    final selected = texture.toLowerCase();

    switch (selected) {
      case 'braids':
        return haystack.contains('braid') || haystack.contains('cornrow');
      case 'locs':
        return haystack.contains('loc') || haystack.contains('dreadlock');
      case 'afro':
        return haystack.contains('afro') || haystack.contains('coily');
      default:
        return haystack.contains(selected);
    }
  }

  bool _matchesFilters(Map<String, dynamic> data) {
    return _matchesFilterValue(data['gender'], _genderFilter) &&
        _matchesFilterValue(data['maintenanceLevel'], _maintenanceFilter) &&
        _matchesMultiFilterValue(
          values: data['occasions'],
          fallback: data['occasion'],
          selected: _occasionFilter,
        );
  }

  bool _matchesFilterValue(Object? value, String selected) {
    if (selected == _allFilterValue) return true;
    return (value?.toString().trim() ?? '') == selected;
  }

  bool _matchesMultiFilterValue({
    required Object? values,
    required Object? fallback,
    required String selected,
  }) {
    if (selected == _allFilterValue) return true;
    final list = _stringListFromDynamic(values);
    if (list.isNotEmpty) return list.contains(selected);
    return (fallback?.toString().trim() ?? '') == selected;
  }

  _HairStyleOption? _catalogStyleFromDoc(Map<String, dynamic> data) {
    final imageUrl = (data['imageUrl'] ?? '').toString().trim();
    if (imageUrl.isEmpty) return null;

    final name = _firstNonEmpty([
      data['name'],
      data['cutType'],
      data['styleType'],
      'Hairstyle',
    ]);
    final details =
        [
          data['length'],
          data['hairType'],
          data['styleType'],
          _stringListFromDynamic(data['styleTypes']).join(', '),
          data['cutType'],
          data['occasion'],
          _stringListFromDynamic(data['occasions']).join(', '),
          data['colour'],
          data['maintenanceLevel'],
        ].map((value) => value?.toString().trim() ?? '').where((value) {
          return value.isNotEmpty && value != 'Other';
        }).toList();

    final detailText = details.isEmpty ? name : '$name (${details.join(', ')})';
    return _HairStyleOption(
      name: name,
      prompt:
          'Give the person the $detailText hairstyle with realistic texture and salon-quality detail, preserving their face, pose, skin tone, and background.',
      imageUrl: imageUrl,
    );
  }

  String _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return 'Hairstyle';
  }
}

class _HairResultPage extends StatefulWidget {
  const _HairResultPage({
    required this.sourceImageUrl,
    required this.style,
    this.sourceBytes,
  });

  final Uint8List? sourceBytes;
  final String sourceImageUrl;
  final _HairStyleOption style;

  @override
  State<_HairResultPage> createState() => _HairResultPageState();
}

class _HairResultPageState extends State<_HairResultPage> {
  final _service = HairstyleService();
  HairstyleGeneration? _generation;
  Object? _error;
  bool _isSaving = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'Sign in to generate a hairstyle.');
      return;
    }

    try {
      final generation = await _service.generate(
        userId: user.uid,
        sourceBytes: widget.sourceBytes,
        styleName: widget.style.name,
        prompt: widget.style.prompt,
        sourceImageUrl: widget.sourceImageUrl,
      );
      if (mounted) setState(() => _generation = generation);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _generation = HairstyleGeneration(
          sourceImageUrl: widget.sourceImageUrl,
          resultImageUrl: widget.sourceImageUrl,
          isPreview: true,
        );
      });
    }
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    final generation = _generation;
    if (user == null || generation == null || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      await _service.saveLook(
        userId: user.uid,
        styleName: widget.style.name,
        prompt: widget.style.prompt,
        styleReferenceImageUrl: widget.style.imageUrl,
        generation: generation,
      );
      if (mounted) {
        setState(() => _isSaved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              generation.isPreview
                  ? 'Hairstyle collage saved.'
                  : 'Hairstyle saved.',
            ),
          ),
        );
        _returnToHairStyleHome();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to save: $error')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _returnToHairStyleHome() {
    MainScreen.selectTab(MainTab.home);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return _HairFlowScaffold(
      title: 'Your Styled Look',
      backOnly: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your New Look',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          AspectRatio(
            aspectRatio: 0.83,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: _buildResultImage(),
            ),
          ),
          if (_generation?.isPreview == true) ...[
            const SizedBox(height: 10),
            Text(
              _error == null
                  ? 'Mock collage preview. Add FASHN_API_KEY to generate the hairstyle on your selfie.'
                  : 'Generation was unavailable, so this mock collage can be saved instead.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HairButton(
                  label: _isSaved
                      ? (_generation?.isPreview == true
                            ? 'Collage Saved'
                            : 'Look Saved')
                      : (_generation?.isPreview == true
                            ? 'Save Collage'
                            : 'Save Look'),
                  icon: _isSaved
                      ? Icons.check_circle_outline
                      : Icons.download_rounded,
                  color: _hairNavy,
                  loading: _isSaving,
                  enabled: !_isSaved,
                  onPressed: _save,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HairButton(
                  label: 'Try Another Style',
                  icon: Icons.refresh_rounded,
                  color: _hairNavy,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultImage() {
    final generation = _generation;
    if (generation == null) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: const Center(child: CircularProgressIndicator(color: _hairNavy)),
      );
    }

    if (generation.isPreview) {
      return _HairMockCollage(
        sourceImageUrl: generation.sourceImageUrl,
        sourceBytes: widget.sourceBytes,
        styleName: widget.style.name,
        styleImageUrl: widget.style.imageUrl,
      );
    }

    return AppNetworkImage(
      generation.resultImageUrl,
      fit: BoxFit.cover,
      fallback: _HairSourceImage(
        sourceBytes: widget.sourceBytes,
        sourceImageUrl: widget.sourceImageUrl,
        fit: BoxFit.cover,
      ),
    );
  }
}

class HairJourneyPage extends StatelessWidget {
  const HairJourneyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return _HairFlowScaffold(
      title: 'Your Styling Journey',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user == null)
            const _EmptyHairFeed(title: 'Sign in to see saved hairstyles')
          else
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: HairstyleService().watchSavedLooks(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _hairNavy),
                  );
                }
                final looks = snapshot.data?.docs ?? [];
                if (looks.isEmpty) {
                  return const _EmptyHairFeed(
                    title: 'Your saved hairstyles will appear here',
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saved Hairstyles',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...looks
                        .take(6)
                        .map(
                          (look) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _SavedHairStyleCard(
                              ownerId: user.uid,
                              lookId: look.id,
                              data: look.data(),
                            ),
                          ),
                        ),
                    const SizedBox(height: 24),
                    Center(
                      child: SizedBox(
                        width: 220,
                        child: _HairButton(
                          label: 'View All Saved Styles',
                          icon: Icons.keyboard_double_arrow_right_rounded,
                          color: _hairNavy,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const AllSavedHairStylesPage(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class AllSavedHairStylesPage extends StatefulWidget {
  const AllSavedHairStylesPage({super.key});

  @override
  State<AllSavedHairStylesPage> createState() => _AllSavedHairStylesPageState();
}

class _AllSavedHairStylesPageState extends State<AllSavedHairStylesPage> {
  final _hairstyleService = HairstyleService();
  final _friendService = FriendService();
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return _HairFlowScaffold(
      title: 'All Saved Styles',
      backOnly: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HairTabs(
            selectedIndex: _selectedTabIndex,
            onSelected: (index) => setState(() => _selectedTabIndex = index),
          ),
          const SizedBox(height: 24),
          if (user == null)
            const _EmptyHairFeed(title: 'Sign in to see saved hairstyles')
          else if (_selectedTabIndex == 0)
            _buildMineLooks(user.uid)
          else if (_selectedTabIndex == 1)
            _buildFriendLooks()
          else
            _buildCommunityLooks(),
        ],
      ),
    );
  }

  Widget _buildMineLooks(String userId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _hairstyleService.watchSavedLooks(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _hairNavy),
          );
        }
        if (snapshot.hasError) {
          return const _EmptyHairFeed(
            title: 'Saved hairstyles could not be loaded',
          );
        }

        final looks = (snapshot.data?.docs ?? [])
            .map(
              (doc) => _HairLookFeedItem(
                id: doc.id,
                ownerId: userId,
                data: doc.data(),
              ),
            )
            .toList();
        return _buildLookList(
          looks,
          emptyMessage: 'Your saved hairstyles will appear here',
        );
      },
    );
  }

  Widget _buildFriendLooks() {
    return StreamBuilder<List<String>>(
      stream: _friendService.getMutualFriendsIds(),
      builder: (context, friendSnapshot) {
        if (friendSnapshot.hasError) {
          return const _EmptyHairFeed(
            title: 'Friend hairstyles could not be loaded',
          );
        }
        if (!friendSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: _hairNavy),
          );
        }
        final friendIds = friendSnapshot.data!.toSet();
        return _buildPublicLooks(
          filter: (item) => friendIds.contains(item.ownerId),
          emptyMessage: 'No public hairstyles from your friends yet.',
        );
      },
    );
  }

  Widget _buildCommunityLooks() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return _buildPublicLooks(
      filter: (item) => item.ownerId != currentUserId,
      emptyMessage: 'No public community hairstyles yet.',
    );
  }

  Widget _buildPublicLooks({
    required bool Function(_HairLookFeedItem item) filter,
    required String emptyMessage,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collectionGroup('hairStyles')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _hairNavy),
          );
        }
        if (snapshot.hasError) {
          return const _EmptyHairFeed(title: 'Hairstyles could not be loaded');
        }

        final looks = (snapshot.data?.docs ?? [])
            .map((doc) {
              final data = doc.data();
              final ownerId = (data['authorId'] ?? data['authorID'] ?? '')
                  .toString();
              return _HairLookFeedItem(
                id: doc.id,
                ownerId: ownerId,
                data: data,
              );
            })
            .where((item) {
              final isPublic =
                  item.data['isPublic'] == true ||
                  item.data['visibility'] == 'public';
              return isPublic && item.ownerId.isNotEmpty && filter(item);
            })
            .toList();
        return _buildLookList(looks, emptyMessage: emptyMessage);
      },
    );
  }

  Widget _buildLookList(
    List<_HairLookFeedItem> looks, {
    required String emptyMessage,
  }) {
    if (looks.isEmpty) return _EmptyHairFeed(title: emptyMessage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${looks.length} saved ${looks.length == 1 ? 'style' : 'styles'}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemCount: looks.length,
          itemBuilder: (context, index) {
            final look = looks[index];
            return _SavedHairStyleCard(
              ownerId: look.ownerId,
              lookId: look.id,
              data: look.data,
            );
          },
        ),
      ],
    );
  }
}

class _HairLookFeedItem {
  const _HairLookFeedItem({
    required this.id,
    required this.ownerId,
    required this.data,
  });

  final String id;
  final String ownerId;
  final Map<String, dynamic> data;
}

class _SavedHairStyleCard extends StatefulWidget {
  const _SavedHairStyleCard({
    required this.ownerId,
    required this.lookId,
    required this.data,
  });

  final String ownerId;
  final String lookId;
  final Map<String, dynamic> data;

  @override
  State<_SavedHairStyleCard> createState() => _SavedHairStyleCardState();
}

class _SavedHairStyleCardState extends State<_SavedHairStyleCard> {
  final _service = HairstyleService();
  bool _busy = false;

  Map<String, dynamic> get data => widget.data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final styleName = (data['styleName'] ?? 'Hairstyle').toString();
    final resultUrl = (data['resultImageUrl'] ?? '').toString();
    final isMock =
        data['previewType'] == 'mock_collage' || data['isPreview'] == true;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isOwner = currentUserId == widget.ownerId;
    final isPublic = data['isPublic'] == true || data['visibility'] == 'public';
    final commentCount = _asInt(data['commentCount']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: isMock ? 0.9 : 1.08,
                child: isMock
                    ? _HairMockCollage(
                        sourceImageUrl: (data['sourceImageUrl'] ?? '')
                            .toString(),
                        styleName: styleName,
                        styleImageUrl: (data['styleReferenceImageUrl'] ?? '')
                            .toString(),
                        compact: true,
                      )
                    : AppNetworkImage(
                        resultUrl,
                        fit: BoxFit.cover,
                        fallback: ColoredBox(
                          color: colors.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        styleName,
                        softWrap: true,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isPublic)
                      const Icon(
                        Icons.public_rounded,
                        size: 18,
                        color: _hairNavy,
                      )
                    else
                      Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: colors.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Text(
                  isMock ? 'Mock collage' : 'Generated look',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _HairSocialCommand(
                icon: Icons.face_retouching_natural,
                label: 'Try On',
                backgroundColor: _hairNavy,
                foregroundColor: Colors.white,
                onTap: _busy ? null : _tryOn,
              ),
            ),
            const SizedBox(width: 8),
            if (isPublic)
              Expanded(
                child: _HairSocialCommand(
                  icon: Icons.chat_bubble_outline,
                  label: 'Comment',
                  backgroundColor: _hairOrange,
                  foregroundColor: Colors.white,
                  onTap: () => showHairCommentsSheet(
                    context,
                    ownerId: widget.ownerId,
                    lookId: widget.lookId,
                  ),
                ),
              ),
            if (isPublic) const SizedBox(width: 8),
            if (isOwner)
              Expanded(
                child: _HairSocialCommand(
                  icon: isPublic ? Icons.lock_outline : Icons.public_rounded,
                  label: isPublic ? 'Private' : 'Publish',
                  backgroundColor: colors.surface,
                  foregroundColor: colors.onSurface,
                  onTap: _busy
                      ? null
                      : () => isPublic ? _makePrivate() : _publish(),
                ),
              ),
            if (isOwner) const SizedBox(width: 8),
            if (isOwner)
              Expanded(
                child: _HairSocialCommand(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  backgroundColor: colors.error,
                  foregroundColor: colors.onError,
                  onTap: _busy ? null : _delete,
                ),
              ),
          ],
        ),
        if (isPublic) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: [
                AffirmationRow(
                  targetType: AffirmationTargetType.hairLook,
                  targetId: widget.lookId,
                  targetOwnerId: widget.ownerId,
                  currentUserId: currentUserId,
                  ownerName: isOwner ? 'your look' : styleName,
                  onOpenReceived: () => showReceivedAffirmations(
                    context,
                    targetType: AffirmationTargetType.hairLook,
                    targetId: widget.lookId,
                  ),
                ),
                Divider(height: 1, color: colors.outlineVariant),
                SizedBox(
                  height: 40,
                  child: _HairSocialReaction(
                    icon: Icons.chat_bubble_outline,
                    label: '$commentCount comments',
                    color: _hairNavy,
                    onTap: () => showHairCommentsSheet(
                      context,
                      ownerId: widget.ownerId,
                      lookId: widget.lookId,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _tryOn() async {
    final sourceUrl = (data['sourceImageUrl'] ?? '').toString();
    if (sourceUrl.isEmpty) {
      _showSnack('No source photo found for this hairstyle.');
      return;
    }

    setState(() => _busy = true);
    try {
      final bytes = kIsWeb ? null : await _service.downloadSelfie(sourceUrl);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => _HairResultPage(
            sourceBytes: bytes,
            sourceImageUrl: sourceUrl,
            style: _HairStyleOption(
              name: (data['styleName'] ?? 'Hairstyle').toString(),
              prompt: (data['prompt'] ?? '').toString(),
              imageUrl: (data['styleReferenceImageUrl'] ?? '').toString(),
            ),
          ),
        ),
      );
    } catch (error) {
      _showSnack('Unable to try on hairstyle: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _publish() async {
    await _runAction(
      () => _service.makeSavedLookPublic(
        userId: widget.ownerId,
        lookId: widget.lookId,
      ),
      'Hairstyle published.',
      'Unable to publish hairstyle',
    );
  }

  Future<void> _makePrivate() async {
    await _runAction(
      () => _service.makeSavedLookPrivate(
        userId: widget.ownerId,
        lookId: widget.lookId,
      ),
      'Hairstyle made private.',
      'Unable to make hairstyle private',
    );
  }

  Future<void> _delete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this hairstyle?'),
        content: const Text(
          'This deletes the saved hairstyle and its likes and comments. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    await _runAction(
      () => _service.deleteSavedLook(
        userId: widget.ownerId,
        lookId: widget.lookId,
      ),
      'Hairstyle deleted.',
      'Unable to delete hairstyle',
    );
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String success,
    String failure, {
    bool showSuccess = true,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (showSuccess && mounted) _showSnack(success);
    } catch (error) {
      if (mounted) _showSnack('$failure: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted || message.isEmpty) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    return value is num ? value.toInt() : fallback;
  }
}

class _HairSocialCommand extends StatelessWidget {
  const _HairSocialCommand({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: onTap == null
              ? backgroundColor.withValues(alpha: 0.55)
              : backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: foregroundColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HairSocialReaction extends StatelessWidget {
  const _HairSocialReaction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showHairCommentsSheet(
  BuildContext context, {
  required String ownerId,
  required String lookId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _HairCommentsSheet(ownerId: ownerId, lookId: lookId),
  );
}

class _HairCommentsSheet extends StatefulWidget {
  const _HairCommentsSheet({required this.ownerId, required this.lookId});

  final String ownerId;
  final String lookId;

  @override
  State<_HairCommentsSheet> createState() => _HairCommentsSheetState();
}

class _HairCommentsSheetState extends State<_HairCommentsSheet> {
  final _controller = TextEditingController();
  final _service = HairstyleService();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (text.isEmpty || user == null || _isSending) return;

    setState(() => _isSending = true);
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userSnapshot.data() ?? const <String, dynamic>{};
      final username = (userData['displayName'] ?? user.displayName ?? 'User')
          .toString();
      final profileImageUrl =
          (userData['profileImageURL'] ??
                  userData['profileImageUrl'] ??
                  user.photoURL ??
                  '')
              .toString();

      await _service.addSavedLookComment(
        ownerId: widget.ownerId,
        lookId: widget.lookId,
        userId: user.uid,
        text: text,
        username: username,
        profileImageURL: profileImageUrl,
      );
      _controller.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to add comment: $error')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Comments',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<PostComment>>(
                stream: _service.watchSavedLookComments(
                  ownerId: widget.ownerId,
                  lookId: widget.lookId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Comments could not be loaded.'),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final comments = snapshot.data!;
                  if (comments.isEmpty) {
                    return const Center(
                      child: Text(
                        'No comments yet. Start the conversation.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: comments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return _HairCommentTile(comment: comment);
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
              child: user == null
                  ? const Text('Sign in to add a comment.')
                  : Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              filled: true,
                              fillColor: colors.surfaceContainerLow,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 11,
                              ),
                            ),
                            onSubmitted: (_) => _sendComment(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _isSending ? null : _sendComment,
                          icon: _isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HairCommentTile extends StatelessWidget {
  const _HairCommentTile({required this.comment});

  final PostComment comment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: comment.profileImageURL.isEmpty
              ? null
              : CachedNetworkImageProvider(comment.profileImageURL),
          child: comment.profileImageURL.isEmpty
              ? Text(
                  comment.username.isEmpty
                      ? '?'
                      : comment.username.substring(0, 1).toUpperCase(),
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(comment.text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HairFlowScaffold extends StatelessWidget {
  const _HairFlowScaffold({
    required this.title,
    required this.child,
    this.backOnly = false,
    this.leadingCancel = false,
  });

  final String title;
  final Widget child;
  final bool backOnly;
  final bool leadingCancel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _HairHeader(
              title: title,
              onMenu: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              onBack: () => Navigator.pop(context),
              backOnly: backOnly,
              leadingCancel: leadingCancel,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 26),
                child: child,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: backOnly ? null : const _HairBottomBar(),
    );
  }
}

class _HairHeader extends StatelessWidget {
  const _HairHeader({
    required this.title,
    required this.onMenu,
    required this.onBack,
    this.backOnly = false,
    this.leadingCancel = false,
    this.fashionStyleLayout = false,
  });

  final String title;
  final VoidCallback onMenu;
  final VoidCallback onBack;
  final bool backOnly;
  final bool leadingCancel;
  final bool fashionStyleLayout;

  @override
  Widget build(BuildContext context) {
    if (fashionStyleLayout) {
      final colors = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 20, 4),
        child: Row(
          children: [
            MenuOrBackButton(color: colors.onSurface),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
            ),
            CartBadgeButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
              color: colors.onSurface,
            ),
            const SizedBox(width: 20),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Column(
        children: [
          Row(
            children: [
              // Back (or Cancel) sits top-left, where users expect it.
              if (leadingCancel)
                TextButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Cancel'),
                  style: TextButton.styleFrom(foregroundColor: _hairNavy),
                )
              else
                IconButton(
                  tooltip: 'Back',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
              const Spacer(),
              if (!leadingCancel && !backOnly)
                IconButton(
                  tooltip: 'Menu',
                  onPressed: onMenu,
                  icon: const Icon(Icons.menu_rounded),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                if (!backOnly)
                  CartBadgeButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.cart),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HairTabs extends StatelessWidget {
  const _HairTabs({required this.selectedIndex, this.onSelected});

  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    const labels = ['Mine', 'My Friends', 'Community'];
    return Row(
      children: List.generate(labels.length, (index) {
        final selected = selectedIndex == index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < labels.length - 1 ? 10 : 0),
            child: OutlinedButton(
              onPressed: onSelected == null
                  ? null
                  : () => onSelected?.call(index),
              style: OutlinedButton.styleFrom(
                foregroundColor: selected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                backgroundColor: selected
                    ? _hairNavy
                    : Theme.of(context).colorScheme.surfaceContainerLow,
                disabledForegroundColor: selected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                disabledBackgroundColor: selected
                    ? _hairNavy
                    : Theme.of(context).colorScheme.surfaceContainerLow,
                side: BorderSide(
                  color: selected
                      ? _hairNavy
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: const StadiumBorder(),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  labels[index],
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _HairButton extends StatelessWidget {
  const _HairButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.enabled = true,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback onPressed;
  final bool loading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: loading || !enabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.65),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon ?? Icons.check_rounded, size: 20),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _FaceSlider extends StatelessWidget {
  const _FaceSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _hairNavy,
              inactiveTrackColor: Theme.of(context).colorScheme.outlineVariant,
              thumbColor: _hairNavy,
              trackHeight: 4,
            ),
            child: Slider(value: value, onChanged: onChanged),
          ),
        ),
      ],
    );
  }
}

class _StyleRow extends StatelessWidget {
  const _StyleRow({
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_HairStyleOption> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final option = options[index];
          final selected = selectedIndex == index;
          return SizedBox(
            width: 140,
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? _hairNavy : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: _HairStyleThumbnail(imageUrl: option.imageUrl),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    option.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HairStyleThumbnail extends StatelessWidget {
  const _HairStyleThumbnail({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return _HairCatalogImage(imageUrl: imageUrl);
  }
}

class _HairstylePreferenceGrid extends StatelessWidget {
  const _HairstylePreferenceGrid({
    required this.options,
    required this.selectedOptions,
    required this.saving,
    required this.onToggle,
  });

  final List<String> options;
  final Set<String> selectedOptions;
  final bool saving;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final selected = selectedOptions.contains(option);
        return InkWell(
          onTap: saving ? null : () => onToggle(option),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: (MediaQuery.sizeOf(context).width - 60) / 2,
            constraints: const BoxConstraints(minHeight: 46),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? _hairNavy : colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? _hairNavy : colors.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? Colors.white : colors.onSurfaceVariant,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    option,
                    softWrap: true,
                    style: TextStyle(
                      color: selected ? Colors.white : colors.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _HairCatalogMessage extends StatelessWidget {
  const _HairCatalogMessage({required this.message, this.detail});

  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          if (detail?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              detail!.trim(),
              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _HairMockCollage extends StatelessWidget {
  const _HairMockCollage({
    required this.sourceImageUrl,
    required this.styleName,
    required this.styleImageUrl,
    this.sourceBytes,
    this.compact = false,
  });

  final String sourceImageUrl;
  final Uint8List? sourceBytes;
  final String styleName;
  final String styleImageUrl;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(compact ? 5 : 12),
      color: colors.surfaceContainerLow,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(compact ? 5 : 12),
              child: ColoredBox(
                color: colors.surface,
                child: _HairSourceImage(
                  sourceImageUrl: sourceImageUrl,
                  sourceBytes: sourceBytes,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SizedBox(width: compact ? 4 : 10),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(compact ? 3 : 8),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(compact ? 5 : 12),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: _HairCatalogImage(
                      imageUrl: styleImageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 6),
                    Text(
                      styleName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HairCatalogImage extends StatelessWidget {
  const _HairCatalogImage({required this.imageUrl, this.fit = BoxFit.cover});

  final String imageUrl;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cleanUrl = imageUrl.replaceAll(RegExp(r'\s+'), '');
    if (cleanUrl.isEmpty) {
      return _fallback(colors);
    }

    return AppNetworkImage(
      cleanUrl,
      width: double.infinity,
      height: double.infinity,
      fit: fit,
      fallback: _fallback(colors),
    );
  }

  Widget _fallback(ColorScheme colors) {
    return ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Icon(Icons.face_retouching_natural, color: colors.outline),
    );
  }
}

class _HairSourceImage extends StatelessWidget {
  const _HairSourceImage({
    required this.sourceImageUrl,
    this.sourceBytes,
    this.fit = BoxFit.cover,
  });

  final String sourceImageUrl;
  final Uint8List? sourceBytes;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final bytes = sourceBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        width: double.infinity,
        height: double.infinity,
        fit: fit,
      );
    }

    if (sourceImageUrl.trim().isEmpty) {
      return const ColoredBox(
        color: Colors.black12,
        child: Icon(Icons.person_outline),
      );
    }

    return AppNetworkImage(
      sourceImageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: fit,
      fallback: const ColoredBox(
        color: Colors.black12,
        child: Icon(Icons.person_outline),
      ),
    );
  }
}

class _EmptyHairFeed extends StatelessWidget {
  const _EmptyHairFeed({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 44,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HairBottomBar extends StatelessWidget {
  const _HairBottomBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              tooltip: 'Home',
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              icon: const Icon(Icons.home_outlined),
            ),
            const Text('DD', style: TextStyle(fontWeight: FontWeight.w800)),
            const CircleAvatar(
              radius: 22,
              backgroundColor: _hairNavy,
              child: Text(
                'HS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(Icons.search_rounded),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationsPage(),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                ),
                StreamBuilder<int>(
                  stream: NotificationService().getUnreadCount(),
                  builder: (context, snapshot) {
                    if ((snapshot.data ?? 0) == 0) {
                      return const SizedBox.shrink();
                    }
                    return Positioned(
                      right: 1,
                      top: 1,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          (snapshot.data ?? 0) > 99
                              ? '99+'
                              : '${snapshot.data ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HairStyleOption {
  const _HairStyleOption({
    required this.name,
    required this.prompt,
    required this.imageUrl,
  });

  final String name;
  final String prompt;
  final String imageUrl;

  _HairStyleOption withTexture(String texture) {
    return _HairStyleOption(
      name: '$texture $name',
      prompt: '$prompt Make the finished look read as $texture.',
      imageUrl: imageUrl,
    );
  }

  _HairStyleOption withImageUrl(String imageUrl) {
    return _HairStyleOption(name: name, prompt: prompt, imageUrl: imageUrl);
  }
}
