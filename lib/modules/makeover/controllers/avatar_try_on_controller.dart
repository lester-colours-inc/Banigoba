// Avatar try-on: loads the saved avatar, dresses it in the chosen items with
// the AI, shows the result, makes the other angles and saves the look.
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'package:banigoba/core/main_tab.dart';
import 'package:banigoba/core/services/storage_service.dart';
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/home/views/main_screen.dart';
import 'package:banigoba/modules/makeover/models/try_on_prompt.dart';
import 'package:banigoba/modules/makeover/services/ai_job_service.dart';
import 'package:banigoba/modules/makeover/services/turn_around_service.dart';
import 'package:banigoba/modules/makeover/views/ai_upload_page.dart';
import 'package:banigoba/modules/makeover/widgets/ai_photo_consent.dart';
import 'package:banigoba/modules/makeover/widgets/caption_dialog.dart';
import 'package:banigoba/modules/makeover/widgets/full_screen_look.dart';
import 'package:banigoba/modules/makeover/widgets/turn_around_viewer.dart';
import 'package:banigoba/modules/wardrobe/services/outfit_service.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

export 'package:banigoba/modules/makeover/models/try_on_prompt.dart'
    show TryOnProvider;

class AvatarTryOnController extends GetxController {
  AvatarTryOnController({
    this.garmentImageUrl,
    this.garmentName,
    this.category,
    this.fitNote = '',
    this.arguments,
    OutfitService? outfitService,
    AiImageJobs? jobs,
  }) : _outfitService = outfitService ?? OutfitService(),
       _jobs = jobs ?? SupabaseAiImageJobs();

  final String? garmentImageUrl;
  final String? garmentName;
  final String? category;

  /// How the item really fits the shopper (their size and the fit check's
  /// findings), passed to Gemini as an instruction.
  final String fitNote;

  /// The route arguments the page was opened with (products, planned date…).
  final Object? arguments;

  final OutfitService _outfitService;
  final AiImageJobs _jobs;

  final RxnString avatarImageUrl = RxnString();
  final RxnString error = RxnString();
  final RxBool isLoadingAvatar = true.obs;
  final Rx<Map<TryOnProvider, String>> results = Rx(const {});
  final Rx<Set<TryOnProvider>> savedResults = Rx(const {});

  /// The result currently shown in the before/after panel.
  final Rxn<TryOnProvider> visibleResult = Rxn<TryOnProvider>();
  final Rxn<TryOnProvider> generatingProvider = Rxn<TryOnProvider>();
  final Rxn<TryOnProvider> savingProvider = Rxn<TryOnProvider>();
  final RxnString generatingLabel = RxnString();

  /// The turn-around angles made so far for each engine's look (the front is
  /// always the look itself), and which look is having its angles made.
  final Rx<Map<TryOnProvider, Map<TurnView, String>>> turns = Rx(const {});
  final Rxn<TryOnProvider> turningProvider = Rxn<TryOnProvider>();

  /// The saved outfit each saved look became, so angles made after saving
  /// can still be attached to it.
  final Rx<Map<TryOnProvider, String>> savedOutfitIds = Rx(const {});

  Map<dynamic, dynamic>? get _args {
    final value = arguments;
    return value is Map ? value : null;
  }

  List<Map<String, dynamic>> get selectedProducts {
    final args = _args;
    if (args != null && args['products'] is Iterable) {
      final products = (args['products'] as Iterable)
          .whereType<Map>()
          .map((product) => Map<String, dynamic>.from(product))
          .toList();
      if (products.isNotEmpty) return products;
    }
    final garmentUrl = legacyGarmentImageUrl;
    if (garmentUrl == null) return [];
    return [
      {
        'name': _legacyGarmentName,
        'imageUrl': garmentUrl,
        'category': _garmentCategory ?? 'auto',
      },
    ];
  }

  String? get legacyGarmentImageUrl {
    if (garmentImageUrl?.isNotEmpty == true) return garmentImageUrl;
    final value = _args?['garmentImageUrl'];
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  String get title {
    final products = selectedProducts;
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
    if (garmentName?.isNotEmpty == true) return garmentName!;
    final value = _args?['garmentName'];
    if (value is String && value.isNotEmpty) return value;
    return 'Selected clothing';
  }

  String? get _garmentCategory {
    if (category?.isNotEmpty == true) return category;
    final value = _args?['category'];
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  DateTime? get _plannedDate {
    final value = _args?['plannedDate'];
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String? get _eventId => _stringArg('eventId');
  String? get _eventName => _stringArg('eventName');

  String? _stringArg(String key) {
    final value = _args?[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  bool get canGenerate =>
      avatarImageUrl.value != null &&
      selectedProducts.isNotEmpty &&
      generatingProvider.value == null;

  List<TryOnProvider> get resultProviders =>
      TryOnProvider.values.where(results.value.containsKey).toList();

  @override
  void onInit() {
    super.onInit();
    loadAvatar();
  }

  Future<void> loadAvatar() async {
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      error.value = 'Sign in to use avatar try-on.';
      isLoadingAvatar.value = false;
      return;
    }

    try {
      final url = await StorageService().getLatestFullBodyImageUrl(user.uid);
      if (isClosed) return;
      avatarImageUrl.value = url is String && url.isNotEmpty ? url : null;
      isLoadingAvatar.value = false;
    } catch (e) {
      if (isClosed) return;
      error.value = 'Unable to load your avatar: $e';
      isLoadingAvatar.value = false;
    }
  }

  void showResult(TryOnProvider provider) => visibleResult.value = provider;

  /// Runs [generate] for [provider], keeping any result the other engine
  /// already produced so the two can sit side by side.
  Future<void> _runGeneration(
    TryOnProvider provider,
    Future<String> Function() generate,
  ) async {
    generatingProvider.value = provider;
    error.value = null;
    results.value = {...results.value}..remove(provider);
    savedResults.value = {...savedResults.value}..remove(provider);
    turns.value = {...turns.value}..remove(provider);
    savedOutfitIds.value = {...savedOutfitIds.value}..remove(provider);
    visibleResult.value = _remainingResult(provider);

    try {
      final resultUrl = await generate();
      if (isClosed) return;
      results.value = {...results.value, provider: resultUrl};
      visibleResult.value = provider;
    } on Exception catch (e) {
      if (isClosed) return;
      error.value = '${provider.label} try-on failed: $e';
    } finally {
      if (!isClosed) {
        generatingProvider.value = null;
        generatingLabel.value = null;
      }
    }
  }

  /// The other engine's result, if it has one, once [dropped] goes away.
  TryOnProvider? _remainingResult(TryOnProvider dropped) {
    if (visibleResult.value != dropped) return visibleResult.value;
    for (final provider in TryOnProvider.values) {
      if (provider != dropped && results.value.containsKey(provider)) {
        return provider;
      }
    }
    return null;
  }

  /// Throws away a look the user does not want to keep.
  void discardResult(TryOnProvider provider) {
    visibleResult.value = _remainingResult(provider);
    results.value = {...results.value}..remove(provider);
    savedResults.value = {...savedResults.value}..remove(provider);
    turns.value = {...turns.value}..remove(provider);
  }

  /// Makes the right side, back and left views of [provider]'s look, showing
  /// each as soon as it is ready. Uses Gemini, whatever engine made the look.
  Future<void> turnAround(TryOnProvider provider) async {
    final context = Get.context;
    if (context == null || !await ensureAiPhotoConsent(context) || isClosed) {
      return;
    }
    final frontUrl = results.value[provider];
    final avatarUrl = avatarImageUrl.value;
    final user = AppAuth.instance.currentUser;
    if (frontUrl == null || avatarUrl == null || user == null) return;

    turningProvider.value = provider;
    error.value = null;
    turns.value = {
      ...turns.value,
      provider: {TurnView.front: frontUrl},
    };
    final products = selectedProducts;
    try {
      await TurnAroundService().run(
        frontUrl: frontUrl,
        avatarUrl: avatarUrl,
        garmentUrls: [
          for (final product in products) tryOnProductImageUrl(product),
        ],
        garmentBackUrls: [
          for (final product in products)
            (product['backImageUrl'] ?? '').toString(),
        ],
        onView: (view, url) {
          if (isClosed) return;
          turns.value = {
            ...turns.value,
            provider: {...?turns.value[provider], view: url},
          };
        },
      );
    } on AiJobException catch (e) {
      if (!isClosed) {
        error.value = e.isStillRunning
            ? e.message
            : 'Could not make every angle: ${e.message}';
      }
    } finally {
      if (!isClosed) turningProvider.value = null;
      await _keepTurnViews(provider, user.uid);
    }
  }

  /// If the look is already saved, attaches the angles made so far to it.
  Future<void> _keepTurnViews(TryOnProvider provider, String userId) async {
    final outfitId = savedOutfitIds.value[provider];
    final views = turnViewsToMap(turns.value[provider] ?? const {});
    if (outfitId == null || views.isEmpty) return;
    try {
      await _outfitService.saveTurnViews(
        userId: userId,
        outfitId: outfitId,
        views: views,
      );
    } on PostgrestException catch (e) {
      debugPrint('Could not keep the angles: ${e.message}');
    }
  }

  /// Gemini takes the avatar and every garment in one call and returns raw
  /// bytes, so the result is uploaded before it can be shown or saved.
  Future<void> generateWithGemini() async {
    final context = Get.context;
    if (context == null || !await ensureAiPhotoConsent(context) || isClosed) {
      return;
    }
    final avatarUrl = avatarImageUrl.value;
    final chosen = selectedProducts;
    if (avatarUrl == null || chosen.isEmpty) return;

    final user = AppAuth.instance.currentUser;
    if (user == null) {
      error.value = 'Sign in to use avatar try-on.';
      return;
    }

    await _runGeneration(TryOnProvider.gemini, () async {
      final products = orderedTryOnProducts(
        chosen,
      ).where((product) => tryOnProductImageUrl(product).isNotEmpty).toList();
      if (products.isEmpty) {
        throw Exception('None of the selected items have an image.');
      }

      generatingLabel.value = 'your whole look at once';
      // Made on the server: it finishes, and you are told, even if you leave.
      final job = await _jobs.run(
        AiJobRequest(
          kind: AiJobKind.tryOn,
          label: 'Your try-on',
          steps: [
            AiImageStep(
              prompt: geminiTryOnPrompt(products, fitNote: fitNote),
              images: [
                AiImageUrl(avatarUrl),
                for (final product in products)
                  AiImageUrl(tryOnProductImageUrl(product)),
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

  Future<void> saveCompletedOutfit(TryOnProvider provider) async {
    final user = AppAuth.instance.currentUser;
    final avatarUrl = avatarImageUrl.value;
    final resultUrl = results.value[provider];
    if (user == null || avatarUrl == null || resultUrl == null) return;
    final plannedDate = _plannedDate;

    final caption = plannedDate == null
        ? await askLookCaption()
        : 'Planned Look';
    if (caption == null || isClosed) return;

    savingProvider.value = provider;
    try {
      final String outfitId;
      final views = turnViewsToMap(turns.value[provider] ?? const {});
      if (plannedDate == null) {
        outfitId = await _outfitService.saveOutfitToDailyDressUp(
          userId: user.uid,
          avatarImageUrl: avatarUrl,
          resultImageUrl: resultUrl,
          products: selectedProducts,
          previewType: provider.previewType,
          caption: caption,
          turnViews: views,
        );
      } else {
        outfitId = await _outfitService.saveOutfitForDate(
          userId: user.uid,
          avatarImageUrl: avatarUrl,
          resultImageUrl: resultUrl,
          products: selectedProducts,
          previewType: provider.previewType,
          date: plannedDate,
          eventId: _eventId,
          eventName: _eventName,
          turnViews: views,
        );
      }
      if (isClosed) return;
      savedResults.value = {...savedResults.value, provider};
      savedOutfitIds.value = {...savedOutfitIds.value, provider: outfitId};
      AppToast.say(
        plannedDate == null
            ? 'Look saved to your Home feed.'
            : _eventName == null
            ? 'Look saved to your Week Planner.'
            : 'Look saved to $_eventName.',
      );
      if (plannedDate == null) _openSavedLook();
    } catch (e) {
      if (isClosed) return;
      AppToast.say('Unable to save outfit: $e');
    } finally {
      if (!isClosed) savingProvider.value = null;
    }
  }

  /// Takes the user to where the look they just saved actually lives: the
  /// Home tab, which is the dress-up feed.
  void _openSavedLook() {
    MainScreen.selectTab(MainTab.home);
    Get.until((route) => route.isFirst);
  }

  Future<void> createOrUpdateAvatar() async {
    await Get.to<void>(
      () => AiUploadPage(
        plannedDate: _plannedDate,
        eventId: _eventId,
        eventName: _eventName,
      ),
    );
    if (isClosed) return;
    isLoadingAvatar.value = true;
    error.value = null;
    await loadAvatar();
  }

  void openFullScreenResult(TryOnProvider provider) {
    final imageUrl = results.value[provider];
    if (imageUrl == null) return;
    Get.to<void>(
      () => FullScreenLook(title: '${provider.label} look', imageUrl: imageUrl),
    );
  }
}
