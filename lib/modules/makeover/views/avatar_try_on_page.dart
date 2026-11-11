// Generates a clothing try-on using the signed-in user's saved avatar.

import 'package:banigoba/modules/makeover/widgets/ai_photo_consent.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/core/services/storage_service.dart';
import 'package:flutter/material.dart';

import 'package:banigoba/modules/makeover/services/ai_job_service.dart';
import 'package:banigoba/modules/wardrobe/services/outfit_service.dart';
import 'package:banigoba/modules/makeover/widgets/before_after_view.dart';
import 'package:banigoba/modules/shop/widgets/safe_product_image.dart';
import 'package:banigoba/modules/makeover/views/ai_upload_page.dart';
import 'package:banigoba/core/main_tab.dart';
import 'package:banigoba/modules/home/views/main_screen.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';
import 'package:banigoba/modules/makeover/services/turn_around_service.dart';
import 'package:banigoba/modules/makeover/widgets/turn_around_viewer.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

/// The engine that dresses the avatar. Results are kept per provider.
enum TryOnProvider {
  gemini('Gemini', 'generated_gemini');

  const TryOnProvider(this.label, this.previewType);

  final String label;

  /// Recorded on the saved outfit so it stays clear which engine made it.
  final String previewType;
}

class AvatarTryOnPage extends StatefulWidget {
  final String? garmentImageUrl;
  final String? garmentName;
  final String? category;

  /// How the item really fits the shopper (their size and the fit check's
  /// findings), passed to Gemini as an instruction.
  final String fitNote;

  const AvatarTryOnPage({
    super.key,
    this.garmentImageUrl,
    this.garmentName,
    this.category,
    this.fitNote = '',
  });

  @override
  State<AvatarTryOnPage> createState() => _AvatarTryOnPageState();
}

class _AvatarTryOnPageState extends State<AvatarTryOnPage> {
  static const Color _primaryColor = Color(0xFF0D0140);
  final OutfitService _outfitService = OutfitService();
  final AiImageJobs _jobs = SupabaseAiImageJobs();

  String? _avatarImageUrl;
  String? _error;
  bool _isLoadingAvatar = true;
  Map<TryOnProvider, String> _results = const {};
  Set<TryOnProvider> _savedResults = const {};

  /// The result currently shown in the before/after panel.
  TryOnProvider? _visibleResult;
  TryOnProvider? _generatingProvider;
  TryOnProvider? _savingProvider;
  String? _generatingLabel;

  /// The turn-around angles made so far for each engine's look (the front is
  /// always the look itself), and which look is having its angles made.
  Map<TryOnProvider, Map<TurnView, String>> _turns = const {};
  TryOnProvider? _turningProvider;

  /// The saved outfit each saved look became, so angles made after saving
  /// can still be attached to it.
  Map<TryOnProvider, String> _savedOutfitIds = const {};

  List<Map<String, dynamic>> get _selectedProducts {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map && arguments['products'] is Iterable) {
      final products = (arguments['products'] as Iterable)
          .whereType<Map>()
          .map((product) => Map<String, dynamic>.from(product))
          .toList();
      if (products.isNotEmpty) return products;
    }
    final garmentUrl = _garmentImageUrl;
    if (garmentUrl == null) return [];
    return [
      {
        'name': _legacyGarmentName,
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
    final products = _selectedProducts;
    if (products.length > 1) {
      return products
          .map((product) => (product['name'] ?? 'Clothing').toString())
          .join(' + ');
    }
    if (products.length == 1) {
      return (products.first['name'] ?? 'Selected clothing').toString();
    }
    return _legacyGarmentName;
  }

  String get _legacyGarmentName {
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

  DateTime? get _plannedDate {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map) {
      final value = arguments['plannedDate'];
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
    }
    return null;
  }

  String? get _eventId {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final value = arguments is Map ? arguments['eventId'] : null;
    return value is String && value.isNotEmpty ? value : null;
  }

  String? get _eventName {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final value = arguments is Map ? arguments['eventName'] : null;
    return value is String && value.isNotEmpty ? value : null;
  }

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _error = 'Sign in to use avatar try-on.';
        _isLoadingAvatar = false;
      });
      return;
    }

    try {
      final url = await StorageService().getLatestFullBodyImageUrl(user.uid);
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

  /// Validates the shared pre-conditions both engines need.
  ///
  /// Returns null — after surfacing an error where one is useful — when the
  /// avatar, the products or the provider's API key are missing.
  ({String avatarUrl, List<Map<String, dynamic>> products})?
  _generationInputs() {
    final avatarUrl = _avatarImageUrl;
    final products = _selectedProducts;
    if (avatarUrl == null || products.isEmpty) return null;
    return (avatarUrl: avatarUrl, products: products);
  }

  /// Runs [generate] for [provider], keeping any result the other engine
  /// already produced so the two can sit side by side.
  Future<void> _runGeneration(
    TryOnProvider provider,
    Future<String> Function() generate,
  ) async {
    setState(() {
      _generatingProvider = provider;
      _error = null;
      _results = {..._results}..remove(provider);
      _savedResults = {..._savedResults}..remove(provider);
      _turns = {..._turns}..remove(provider);
      _savedOutfitIds = {..._savedOutfitIds}..remove(provider);
      _visibleResult = _remainingResult(provider);
    });

    try {
      final resultUrl = await generate();
      if (!mounted) return;
      setState(() {
        _results = {..._results, provider: resultUrl};
        _visibleResult = provider;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _error = '${provider.label} try-on failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _generatingProvider = null;
          _generatingLabel = null;
        });
      }
    }
  }

  void _setGeneratingLabel(String? label) {
    if (!mounted) return;
    setState(() => _generatingLabel = label);
  }

  /// The other engine's result, if it has one, once [dropped] goes away.
  TryOnProvider? _remainingResult(TryOnProvider dropped) {
    if (_visibleResult != dropped) return _visibleResult;
    for (final provider in TryOnProvider.values) {
      if (provider != dropped && _results.containsKey(provider)) {
        return provider;
      }
    }
    return null;
  }

  /// Throws away a look the user does not want to keep.
  void _discardResult(TryOnProvider provider) {
    setState(() {
      _visibleResult = _remainingResult(provider);
      _results = {..._results}..remove(provider);
      _savedResults = {..._savedResults}..remove(provider);
      _turns = {..._turns}..remove(provider);
    });
  }

  /// Makes the right side, back and left views of [provider]'s look, showing
  /// each as soon as it is ready. Uses Gemini, whatever engine made the look.
  Future<void> _turnAround(TryOnProvider provider) async {
    if (!await ensureAiPhotoConsent(context) || !mounted) return;
    final frontUrl = _results[provider];
    final avatarUrl = _avatarImageUrl;
    final user = AppAuth.instance.currentUser;
    if (frontUrl == null || avatarUrl == null || user == null) return;

    setState(() {
      _turningProvider = provider;
      _error = null;
      _turns = {
        ..._turns,
        provider: {TurnView.front: frontUrl},
      };
    });
    final service = TurnAroundService();
    try {
      await service.run(
        frontUrl: frontUrl,
        avatarUrl: avatarUrl,
        garmentUrls: [
          for (final product in _selectedProducts) _productImageUrl(product),
        ],
        garmentBackUrls: [
          for (final product in _selectedProducts)
            (product['backImageUrl'] ?? '').toString(),
        ],
        onView: (view, url) {
          if (!mounted) return;
          setState(() {
            _turns = {
              ..._turns,
              provider: {...?_turns[provider], view: url},
            };
          });
        },
      );
    } on AiJobException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.isStillRunning
              ? error.message
              : 'Could not make every angle: ${error.message}',
        );
      }
    } finally {
      if (mounted) setState(() => _turningProvider = null);
      await _keepTurnViews(provider, user.uid);
    }
  }

  /// If the look is already saved, attaches the angles made so far to it.
  Future<void> _keepTurnViews(TryOnProvider provider, String userId) async {
    final outfitId = _savedOutfitIds[provider];
    final views = turnViewsToMap(_turns[provider] ?? const {});
    if (outfitId == null || views.isEmpty) return;
    try {
      await _outfitService.saveTurnViews(
        userId: userId,
        outfitId: outfitId,
        views: views,
      );
    } on PostgrestException catch (error) {
      debugPrint('Could not keep the angles: ${error.message}');
    }
  }

  Widget _turnAroundSection(TryOnProvider provider) {
    final colors = Theme.of(context).colorScheme;
    final views = _turns[provider];
    final isMaking = _turningProvider == provider;
    final madeAny = views != null && views.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Text(
          'See every angle',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          madeAny
              ? 'Drag left or right to turn around. The sides and back are '
                    'estimated by AI, because the items are only shown from '
                    'the front.'
              : 'Turn around to see the side and back views. The sides and '
                    'back are estimated by AI.',
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        if (madeAny)
          TurnAroundViewer(
            key: ValueKey('turn_${_results[provider]}'),
            views: views,
            isMakingMore: isMaking,
          ),
        if (!isMaking &&
            (views == null || views.length < TurnView.values.length))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              key: const ValueKey('turn_me_around'),
              onPressed: () => _turnAround(provider),
              icon: const Icon(Icons.threesixty),
              label: Text(
                madeAny ? 'Make the missing angles' : 'Turn me around',
              ),
            ),
          ),
        if (isMaking && !madeAny)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  /// Gemini takes the avatar and every garment in one call and returns raw
  /// bytes, so the result is uploaded before it can be shown or saved.
  Future<void> _generateWithGemini() async {
    if (!await ensureAiPhotoConsent(context) || !mounted) return;
    final inputs = _generationInputs();
    if (inputs == null) return;

    final user = AppAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'Sign in to use avatar try-on.');
      return;
    }

    await _runGeneration(TryOnProvider.gemini, () async {
      final products = _orderedProducts(
        inputs.products,
      ).where((product) => _productImageUrl(product).isNotEmpty).toList();
      if (products.isEmpty) {
        throw Exception('None of the selected items have an image.');
      }

      _setGeneratingLabel('your whole look at once');
      // Made on the server: it finishes, and you are told, even if you leave.
      final job = await _jobs.run(
        AiJobRequest(
          kind: AiJobKind.tryOn,
          label: 'Your try-on',
          steps: [
            AiImageStep(
              prompt: _geminiTryOnPrompt(products),
              images: [
                AiImageUrl(inputs.avatarUrl),
                for (final product in products)
                  AiImageUrl(_productImageUrl(product)),
              ],
            ),
          ],
        ),
      );
      if (job.images.isEmpty) {
        throw const AiJobException('No picture came back. Please try again.');
      }
      return job.images.first;
    });
  }

  /// Describes the whole look in one instruction, in the same order the images
  /// are attached.
  String _geminiTryOnPrompt(List<Map<String, dynamic>> products) {
    final items = products
        .map((product) => '- ${_geminiItemDescription(product)}')
        .join('\n');

    return 'The first image is a full-body photo of a person. The remaining '
        '${products.length} image(s) are items to put on that person:\n'
        '$items\n\n'
        'Generate one photorealistic full-body image of the same person '
        'wearing every item exactly as shown. Keep each item\'s colour, '
        'pattern, print, texture, length and cut identical to its reference '
        'image. Preserve the person\'s face, skin tone, hair, body shape, pose '
        'and the background from the first image. Replace any existing '
        'clothing that an item covers. Natural lighting, sharp detail, no '
        'text or watermarks.'
        '${widget.fitNote.isEmpty ? '' : ' ${widget.fitNote}'}';
  }

  String _geminiItemDescription(Map<String, dynamic> product) {
    final name = (product['name'] ?? 'item').toString();
    final placement = switch (_productGroup(product)) {
      'tops' => 'worn on the upper body',
      'bottoms' => 'worn on the lower body',
      'dresses' => 'worn as a one-piece',
      'outerwear' => 'worn as an outer layer over the other clothing',
      'shoes' => 'worn on the feet',
      'accessories' => 'worn or carried the way this accessory normally is',
      _ => 'worn the way this item normally is',
    };
    return '$name ($placement)';
  }

  List<Map<String, dynamic>> _orderedProducts(
    List<Map<String, dynamic>> products,
  ) {
    const order = {
      'dresses': 0,
      'tops': 1,
      'bottoms': 2,
      'outerwear': 3,
      'shoes': 4,
      'accessories': 5,
      'other': 6,
    };
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
    if (value.contains('shoe') ||
        value.contains('sneaker') ||
        value.contains('boot') ||
        value.contains('sandal') ||
        value.contains('heel')) {
      return 'shoes';
    }
    if (value.contains('outerwear') ||
        value.contains('jacket') ||
        value.contains('blazer') ||
        value.contains('coat') ||
        value.contains('hoodie') ||
        value.contains('cardigan')) {
      return 'outerwear';
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
    if (value.contains('top') ||
        value.contains('shirt') ||
        value.contains('tee') ||
        value.contains('tank') ||
        value.contains('blouse') ||
        value.contains('polo') ||
        value.contains('sweatshirt')) {
      return 'tops';
    }
    return 'other';
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

  Future<void> _saveCompletedOutfit(TryOnProvider provider) async {
    final user = AppAuth.instance.currentUser;
    final avatarUrl = _avatarImageUrl;
    final resultUrl = _results[provider];
    if (user == null || avatarUrl == null || resultUrl == null) return;
    final plannedDate = _plannedDate;

    final caption = plannedDate == null
        ? await _promptForCaption()
        : 'Planned Look';
    if (caption == null) return;
    if (!mounted) return;

    setState(() => _savingProvider = provider);
    try {
      final String outfitId;
      final turnViews = turnViewsToMap(_turns[provider] ?? const {});
      if (plannedDate == null) {
        outfitId = await _outfitService.saveOutfitToDailyDressUp(
          userId: user.uid,
          avatarImageUrl: avatarUrl,
          resultImageUrl: resultUrl,
          products: _selectedProducts,
          previewType: provider.previewType,
          caption: caption,
          turnViews: turnViews,
        );
      } else {
        outfitId = await _outfitService.saveOutfitForDate(
          userId: user.uid,
          avatarImageUrl: avatarUrl,
          resultImageUrl: resultUrl,
          products: _selectedProducts,
          previewType: provider.previewType,
          date: plannedDate,
          eventId: _eventId,
          eventName: _eventName,
          turnViews: turnViews,
        );
      }
      if (!mounted) return;
      setState(() {
        _savedResults = {..._savedResults, provider};
        _savedOutfitIds = {..._savedOutfitIds, provider: outfitId};
      });
      AppToast.say(
        plannedDate == null
            ? 'Look saved to your Home feed.'
            : _eventName == null
            ? 'Look saved to your Week Planner.'
            : 'Look saved to $_eventName.',
      );
      if (plannedDate == null) {
        _openSavedLook();
      }
    } catch (error) {
      if (!mounted) return;
      AppToast.say('Unable to save outfit: $error');
    } finally {
      if (mounted) setState(() => _savingProvider = null);
    }
  }

  Future<String?> _promptForCaption() async {
    final controller = TextEditingController();
    final caption = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Caption your look'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          maxLength: 160,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'What should this Daily Dress Up say?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(
                dialogContext,
                text.isEmpty ? 'My completed try-on look' : text,
              );
            },
            child: const Text('Save Look'),
          ),
        ],
      ),
    );
    return caption;
  }

  /// Takes the user to where the look they just saved actually lives: the
  /// Home tab, which is the dress-up feed.
  void _openSavedLook() {
    MainScreen.selectTab(MainTab.home);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _createOrUpdateAvatar() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiUploadPage(
          plannedDate: _plannedDate,
          eventId: _eventId,
          eventName: _eventName,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _isLoadingAvatar = true;
      _error = null;
    });
    await _loadAvatar();
  }

  @override
  Widget build(BuildContext context) {
    final products = _selectedProducts;
    final isMultiProductLook = products.length > 1;
    final clothingImageUrl = products.length == 1
        ? _productImageUrl(products.first)
        : _garmentImageUrl;
    final colors = Theme.of(context).colorScheme;
    final canGenerate =
        _avatarImageUrl != null &&
        products.isNotEmpty &&
        _generatingProvider == null;
    final resultProviders = TryOnProvider.values
        .where(_results.containsKey)
        .toList();

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
                                  child: SafeProductImage(
                                    imageUrl: _productImageUrl(product),
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.contain,
                                    iconSize: 28,
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
                      if (!isMultiProductLook) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _imageCard(
                            title: 'Clothing',
                            imageUrl: clothingImageUrl,
                            emptyText: 'Choose clothing to try on',
                          ),
                        ),
                      ],
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
                    onPressed: canGenerate ? _generateWithGemini : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                    ),
                    icon: _generatingProvider == TryOnProvider.gemini
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      _generatingProvider == TryOnProvider.gemini
                          ? 'Dressing your avatar...'
                          : _results.containsKey(TryOnProvider.gemini)
                          ? 'Try Again'
                          : 'See It On Me',
                    ),
                  ),
                  if (_generatingProvider != null &&
                      _generatingLabel != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Putting on $_generatingLabel',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                  if (resultProviders.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _transformationPanel(resultProviders),
                  ],
                ],
              ),
            ),
    );
  }

  /// The before/after panel: the avatar on the left, the generated look on the
  /// right, with a handle to drag between them.
  ///
  /// When both engines have run, [resultProviders] becomes a chip row so the
  /// same transformation view can switch between the two looks.
  Widget _transformationPanel(List<TryOnProvider> resultProviders) {
    final provider = _results.containsKey(_visibleResult)
        ? _visibleResult!
        : resultProviders.first;
    final resultUrl = _results[provider];
    final avatarUrl = _avatarImageUrl;
    if (resultUrl == null || avatarUrl == null) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Try On: Before & After',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 13,
                    color: colors.onPrimaryContainer,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'AI generated',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (resultProviders.length > 1) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              for (final option in resultProviders) ...[
                _providerChip(option, isSelected: option == provider),
                const SizedBox(width: 10),
              ],
            ],
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'See the Transformation',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Drag the handle to compare, or tap to see the look full screen.',
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        BeforeAfterView(
          key: ValueKey(resultUrl),
          beforeImageUrl: avatarUrl,
          afterImageUrl: resultUrl,
          onTapAfter: () => _openFullScreenResult(provider),
        ),
        _turnAroundSection(provider),
        const SizedBox(height: 16),
        _transformationActions(provider),
      ],
    );
  }

  /// Switches the panel between the two engines' looks.
  Widget _providerChip(TryOnProvider provider, {required bool isSelected}) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: isSelected
          ? null
          : () => setState(() => _visibleResult = provider),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? _primaryColor : colors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              provider.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : colors.onSurfaceVariant,
              ),
            ),
            if (_savedResults.contains(provider)) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.check_circle,
                size: 14,
                color: isSelected ? Colors.white : colors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Discard or keep the look currently on screen.
  Widget _transformationActions(TryOnProvider provider) {
    final colors = Theme.of(context).colorScheme;
    final isSaved = _savedResults.contains(provider);
    final isSaving = _savingProvider == provider;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isSaving ? null : () => _discardResult(provider),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.onSurfaceVariant,
              backgroundColor: colors.surfaceContainerLow,
              minimumSize: const Size(0, 54),
              side: BorderSide(color: colors.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: isSaving || isSaved
                ? null
                : () => _saveCompletedOutfit(provider),
            style: FilledButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 54),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(isSaved ? Icons.check_circle : Icons.save_outlined),
            label: Text(
              isSaved ? 'Saved' : 'Save Look',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  void _openFullScreenResult(TryOnProvider provider) {
    final imageUrl = _results[provider];
    if (imageUrl == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (viewerContext) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text('${provider.label} look'),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(
              maxScale: 4,
              child: AppNetworkImage(
                imageUrl,
                fit: BoxFit.contain,
                fallback: const Text(
                  'Unable to display this look.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
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
              : AppNetworkImage(
                  imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                  fallback: const Center(
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
        ),
      ],
    );
  }
}
