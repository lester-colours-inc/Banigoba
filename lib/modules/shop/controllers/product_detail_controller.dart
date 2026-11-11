// A product's detail screen: its data, size choice, fit check, cart,
// wardrobe, boutique chat, and the owner's edit / delete.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:banigoba/app/routes/app_routes.dart';
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/makeover/views/avatar_try_on_page.dart';
import 'package:banigoba/modules/profile_details/models/body_profile.dart';
import 'package:banigoba/modules/profile_details/services/body_profile_service.dart';
import 'package:banigoba/modules/shop/services/cart_service.dart';
import 'package:banigoba/modules/shop/services/product_service.dart';
import 'package:banigoba/modules/shop/services/shop_chat_service.dart';
import 'package:banigoba/modules/shop/views/shop_chat_page.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/modules/wardrobe/models/fit_check.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

/// Asks whether to empty a bag from another shop; true to clear it.
typedef ConfirmNewBag = Future<bool> Function(CartShopConflictException error);

class ProductDetailController extends GetxController {
  ProductDetailController({
    String? productId,
    required Map<String, dynamic> productData,
    this.loadBodyProfile,
  }) : _initial = {...productData, if (productId != null) 'id': productId};

  final Map<String, dynamic> _initial;

  /// Injected in tests; defaults to the signed-in user's saved measurements.
  final Future<BodyProfile> Function()? loadBodyProfile;

  final ProductService _products = ProductService();
  final CartService _cart = CartService();

  final String currentUserId = AppAuth.instance.currentUser?.uid ?? '';

  late final Rx<Map<String, dynamic>> product = Rx(_initial);
  final RxnString selectedSize = RxnString();

  /// The shopper's saved measurements, for the fit check and the try-on.
  final Rx<BodyProfile> body = const BodyProfile().obs;
  final RxBool isSaved = false.obs;

  /// The uploader's profile; empty until it loads.
  final Rx<Map<String, dynamic>> poster = Rx(<String, dynamic>{});

  StreamSubscription<bool>? _savedSub;
  StreamSubscription<Map<String, dynamic>>? _posterSub;

  Map<String, dynamic> get data => product.value;

  String? get uploaderId => (data['userId'] ?? data['uploaderId']) as String?;

  Object? get productId => data['id'] ?? data['originalProductId'];

  bool get isMe => uploaderId == currentUserId;

  /// A catalog product, as opposed to a user's copy of one.
  bool get isCatalogProduct =>
      data.containsKey('uploaderId') && data['originalProductId'] == null;

  @override
  void onInit() {
    super.onInit();
    loadBody();
    final id = productId;
    if (!isMe && id != null) {
      _savedSub = _products
          .isInWardrobe(currentUserId, id.toString())
          .listen((saved) => isSaved.value = saved);
    }
    final poster_ = uploaderId;
    if (poster_ != null) {
      _posterSub = ProfileService()
          .watch(poster_)
          .listen((profile) => poster.value = profile);
    }
  }

  @override
  void onClose() {
    _savedSub?.cancel();
    _posterSub?.cancel();
    super.onClose();
  }

  Future<void> loadBody() async {
    try {
      final loaded =
          await (loadBodyProfile ?? BodyProfileService().loadForCurrentUser)();
      if (!isClosed) body.value = loaded;
    } on Exception catch (error) {
      // No fit check without measurements; the page still works.
      debugPrint('Unable to load measurements: $error');
    }
  }

  void chooseSize(String size) => selectedSize.value = size;

  static bool isClothing(String category) => const {
    'tops',
    'bottoms',
    'dresses',
    'outerwear',
  }.contains(category.toLowerCase());

  /// How this item really fits the shopper, for the try-on picture: their
  /// size and build, plus the fit check's findings when the shop gave a
  /// size chart.
  String fitNoteForTryOn() {
    final size = selectedSize.value ?? '';
    final check = FitCheck.of(
      SizeChart.fromProduct(data),
      body.value,
      selectedSize: size,
    );
    return [
      body.value.tryOnFitNote(selectedSize: size),
      check.tryOnNote,
    ].where((part) => part.isNotEmpty).join(' ');
  }

  Future<void> openBodyProfile() async {
    await Get.toNamed<void>(AppRoutes.bodyProfile);
    await loadBody();
  }

  void openTryOn({
    required Object imageUrl,
    required Object name,
    required String category,
  }) => Get.to<void>(
    () => AvatarTryOnPage(
      garmentImageUrl: imageUrl as String?,
      garmentName: name as String,
      category: category,
      fitNote: fitNoteForTryOn(),
    ),
  );

  void showAlreadyInWardrobe() => AppToast.say(
    'Already in your Wardrobe. Remove it from the Wardrobe page.',
  );

  /// The heart in the app bar: saved pieces are only removed from the
  /// Wardrobe page.
  Future<void> toggleHeart() async {
    final id = productId;
    if (id == null) return;
    if (isSaved.value) {
      showAlreadyInWardrobe();
      return;
    }
    await _products.addToWardrobe(
      userId: currentUserId,
      productId: id.toString(),
      productData: data,
    );
  }

  Future<void> addToWardrobe() async {
    final id = productId;
    if (id == null) return;
    if (isSaved.value) {
      showAlreadyInWardrobe();
      return;
    }
    try {
      await _products.addToWardrobe(
        userId: currentUserId,
        productId: id.toString(),
        productData: data,
      );
      if (!isClosed) {
        AppToast.show(
          'Added to Wardrobe',
          duration: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      if (!isClosed) AppToast.say('Error: $e');
    }
  }

  Future<void> addToCart({required ConfirmNewBag confirmNewBag}) async {
    final id = productId.toString();
    final size = selectedSize.value;
    try {
      await _cart.addToCart(
        userId: currentUserId,
        productId: id,
        productData: data,
        selectedSize: size,
      );
      if (!isClosed) _showAddedToCart();
    } on CartShopConflictException catch (error) {
      if (isClosed) return;
      if (!await confirmNewBag(error)) return;
      await _cart.clearCart(currentUserId);
      await _cart.addToCart(
        userId: currentUserId,
        productId: id,
        productData: data,
        selectedSize: size,
      );
      if (!isClosed) _showAddedToCart();
    } catch (error) {
      if (!isClosed) AppToast.say('Unable to add to cart: $error');
    }
  }

  void _showAddedToCart() => AppToast.show(
    'Added to cart.',
    actionLabel: 'View Cart',
    onAction: () => Get.toNamed<void>(AppRoutes.cart),
  );

  Future<void> messageSeller({
    required String sellerId,
    required String shopName,
    required String productName,
    String? productImageUrl,
    double? productPrice,
  }) async {
    final id = productId?.toString();
    final chats = ShopChatService();
    final chatId = await chats.ensureConversation(
      sellerId: sellerId,
      customerId: currentUserId,
      shopName: shopName,
      productId: id,
      productName: productName,
      productImageUrl: productImageUrl,
      productPrice: productPrice,
    );
    if (id?.isNotEmpty == true) {
      await chats.addProductReference(
        chatId: chatId,
        productId: id!,
        productName: productName,
        productImageUrl: productImageUrl,
        productPrice: productPrice,
      );
    }
    if (isClosed) return;
    await Get.to<void>(
      () => ShopChatPage(chatId: chatId, title: shopName, asSeller: false),
    );
  }

  /// Deletes the product, closes the dialog and the page.
  Future<void> deleteProduct(String id) async {
    if (isCatalogProduct) {
      await _products.deleteProduct(id);
    } else {
      await _products.deleteUserProduct(
        AppAuth.instance.currentUser?.uid ?? '',
        id,
      );
    }
    if (isClosed) return;
    Get.back<void>(); // Close dialog
    Get.back<void>(); // Go back from detail page
    AppToast.say('Item deleted');
  }

  /// Saves the owner's edits, then closes the edit sheet.
  Future<void> saveEdit(String id, Map<String, dynamic> updated) async {
    if (isCatalogProduct) {
      await _products.updateCatalogProduct(id, updated);
    } else {
      await _products.updateUserProduct(
        userProductId: id,
        userId: AppAuth.instance.currentUser!.uid,
        updatedData: updated,
      );
    }
    product.value = {...data, ...updated};
    if (isClosed) return;
    Get.back<void>();
    AppToast.say('Item updated');
  }
}
