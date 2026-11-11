// Customer-facing product detail screen.
//
// This page shows boutique product metadata, lets customers choose a size,
// adds products to wardrobe/cart, and starts the product-context boutique chat.
// Owners can also edit or delete their own products from here.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/utils/size_inventory.dart';
import 'package:banigoba/modules/profile_details/models/body_profile.dart';
import 'package:banigoba/modules/shop/controllers/product_detail_controller.dart';
import 'package:banigoba/modules/shop/widgets/product_detail_actions.dart';
import 'package:banigoba/modules/shop/widgets/product_detail_rows.dart';
import 'package:banigoba/modules/shop/widgets/product_edit_sheet.dart';
import 'package:banigoba/modules/shop/widgets/product_size_selector.dart';
import 'package:banigoba/modules/shop/widgets/safe_product_image.dart';
import 'package:banigoba/modules/wardrobe/models/fit_check.dart';
import 'package:banigoba/modules/wardrobe/models/piece_details.dart';
import 'package:banigoba/modules/wardrobe/widgets/fit_check_card.dart';

/// Screen displaying detailed information about a product
class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({
    super.key,
    this.productId,
    required this.productData,
    this.loadBodyProfile,
  });

  final String? productId;
  final Map<String, dynamic> productData;

  /// Injected in tests; defaults to the signed-in user's saved measurements.
  final Future<BodyProfile> Function()? loadBodyProfile;

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: it is opened with a product, not by route name.
    return GetBuilder<ProductDetailController>(
      init: ProductDetailController(
        productId: productId,
        productData: productData,
        loadBodyProfile: loadBodyProfile,
      ),
      global: false,
      builder: (controller) => _ProductDetailView(controller: controller),
    );
  }
}

class _ProductDetailView extends StatelessWidget {
  const _ProductDetailView({required this.controller});

  final ProductDetailController controller;

  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text(
          "Are you sure you want to delete '$name'? This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => controller.deleteProduct(id),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final data = controller.data;
      final imageUrl = data['imageUrl'] ?? data['imageURL'] ?? '';
      final rawImageUrl = data['rawImageUrl'] ?? imageUrl;
      final name = data['name'] ?? 'No Name';
      final String category = data['category'] ?? 'N/A';
      final String subcategory = data['subcategory'] ?? 'N/A';
      final String styleTag = data['styleTag'] ?? data['style'] ?? 'casual';

      // Normalize colour data for display.
      final dynamic rawColours = data['colours'] ?? data['colour'];
      var coloursList = <dynamic>[];
      if (rawColours is List) {
        coloursList = rawColours;
      } else if (rawColours != null && rawColours.toString().isNotEmpty) {
        coloursList = [rawColours];
      }
      final colourDisplay = coloursList.isNotEmpty
          ? coloursList
                .map((c) {
                  final s = c.toString().trim();
                  if (s.isEmpty) return s;
                  return s[0].toUpperCase() + s.substring(1).toLowerCase();
                })
                .join(', ')
          : 'N/A';

      final gender = data['gender'] ?? 'N/A';
      final visibility = data['visibility'] ?? 'private';
      final price = (data['price'] as num?)?.toDouble() ?? 0;
      final sizeInventory = parseSizeInventory(data);
      // Only sizes with available stock are selectable.
      final availableSizes = [
        for (final entry in sizeInventory.entries)
          if (entry.value > 0) entry.key,
      ];
      final hasSizes = sizeInventory.isNotEmpty;
      final stock = hasSizes
          ? sizeInventory.values.fold<int>(0, (total, q) => total + q)
          : (data['stock'] as num?)?.toInt() ?? 0;
      final shopName = (data['shopName'] ?? '').toString();
      final pieceDetails = PieceDetails.fromMap(data);
      final productId = controller.productId;
      final isMe = controller.isMe;
      final colors = Theme.of(context).colorScheme;

      return Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          title: Text(name),
          backgroundColor: colors.surface,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            if (isMe && productId != null) ...[
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => showProductEditSheet(
                  context,
                  product: data,
                  isCatalog: controller.isCatalogProduct,
                  onSave: (updated) =>
                      controller.saveEdit(productId.toString(), updated),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () =>
                    _confirmDelete(context, productId.toString(), '$name'),
              ),
            ],
            if (!isMe && productId != null)
              IconButton(
                icon: Icon(
                  controller.isSaved.value
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: controller.isSaved.value ? Colors.red : Colors.black,
                ),
                tooltip: controller.isSaved.value
                    ? 'In your Wardrobe'
                    : 'Add to Wardrobe',
                onPressed: controller.toggleHeart,
              ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    _posterRow(),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
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
                      ProductDetailRow('Boutique', shopName),
                    if (data.containsKey('stock'))
                      ProductDetailRow(
                        'Availability',
                        stock > 0 ? '$stock in stock' : 'Out of stock',
                      ),
                    if (hasSizes)
                      ProductSizeSelector(
                        sizes: availableSizes,
                        selected: controller.selectedSize.value,
                        onSelected: controller.chooseSize,
                      ),
                    if (!isMe && ProductDetailController.isClothing(category))
                      FitCheckCard(
                        chart: SizeChart.fromProduct(data),
                        body: controller.body.value,
                        selectedSize: controller.selectedSize.value ?? '',
                        availableSizes: availableSizes,
                        onChooseSize: controller.chooseSize,
                        onAddMeasurements: controller.openBodyProfile,
                      ),
                    ProductDetailRow('Category', category),
                    ProductDetailRow('Subcategory', subcategory),
                    ProductDetailRow('Style', styleTag),
                    ProductDetailRow('Colours', colourDisplay),
                    ProductDetailRow('Gender', gender),
                    if (data.containsKey('visibility'))
                      ProductDetailRow('Visibility', visibility),
                    ProductPieceDetails(pieceDetails),
                    if (data.containsKey('weatherTags'))
                      ProductTagsRow(
                        'Weather',
                        List<String>.from(data['weatherTags'] ?? []),
                      ),
                    if (data.containsKey('functionalTags'))
                      ProductTagsRow(
                        'Functional',
                        List<String>.from(data['functionalTags'] ?? []),
                      ),
                    ProductDetailActions(
                      controller: controller,
                      imageUrl: imageUrl,
                      name: name,
                      category: category,
                      price: price,
                      shopName: shopName,
                      stock: stock,
                      hasSizes: hasSizes,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// "Uploaded by: …", once the uploader's profile has loaded.
  Widget _posterRow() {
    if (controller.uploaderId == null) return const SizedBox.shrink();
    final user = controller.poster.value;
    if (user.isEmpty) return const SizedBox.shrink();
    final isAdmin = user['role'] == 'admin' || user['isAdmin'] == true;
    final isMe = controller.isMe;
    if (isAdmin && !isMe) return const SizedBox.shrink();
    final posterName = user['displayName'] ?? 'User';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          const Text('Uploaded by: ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              isMe ? 'You' : '$posterName',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D0140),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
