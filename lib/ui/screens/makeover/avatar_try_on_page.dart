// Generates a clothing try-on using the signed-in user's saved avatar.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/services/outfit_service.dart';
import '../../../data/services/photo_edit_api.dart';
import 'ai_upload_page.dart';

class AvatarTryOnPage extends StatefulWidget {
  final String? garmentImageUrl;
  final String? garmentName;
  final String? category;

  const AvatarTryOnPage({
    super.key,
    this.garmentImageUrl,
    this.garmentName,
    this.category,
  });

  @override
  State<AvatarTryOnPage> createState() => _AvatarTryOnPageState();
}

class _AvatarTryOnPageState extends State<AvatarTryOnPage> {
  static const Color _primaryColor = Color(0xFF0D0140);
  static const String _apiKey = String.fromEnvironment('FASHN_API_KEY');
  final OutfitService _outfitService = OutfitService();

  String? _avatarImageUrl;
  String? _resultImageUrl;
  String? _error;
  bool _isLoadingAvatar = true;
  bool _isGenerating = false;
  bool _isSavingOutfit = false;
  bool _outfitSaved = false;
  bool _showMockCollage = false;

  List<Map<String, dynamic>> get _selectedProducts {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map && arguments['products'] is Iterable) {
      return (arguments['products'] as Iterable)
          .whereType<Map>()
          .map((product) => Map<String, dynamic>.from(product))
          .toList();
    }
    final garmentUrl = _garmentImageUrl;
    if (garmentUrl == null) return [];
    return [
      {
        'name': _garmentName,
        'imageUrl': garmentUrl,
        'category': _garmentCategory ?? 'auto',
      },
    ];
  }

  String? get _garmentImageUrl {
    if (widget.garmentImageUrl?.isNotEmpty == true) {
      return widget.garmentImageUrl;
    }

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map) {
      final value = arguments['garmentImageUrl'];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  String get _garmentName {
    if (widget.garmentName?.isNotEmpty == true) return widget.garmentName!;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map) {
      final value = arguments['garmentName'];
      if (value is String && value.isNotEmpty) return value;
    }
    return 'Selected clothing';
  }

  String? get _garmentCategory {
    if (widget.category?.isNotEmpty == true) return widget.category;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map) {
      final value = arguments['category'];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _error = 'Sign in to use avatar try-on.';
        _isLoadingAvatar = false;
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final url = snapshot.data()?['latestFullBodyImageUrl'];
      if (!mounted) return;
      setState(() {
        _avatarImageUrl = url is String && url.isNotEmpty ? url : null;
        _isLoadingAvatar = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load your avatar: $e';
        _isLoadingAvatar = false;
      });
    }
  }

  Future<void> _generateTryOn() async {
    final avatarUrl = _avatarImageUrl;
    final products = _selectedProducts;
    if (avatarUrl == null || products.isEmpty) return;

    if (_apiKey.isEmpty) {
      setState(() {
        _error =
            'FASHN is not configured. Start the app with '
            '--dart-define=FASHN_API_KEY=your_key.';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
      _resultImageUrl = null;
      _outfitSaved = false;
    });

    try {
      var currentAvatarUrl = avatarUrl;
      for (final product in _orderedProducts(products)) {
        final garmentUrl = _productImageUrl(product);
        if (garmentUrl.isEmpty) continue;
        final results = await PhotoEditApi(apiKey: _apiKey).tryOnClothes(
          modelImageUrl: currentAvatarUrl,
          garmentImageUrl: garmentUrl,
          category: _fashnCategory(
            (product['category'] ?? product['subcategory']).toString(),
          ),
        );
        if (results.isEmpty) {
          throw Exception(
            'No image was returned for ${product['name'] ?? 'a product'}.',
          );
        }
        currentAvatarUrl = results.first;
      }
      if (!mounted) return;
      setState(() {
        _resultImageUrl = currentAvatarUrl;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Try-on failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _orderedProducts(
    List<Map<String, dynamic>> products,
  ) {
    const order = {'dresses': 0, 'tops': 1, 'bottoms': 2, 'accessories': 3};
    final sorted = [...products];
    sorted.sort(
      (a, b) => (order[_productGroup(a)] ?? 4).compareTo(
        order[_productGroup(b)] ?? 4,
      ),
    );
    return sorted;
  }

  String _productGroup(Map<String, dynamic> product) {
    final value = '${product['category'] ?? ''} ${product['subcategory'] ?? ''}'
        .toLowerCase();
    if (value.contains('dress') ||
        value.contains('jumpsuit') ||
        value.contains('one-piece')) {
      return 'dresses';
    }
    if (value.contains('bottom') ||
        value.contains('pants') ||
        value.contains('trouser') ||
        value.contains('jean') ||
        value.contains('short') ||
        value.contains('skirt')) {
      return 'bottoms';
    }
    if (value.contains('accessor') ||
        value.contains('bag') ||
        value.contains('hat') ||
        value.contains('watch') ||
        value.contains('jewel')) {
      return 'accessories';
    }
    return 'tops';
  }

  String _productImageUrl(Map<String, dynamic> product) {
    const fields = [
      'rawImageUrl',
      'imageUrl',
      'imageURL',
      'processedImageUrl',
      'processed_url',
      'raw_url',
    ];
    for (final field in fields) {
      final value = product[field];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  Future<void> _saveCompletedOutfit() async {
    final user = FirebaseAuth.instance.currentUser;
    final avatarUrl = _avatarImageUrl;
    if (user == null || avatarUrl == null || !_showMockCollage) return;
    final resultUrl = _resultImageUrl ?? avatarUrl;

    setState(() => _isSavingOutfit = true);
    try {
      await _outfitService.saveOutfitToDailyDressUp(
        userId: user.uid,
        avatarImageUrl: avatarUrl,
        resultImageUrl: resultUrl,
        products: _selectedProducts,
        previewType: _resultImageUrl == null ? 'mock_collage' : 'generated',
      );
      if (!mounted) return;
      setState(() => _outfitSaved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Look saved to My Daily Dress Up.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save outfit: $error')));
    } finally {
      if (mounted) setState(() => _isSavingOutfit = false);
    }
  }

  void _previewMockLook() {
    if (_avatarImageUrl == null || _selectedProducts.isEmpty) return;
    setState(() {
      _showMockCollage = true;
      _outfitSaved = false;
      _error = null;
    });
  }

  String _fashnCategory(String? value) {
    final category = value?.toLowerCase() ?? '';
    if (category.contains('bottom') ||
        category.contains('pants') ||
        category.contains('trouser') ||
        category.contains('skirt')) {
      return 'bottoms';
    }
    if (category.contains('dress') ||
        category.contains('jumpsuit') ||
        category.contains('one-piece')) {
      return 'one-pieces';
    }
    if (category.contains('top') ||
        category.contains('shirt') ||
        category.contains('jacket') ||
        category.contains('outerwear')) {
      return 'tops';
    }
    return 'auto';
  }

  Future<void> _createOrUpdateAvatar() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AiUploadPage()));
    if (!mounted) return;
    setState(() {
      _isLoadingAvatar = true;
      _error = null;
    });
    await _loadAvatar();
  }

  @override
  Widget build(BuildContext context) {
    final garmentUrl = _garmentImageUrl;
    final products = _selectedProducts;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Avatar Try-On'),
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
      ),
      body: _isLoadingAvatar
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _garmentName,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (products.length > 1) ...[
                    Text(
                      'Selected outfit',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 96,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: products.length,
                        separatorBuilder: (_, _) => SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return Container(
                            width: 82,
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.outlineVariant),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Image.network(
                                    _productImageUrl(product),
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) =>
                                        Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                                Text(
                                  (product['name'] ?? 'Clothing').toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _imageCard(
                          title: 'Your avatar',
                          imageUrl: _avatarImageUrl,
                          emptyText: 'Create an avatar first',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _imageCard(
                          title: 'Clothing',
                          imageUrl: garmentUrl,
                          emptyText: 'Choose clothing to try on',
                        ),
                      ),
                    ],
                  ),
                  if (_avatarImageUrl == null) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _createOrUpdateAvatar,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Create My Avatar'),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _avatarImageUrl == null || products.isEmpty
                        ? null
                        : _previewMockLook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                    ),
                    icon: const Icon(Icons.dashboard_customize_outlined),
                    label: const Text('Preview Mock Look'),
                  ),
                  if (_showMockCollage) ...[
                    const SizedBox(height: 28),
                    const Text(
                      'Mock Try-On Preview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMockCollage(products),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colors.onPrimaryContainer,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This collage is a temporary confirmation preview. '
                              'The try-on API integration will replace it with a '
                              'generated image of the selected items worn on your avatar.',
                              style: TextStyle(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_apiKey.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isGenerating ? null : _generateTryOn,
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(
                          _isGenerating
                              ? 'Generating API Preview...'
                              : 'Test API Preview',
                        ),
                      ),
                    ],
                    if (_resultImageUrl != null) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          _resultImageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const SizedBox(
                            height: 240,
                            child: Center(
                              child: Text(
                                'Unable to display generated preview.',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isSavingOutfit || _outfitSaved
                          ? null
                          : _saveCompletedOutfit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 54),
                      ),
                      icon: _isSavingOutfit
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _outfitSaved
                                  ? Icons.check_circle
                                  : Icons.save_outlined,
                            ),
                      label: Text(
                        _outfitSaved
                            ? 'Saved to My Daily Dress Up'
                            : 'Save to My Daily Dress Up',
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _imageCard({
    required String title,
    required String? imageUrl,
    required String emptyText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          height: 230,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: imageUrl == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(emptyText, textAlign: TextAlign.center),
                  ),
                )
              : Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image_outlined)),
                ),
        ),
      ],
    );
  }

  Widget _buildMockCollage(List<Map<String, dynamic>> products) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 380,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                _resultImageUrl ?? _avatarImageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Center(child: Icon(Icons.person_outline, size: 64)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                for (final product in products)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Image.network(
                                _productImageUrl(product),
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                            Text(
                              (product['name'] ?? 'Clothing').toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
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
