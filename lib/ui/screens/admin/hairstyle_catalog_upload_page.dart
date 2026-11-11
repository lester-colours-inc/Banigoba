// Curators' hairstyle catalogue: upload, edit and browse the hairstyles the
// AI hair makeover offers. Moved here from the retired My Hair Style flow
// (October 2026 review, F-4); only the curators' workspace opens it.
import '../../../core/supabase/app_auth.dart';
import '../../../data/supabase/rows.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/app_routes.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/hairstyle_service.dart';
import '../../widgets/cart_badge_button.dart';
import '../main/notifications_page.dart';
import '../../widgets/app_network_image.dart';
import '../../../data/services/image_crop.dart';

const _hairNavy = Color(0xFF17008A);

const _hairOrange = Color(0xFFFFB51B);

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
    final image = await _picker.pickAndCropImage(
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

    final user = AppAuth.instance.currentUser;
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
    final userId = AppAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          curatorMode ? 'Uploaded Hairstyles' : 'Your Uploaded Hairstyles',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: HairstyleService().watchCatalog(
            uploaderId: curatorMode ? null : userId,
          ),
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

            final docs = snapshot.data?.toList() ?? [];
            docs.sort((a, b) {
              final aDate =
                  asDateTime(a['createdAt']) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final bDate =
                  asDateTime(b['createdAt']) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
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
                  data: doc,
                  onEdit: () => onEdit(doc['id'].toString(), doc),
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

class _HairFlowScaffold extends StatelessWidget {
  const _HairFlowScaffold({
    required this.title,
    required this.child,
    this.backOnly = false,
  });

  final String title;
  final Widget child;
  final bool backOnly;

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
  });

  final String title;
  final VoidCallback onMenu;
  final VoidCallback onBack;
  final bool backOnly;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Column(
        children: [
          Row(
            children: [
              // Back sits top-left, where users expect it.
              IconButton(
                tooltip: 'Back',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
              ),
              const Spacer(),
              if (!backOnly)
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

class _HairButton extends StatelessWidget {
  const _HairButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
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
