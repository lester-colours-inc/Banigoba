// Customer-facing product detail screen.
//
// This page shows boutique product metadata, lets customers choose a size,
// adds products to wardrobe/cart, and starts the product-context boutique chat.
// Owners can also edit or delete their own products from here.
import 'package:flutter/material.dart';
import '../../../core/supabase/app_auth.dart';
import '../../../data/services/profile_service.dart';
import '../../../core/app_routes.dart';
import '../../../data/models/body_profile.dart';
import '../../../data/models/fit_check.dart';
import '../../../data/models/piece_details.dart';
import '../../../data/services/body_profile_service.dart';
import '../../../data/services/cart_service.dart';
import '../../../data/services/product_service.dart';
import '../../../data/services/shop_chat_service.dart';
import '../../../data/utils/size_inventory.dart';
import '../../widgets/fit_check_card.dart';
import '../../widgets/safe_product_image.dart';
import '../makeover/avatar_try_on_page.dart';
import 'shop_chat_page.dart';

/// Screen displaying detailed information about a product
class ProductDetailPage extends StatefulWidget {
  final String? productId;
  final Map<String, dynamic> productData;

  /// Injected in tests; defaults to the signed-in user's saved measurements.
  final Future<BodyProfile> Function()? loadBodyProfile;

  const ProductDetailPage({
    super.key,
    this.productId,
    required this.productData,
    this.loadBodyProfile,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Map<String, dynamic> _currentProductData;
  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();
  String? _selectedSize;

  /// The shopper's saved measurements, for the fit check and the try-on.
  BodyProfile _body = const BodyProfile();

  @override
  void initState() {
    super.initState();
    _loadBodyProfile();
    _currentProductData = Map<String, dynamic>.from(widget.productData);
    if (widget.productId != null) {
      _currentProductData['id'] = widget.productId;
    }
  }

  Future<void> _loadBodyProfile() async {
    try {
      final body =
          await (widget.loadBodyProfile ??
              BodyProfileService().loadForCurrentUser)();
      if (mounted) setState(() => _body = body);
    } on Exception catch (error) {
      // No fit check without measurements; the page still works.
      debugPrint('Unable to load measurements: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = AppAuth.instance.currentUser?.uid ?? '';

    // Extract display data with fallbacks
    final imageUrl =
        _currentProductData['imageUrl'] ??
        _currentProductData['imageURL'] ??
        '';
    final rawImageUrl = _currentProductData['rawImageUrl'] ?? imageUrl;
    final name = _currentProductData['name'] ?? 'No Name';
    final String category = _currentProductData['category'] ?? 'N/A';
    final String subcategory = _currentProductData['subcategory'] ?? 'N/A';
    final String styleTag =
        _currentProductData['styleTag'] ??
        _currentProductData['style'] ??
        'casual';

    // Normalize color data for display
    final dynamic rawColours =
        _currentProductData['colours'] ?? _currentProductData['colour'];
    List<dynamic> coloursList = [];
    if (rawColours is List) {
      coloursList = rawColours;
    } else if (rawColours != null && rawColours.toString().isNotEmpty) {
      coloursList = [rawColours];
    }

    final String colourDisplay = coloursList.isNotEmpty
        ? coloursList
              .map((c) {
                final s = c.toString().trim();
                if (s.isEmpty) return s;
                return s[0].toUpperCase() + s.substring(1).toLowerCase();
              })
              .join(', ')
        : 'N/A';

    final gender = _currentProductData['gender'] ?? 'N/A';
    final visibility = _currentProductData['visibility'] ?? 'private';
    final price = (_currentProductData['price'] as num?)?.toDouble() ?? 0;
    final sizeInventory = parseSizeInventory(_currentProductData);
    // Only sizes with available stock are selectable. The display hides exact
    // inventory counts, but the values still gate add-to-cart.
    final availableSizes = sizeInventory.entries
        .where((entry) => entry.value > 0)
        .toList();
    final hasSizes = sizeInventory.isNotEmpty;
    final stock = hasSizes
        ? sizeInventory.values.fold<int>(
            0,
            (total, quantity) => total + quantity,
          )
        : (_currentProductData['stock'] as num?)?.toInt() ?? 0;
    final shopName = (_currentProductData['shopName'] ?? '').toString();
    final pieceDetails = PieceDetails.fromMap(_currentProductData);

    // Identify the product ID and uploader
    final String? originalProductId = _currentProductData['originalProductId'];
    final String? uploaderId =
        _currentProductData['userId'] ?? _currentProductData['uploaderId'];

    final productId = _currentProductData['id'] ?? originalProductId;

    // Check if current user is the owner
    final bool isMe = uploaderId == currentUserId;

    // Determine if it's a catalog product or user product copy
    final bool isCatalogProduct =
        _currentProductData.containsKey('uploaderId') &&
        originalProductId == null;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Edit/Delete for owner
          if (isMe && productId != null) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showEditDialog(productId, isCatalogProduct),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () =>
                  _confirmDelete(productId, name, isCatalogProduct),
            ),
          ],
          // Favourite (Heart) icon
          if (!isMe && productId != null)
            StreamBuilder<bool>(
              stream: _productService.isInWardrobe(currentUserId, productId),
              builder: (context, snapshot) {
                final isSaved = snapshot.data ?? false;
                return IconButton(
                  icon: Icon(
                    isSaved ? Icons.favorite : Icons.favorite_border,
                    color: isSaved ? Colors.red : Colors.black,
                  ),
                  onPressed: () => _productService.toggleWardrobeItem(
                    userId: currentUserId,
                    productId: productId,
                    productData: _currentProductData,
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            AspectRatio(
              aspectRatio: 1,
              child: SafeProductImage(
                imageUrl: rawImageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                iconSize: 100,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster Name
                  if (uploaderId != null)
                    StreamBuilder<Map<String, dynamic>>(
                      stream: ProfileService().watch(uploaderId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final userData = snapshot.data!;
                        final bool isAdmin =
                            userData['role'] == 'admin' ||
                            userData['isAdmin'] == true;
                        if (isAdmin && !isMe) return const SizedBox.shrink();

                        final posterName = userData['displayName'] ?? 'User';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            children: [
                              Text(
                                isMe ? "Uploaded by: " : "Uploaded by: ",
                                style: TextStyle(color: Colors.grey),
                              ),
                              Expanded(
                                child: Text(
                                  isMe ? "You" : posterName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D0140),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  // Product Name and Details
                  Text(
                    name,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (price > 0)
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF0D0140),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (shopName.isNotEmpty)
                    _buildDetailRow("Boutique", shopName),
                  if (_currentProductData.containsKey('stock'))
                    _buildDetailRow(
                      "Availability",
                      stock > 0 ? '$stock in stock' : 'Out of stock',
                    ),
                  if (hasSizes) _buildSizeSelector(availableSizes),
                  if (!isMe && _isClothing(category))
                    FitCheckCard(
                      chart: SizeChart.fromProduct(_currentProductData),
                      body: _body,
                      selectedSize: _selectedSize ?? '',
                      availableSizes: [
                        for (final entry in availableSizes) entry.key,
                      ],
                      onChooseSize: (size) =>
                          setState(() => _selectedSize = size),
                      onAddMeasurements: () => Navigator.pushNamed(
                        context,
                        AppRoutes.bodyProfile,
                      ).then((_) => _loadBodyProfile()),
                    ),
                  _buildDetailRow("Category", category),
                  _buildDetailRow("Subcategory", subcategory),
                  _buildDetailRow("Style", styleTag),
                  _buildDetailRow("Colours", colourDisplay),
                  _buildDetailRow("Gender", gender),
                  if (_currentProductData.containsKey('visibility'))
                    _buildDetailRow("Visibility", visibility),
                  ..._buildPieceDetails(pieceDetails),

                  // Weather and Functional Tags
                  if (_currentProductData.containsKey('weatherTags'))
                    _buildTagsRow(
                      "Weather",
                      List<String>.from(
                        _currentProductData['weatherTags'] ?? [],
                      ),
                    ),
                  if (_currentProductData.containsKey('functionalTags'))
                    _buildTagsRow(
                      "Functional",
                      List<String>.from(
                        _currentProductData['functionalTags'] ?? [],
                      ),
                    ),

                  const SizedBox(height: 30),
                  // Generate a virtual try-on using the user's saved avatar.
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AvatarTryOnPage(
                              garmentImageUrl: imageUrl,
                              garmentName: name,
                              category: category,
                              fitNote: _fitNoteForTryOn(),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D0140),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Try On",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Add to Wardrobe button
                  if (!isMe && productId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: StreamBuilder<bool>(
                        stream: _productService.isInWardrobe(
                          currentUserId,
                          productId,
                        ),
                        builder: (context, snapshot) {
                          final isSaved = snapshot.data ?? false;
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await _productService.toggleWardrobeItem(
                                    userId: currentUserId,
                                    productId: productId,
                                    productData: _currentProductData,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isSaved
                                              ? "Removed from Wardrobe"
                                              : "Added to Wardrobe",
                                        ),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Error: $e")),
                                    );
                                  }
                                }
                              },
                              icon: Icon(
                                isSaved
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isSaved ? Colors.red : Colors.white,
                              ),
                              label: Text(
                                isSaved
                                    ? "In Your Wardrobe"
                                    : "Add to Wardrobe",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSaved
                                    ? const Color(
                                        0xFF0D0140,
                                      ).withValues(alpha: 0.8)
                                    : const Color(0xFF0D0140),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (!isMe && productId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: currentUserId.isEmpty
                              ? null
                              : stock <= 0 &&
                                    _currentProductData.containsKey('stock')
                              ? null
                              : hasSizes && _selectedSize == null
                              ? null
                              : () => _addToCartWithShopGuard(
                                  userId: currentUserId,
                                  productId: productId.toString(),
                                  selectedSize: _selectedSize,
                                ),
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Add to Cart'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            foregroundColor: const Color(0xFF0D0140),
                            side: const BorderSide(color: Color(0xFF0D0140)),
                          ),
                        ),
                      ),
                    ),
                  if (!isMe &&
                      uploaderId != null &&
                      uploaderId.isNotEmpty &&
                      shopName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: currentUserId.isEmpty
                              ? null
                              : () => _messageSeller(
                                  sellerId: uploaderId,
                                  customerId: currentUserId,
                                  shopName: shopName,
                                  productId: productId?.toString(),
                                  productName: name.toString(),
                                  productImageUrl: imageUrl.toString(),
                                  productPrice: price > 0 ? price : null,
                                ),
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Ask Boutique About This Product'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _messageSeller({
    required String sellerId,
    required String customerId,
    required String shopName,
    required String? productId,
    required String productName,
    String? productImageUrl,
    double? productPrice,
  }) async {
    final chatId = await ShopChatService().ensureConversation(
      sellerId: sellerId,
      customerId: customerId,
      shopName: shopName,
      productId: productId,
      productName: productName,
      productImageUrl: productImageUrl,
      productPrice: productPrice,
    );
    if (productId?.isNotEmpty == true) {
      await ShopChatService().addProductReference(
        chatId: chatId,
        productId: productId!,
        productName: productName,
        productImageUrl: productImageUrl,
        productPrice: productPrice,
      );
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            ShopChatPage(chatId: chatId, title: shopName, asSeller: false),
      ),
    );
  }

  static bool _isClothing(String category) => const {
    'tops',
    'bottoms',
    'dresses',
    'outerwear',
  }.contains(category.toLowerCase());

  /// How this item really fits the shopper, for the try-on picture: their
  /// size and build, plus the fit check's findings when the shop gave a
  /// size chart.
  String _fitNoteForTryOn() {
    final size = _selectedSize ?? '';
    final check = FitCheck.of(
      SizeChart.fromProduct(_currentProductData),
      _body,
      selectedSize: size,
    );
    return [
      _body.tryOnFitNote(selectedSize: size),
      check.tryOnNote,
    ].where((part) => part.isNotEmpty).join(' ');
  }

  Future<void> _addToCartWithShopGuard({
    required String userId,
    required String productId,
    String? selectedSize,
  }) async {
    try {
      await _cartService.addToCart(
        userId: userId,
        productId: productId,
        productData: _currentProductData,
        selectedSize: selectedSize,
      );
      if (!mounted) return;
      _showAddedToCartMessage();
    } on CartShopConflictException catch (error) {
      if (!mounted) return;
      final shouldClear = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Start a new bag?'),
          content: Text(
            'Your bag has items from ${error.currentShopName}. Clear it and start a new bag for ${error.newShopName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep Bag'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear & Add'),
            ),
          ],
        ),
      );
      if (shouldClear != true) return;

      await _cartService.clearCart(userId);
      await _cartService.addToCart(
        userId: userId,
        productId: productId,
        productData: _currentProductData,
        selectedSize: selectedSize,
      );
      if (!mounted) return;
      _showAddedToCartMessage();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to add to cart: $error')));
    }
  }

  void _showAddedToCartMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added to cart.'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
        ),
      ),
    );
  }

  Widget _buildSizeSelector(List<MapEntry<String, int>> availableSizes) {
    // The customer only sees size labels; quantities stay hidden but still
    // drive stock checks when adding to cart and placing an order.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Size:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (availableSizes.isEmpty)
            Text(
              'No sizes available',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableSizes.map((entry) {
                final selected = _selectedSize == entry.key;
                return ChoiceChip(
                  label: Text(entry.key),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedSize = entry.key),
                  selectedColor: const Color(0xFF0D0140).withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: selected ? const Color(0xFF0D0140) : null,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  /// The seller's measurement, fabric, origin and extra-detail fields, each
  /// only shown when the seller actually filled it in.
  List<Widget> _buildPieceDetails(PieceDetails details) {
    return [
      if (details.shoulderMeasurement.isNotEmpty)
        _buildDetailRow(
          "Shoulder Measurement",
          '${details.shoulderMeasurement} cm',
        ),
      if (details.heightMeasurement.isNotEmpty)
        _buildDetailRow(
          "Height Measurement",
          '${details.heightMeasurement} cm',
        ),
      if (details.linenType.isNotEmpty)
        _buildDetailRow("Linen Type", details.linenType),
      if (details.madeWhere.isNotEmpty)
        _buildDetailRow("Made Where", details.madeWhere),
      if (details.otherDetails.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Other Details",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 5),
              for (final detail in details.otherDetails)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('• $detail'),
                ),
            ],
          ),
        ),
    ];
  }

  /// Helper for building tag chips
  Widget _buildTagsRow(String label, List<String> tags) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label Tags:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 8,
            children: tags
                .map(
                  (tag) => Chip(
                    label: Text(tag[0].toUpperCase() + tag.substring(1)),
                    backgroundColor: const Color(
                      0xFF0D0140,
                    ).withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF0D0140),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  /// Confirm deletion
  void _confirmDelete(String id, String name, bool isCatalog) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Item?"),
        content: Text(
          "Are you sure you want to delete '$name'? This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final String currentUserId =
                  AppAuth.instance.currentUser?.uid ?? '';
              if (isCatalog) {
                await _productService.deleteProduct(id);
              } else {
                await _productService.deleteUserProduct(currentUserId, id);
              }
              if (!mounted || !dialogContext.mounted) return;
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Go back from detail page
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Item deleted")));
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Show edit dialog
  void _showEditDialog(String id, bool isCatalog) {
    final nameController = TextEditingController(
      text: _currentProductData['name'],
    );
    String styleTag =
        _currentProductData['styleTag'] ??
        _currentProductData['style'] ??
        'casual';
    String visibility = _currentProductData['visibility'] ?? 'private';
    List<String> selectedColours = List<String>.from(
      _currentProductData['colours'] ?? [],
    );
    List<String> selectedWeatherTags = List<String>.from(
      _currentProductData['weatherTags'] ?? [],
    );
    List<String> selectedFunctionalTags = List<String>.from(
      _currentProductData['functionalTags'] ?? [],
    );

    final List<String> availableColors = [
      'black',
      'white',
      'grey',
      'blue',
      'red',
      'green',
      'yellow',
      'orange',
      'pink',
      'purple',
      'brown',
      'beige',
    ];
    final List<String> styleTags = [
      'casual',
      'afrochic',
      'corporate',
      'streetwear',
      'glamour',
    ];
    final List<String> weatherTags = ["hot", "mild", "cool", "cold", "rainy"];
    final List<String> functionalTags = [
      "waterproof",
      "breathable",
      "insulated",
      "windproof",
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Edit Item",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  initialValue: styleTag,
                  decoration: const InputDecoration(
                    labelText: "Style",
                    border: OutlineInputBorder(),
                  ),
                  items: styleTags
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(_formatLabel(v)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setModalState(() => styleTag = v!),
                ),
                const SizedBox(height: 15),
                if (!isCatalog)
                  DropdownButtonFormField<String>(
                    initialValue: visibility,
                    decoration: const InputDecoration(
                      labelText: "Visibility",
                      border: OutlineInputBorder(),
                    ),
                    items: ['private', 'public']
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(v.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setModalState(() => visibility = v!),
                  ),
                const SizedBox(height: 15),
                const Text(
                  "Colours",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  children: availableColors
                      .map(
                        (color) => FilterChip(
                          label: Text(color),
                          selected: selectedColours.contains(color),
                          onSelected: (selected) => setModalState(() {
                            if (selected) {
                              selectedColours.add(color);
                            } else {
                              selectedColours.remove(color);
                            }
                          }),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Weather Tags",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  children: weatherTags
                      .map(
                        (tag) => FilterChip(
                          label: Text(tag),
                          selected: selectedWeatherTags.contains(tag),
                          onSelected: (selected) => setModalState(() {
                            if (selected) {
                              selectedWeatherTags.add(tag);
                            } else {
                              selectedWeatherTags.remove(tag);
                            }
                          }),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Functional Tags",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  children: functionalTags
                      .map(
                        (tag) => FilterChip(
                          label: Text(tag),
                          selected: selectedFunctionalTags.contains(tag),
                          onSelected: (selected) => setModalState(() {
                            if (selected) {
                              selectedFunctionalTags.add(tag);
                            } else {
                              selectedFunctionalTags.remove(tag);
                            }
                          }),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D0140),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () async {
                      final updated = {
                        'name': nameController.text,
                        'styleTag': styleTag,
                        'colours': selectedColours,
                        'weatherTags': selectedWeatherTags,
                        'functionalTags': selectedFunctionalTags,
                        if (!isCatalog) 'visibility': visibility,
                      };

                      if (isCatalog) {
                        await _productService.updateCatalogProduct(id, updated);
                      } else {
                        await _productService.updateUserProduct(
                          userProductId: id,
                          userId: AppAuth.instance.currentUser!.uid,
                          updatedData: updated,
                        );
                      }

                      setState(() {
                        _currentProductData.addAll(updated);
                      });

                      if (!mounted) return;
                      Navigator.pop(this.context);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text("Item updated")),
                      );
                    },
                    child: const Text(
                      "Save Changes",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper to build a simple label-value row
  String _formatLabel(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  /// Helper to build a simple label-value row
  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    String displayValue = value;
    try {
      displayValue = value[0].toUpperCase() + value.substring(1);
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(child: Text(displayValue, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
