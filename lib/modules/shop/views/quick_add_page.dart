// Quick add (review item K-1): a flea-market trader puts a piece up in a few
// taps. A photo, a price, what kind of piece it is and the sizes in hand, then
// "Add to my shop"; everything else the full form asks for gets a default and
// can be edited later. Built for adding many pieces in a row, so after each one
// the screen clears and keeps the kind.
import 'package:banigoba/modules/makeover/widgets/ai_photo_consent.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/shop/models/quick_add.dart';
import 'package:banigoba/modules/wardrobe/services/garment_tagger.dart';
import 'package:banigoba/modules/shop/services/product_service.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/core/services/image_crop.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

/// Saves a finished draft. The real one uploads the photo and adds the
/// product; tests use a fake.
abstract interface class QuickAddSaver {
  Future<void> save(QuickAddDraft draft, Uint8List photo);
}

class ProductQuickAddSaver implements QuickAddSaver {
  ProductQuickAddSaver({ProductService? products, ProfileService? profiles})
    : _products = products ?? ProductService(),
      _profiles = profiles ?? ProfileService();

  final ProductService _products;
  final ProfileService _profiles;

  @override
  Future<void> save(QuickAddDraft draft, Uint8List photo) async {
    final userId = AppAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) throw Exception('Sign in first.');
    final profile = await _profiles.get(userId);
    final shop = profile['shop'];
    final shopName =
        (shop is Map ? shop['name'] : null)?.toString().trim().isNotEmpty ==
            true
        ? (shop as Map)['name'].toString()
        : (profile['displayName'] ?? 'Boutique').toString();
    final imageUrl = await _products.uploadCatalogProductImageBytes(
      userId: userId,
      bytes: photo,
      customFilename: draft.displayName,
    );
    await _products.addProduct(
      draft.toProduct(imageUrl: imageUrl, shopName: shopName),
    );
  }
}

/// Picks a photo from the camera or the gallery; null when cancelled.
typedef PickPhoto = Future<Uint8List?> Function(ImageSource source);

Future<Uint8List?> _pickWithImagePicker(ImageSource source) async {
  final file = await ImagePicker().pickAndCropImage(
    source: source,
    imageQuality: 85,
    maxWidth: 1600,
  );
  return file?.readAsBytes();
}

class QuickAddPage extends StatefulWidget {
  const QuickAddPage({
    super.key,
    QuickAddSaver? saver,
    PickPhoto? pickPhoto,
    GarmentTagger? tagger,
    this.confirmAiUse = ensureAiPhotoConsent,
  }) : _saver = saver,
       _pickPhoto = pickPhoto,
       _tagger = tagger;

  /// Asks before photos go to the AI (App Store 5.1.2); injected in tests.
  final Future<bool> Function(BuildContext context) confirmAiUse;

  final QuickAddSaver? _saver;
  final PickPhoto? _pickPhoto;
  final GarmentTagger? _tagger;

  @override
  State<QuickAddPage> createState() => _QuickAddPageState();
}

class _QuickAddPageState extends State<QuickAddPage> {
  static const Color _primary = Color(0xFF0D0140);

  final TextEditingController _price = TextEditingController();
  final TextEditingController _name = TextEditingController();
  QuickAddDraft _draft = const QuickAddDraft();
  Uint8List? _photo;
  bool _saving = false;
  int _added = 0;

  late final QuickAddSaver _saver = widget._saver ?? ProductQuickAddSaver();
  late final PickPhoto _pick = widget._pickPhoto ?? _pickWithImagePicker;
  late final GarmentTagger _tagger = widget._tagger ?? ServerGarmentTagger();
  bool _suggested = false;

  @override
  void dispose() {
    _price.dispose();
    _name.dispose();
    super.dispose();
  }

  void _update(QuickAddDraft draft) => setState(() => _draft = draft);

  Future<void> _choosePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const ValueKey('photo_camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              key: const ValueKey('photo_gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from photos'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final bytes = await _pick(source);
    if (bytes == null || !mounted) return;
    setState(() {
      _photo = bytes;
      _draft = _draft.copyWith(hasPhoto: true);
    });
    await _suggestFromPhoto(bytes);
  }

  /// Lets the AI pick the kind and a name from the photo, unless the trader
  /// has already chosen them. Never blocks adding the piece by hand.
  Future<void> _suggestFromPhoto(Uint8List bytes) async {
    if (!_tagger.isConfigured) return;
    if (!await widget.confirmAiUse(context) || !mounted) return;
    final tags = await _tagger.tag(bytes);
    if (tags == null || !mounted || _photo != bytes) return;
    final suggested = tags.category == null
        ? null
        : QuickKind.values
              .where((k) => k.category == tags.category)
              .firstOrNull;
    setState(() {
      if (suggested != null &&
          _draft.kind == QuickKind.tops &&
          _draft.sizes.isEmpty) {
        _draft = _draft.copyWith(kind: suggested);
      }
      if (_name.text.trim().isEmpty && tags.name.isNotEmpty) {
        _name.text = tags.name;
        _draft = _draft.copyWith(name: tags.name);
      }
      _suggested = true;
    });
  }

  Future<void> _save() async {
    final problem = _draft.problem;
    final photo = _photo;
    if (problem != null || photo == null || _saving) {
      if (problem != null) _message(problem);
      return;
    }
    setState(() => _saving = true);
    try {
      await _saver.save(_draft, photo);
      if (!mounted) return;
      _price.clear();
      _name.clear();
      setState(() {
        _added += 1;
        _photo = null;
        _suggested = false;
        // Ready for the next piece of the same kind.
        _draft = QuickAddDraft(kind: _draft.kind);
      });
      _message('Added. Add the next one, or go back when you are done.');
    } on Exception catch (error) {
      _message('Could not add it: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    AppToast.say(text);
  }

  Widget _stepper({
    required Key key,
    required String label,
    required int count,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Row(
      key: key,
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
        IconButton(
          onPressed: onMinus,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$count',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: onPlus,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final kind = _draft.kind;
    final chosen = _draft.sizes.keys.toList()
      ..sort((a, b) => kind.sizes.indexOf(a).compareTo(kind.sizes.indexOf(b)));

    return Scaffold(
      appBar: AppBar(
        title: Text(_added == 0 ? 'Quick add' : 'Quick add · $_added added'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GestureDetector(
            key: const ValueKey('photo_area'),
            onTap: _choosePhoto,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: _photo == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 44,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        const Text('Take a photo of the piece'),
                      ],
                    )
                  : Image.memory(_photo!, fit: BoxFit.cover),
            ),
          ),
          if (_suggested)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Kind and name suggested from the photo. Change them if '
                'they are not right.',
                key: const ValueKey('suggested_note'),
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ),
          const SizedBox(height: 18),
          TextField(
            key: const ValueKey('price_field'),
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Price',
              prefixText: r'$ ',
            ),
            onChanged: (value) => setState(() {
              final price = parsePrice(value);
              _draft = price == null
                  ? QuickAddDraft(
                      kind: _draft.kind,
                      name: _draft.name,
                      sizes: _draft.sizes,
                      quantity: _draft.quantity,
                      hasPhoto: _draft.hasPhoto,
                    )
                  : _draft.copyWith(price: price);
            }),
          ),
          const SizedBox(height: 18),
          const Text(
            'What is it?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in QuickKind.values)
                ChoiceChip(
                  key: ValueKey('kind_${option.name}'),
                  label: Text(option.defaultName),
                  selected: kind == option,
                  onSelected: (_) => _update(_draft.copyWith(kind: option)),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (kind.isSized) ...[
            const Text(
              'Which sizes do you have?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final size in kind.sizes)
                  FilterChip(
                    key: ValueKey('size_$size'),
                    label: Text(size),
                    selected: _draft.sizes.containsKey(size),
                    onSelected: (on) =>
                        _update(_draft.adjustSize(size, on ? 1 : -99)),
                  ),
              ],
            ),
            for (final size in chosen)
              _stepper(
                key: ValueKey('count_$size'),
                label: 'Size $size',
                count: _draft.sizes[size]!,
                onMinus: () => _update(_draft.adjustSize(size, -1)),
                onPlus: () => _update(_draft.adjustSize(size, 1)),
              ),
          ] else
            _stepper(
              key: const ValueKey('count_one'),
              label: 'How many do you have?',
              count: _draft.quantity,
              onMinus: () => _update(
                _draft.copyWith(
                  quantity: _draft.quantity > 1 ? _draft.quantity - 1 : 1,
                ),
              ),
              onPlus: () =>
                  _update(_draft.copyWith(quantity: _draft.quantity + 1)),
            ),
          const SizedBox(height: 18),
          TextField(
            key: const ValueKey('name_field'),
            controller: _name,
            decoration: InputDecoration(
              labelText: 'Name (optional)',
              hintText: kind.defaultName,
            ),
            onChanged: (value) => _update(_draft.copyWith(name: value)),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const ValueKey('quick_add_save'),
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: _primary,
            ),
            child: Text(_saving ? 'Adding…' : 'Add to my shop'),
          ),
        ],
      ),
    );
  }
}
