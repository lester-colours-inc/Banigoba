// The buttons under a product's details: try on, wardrobe, cart, boutique chat.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/shop/controllers/product_detail_controller.dart';
import 'package:banigoba/modules/shop/services/cart_service.dart';

const Color _primary = Color(0xFF0D0140);

class ProductDetailActions extends StatelessWidget {
  const ProductDetailActions({
    super.key,
    required this.controller,
    required this.imageUrl,
    required this.name,
    required this.category,
    required this.price,
    required this.shopName,
    required this.stock,
    required this.hasSizes,
  });

  final ProductDetailController controller;
  final Object imageUrl;
  final Object name;
  final String category;
  final double price;
  final String shopName;
  final int stock;
  final bool hasSizes;

  Future<bool> _confirmNewBag(
    BuildContext context,
    CartShopConflictException error,
  ) async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a new bag?'),
        content: Text(
          'Your bag has items from ${error.currentShopName}. Clear it and '
          'start a new bag for ${error.newShopName}?',
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
    return clear == true;
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final productId = c.productId;
    final uploaderId = c.uploaderId;
    final signedOut = c.currentUserId.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        // Generate a virtual try-on using the user's saved avatar.
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () =>
                c.openTryOn(imageUrl: imageUrl, name: name, category: category),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Try On',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (!c.isMe && productId != null)
          Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: Obx(() {
              final saved = c.isSaved.value;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: c.addToWardrobe,
                  icon: Icon(
                    saved ? Icons.favorite : Icons.favorite_border,
                    color: saved ? Colors.red : Colors.white,
                  ),
                  label: Text(
                    saved ? 'In Your Wardrobe' : 'Add to Wardrobe',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: saved
                        ? _primary.withValues(alpha: 0.8)
                        : _primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              );
            }),
          ),
        if (!c.isMe && productId != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              width: double.infinity,
              child: Obx(
                () => OutlinedButton.icon(
                  onPressed:
                      signedOut ||
                          (stock <= 0 && c.data.containsKey('stock')) ||
                          (hasSizes && c.selectedSize.value == null)
                      ? null
                      : () => c.addToCart(
                          confirmNewBag: (error) =>
                              _confirmNewBag(context, error),
                        ),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Add to Cart'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    foregroundColor: _primary,
                    side: const BorderSide(color: _primary),
                  ),
                ),
              ),
            ),
          ),
        if (!c.isMe &&
            uploaderId != null &&
            uploaderId.isNotEmpty &&
            shopName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: signedOut
                    ? null
                    : () => c.messageSeller(
                        sellerId: uploaderId,
                        shopName: shopName,
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
    );
  }
}
