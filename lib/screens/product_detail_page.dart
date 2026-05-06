import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/product_service.dart';
import 'camera_screen.dart';

/// Screen displaying detailed information about a product
class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> productData;

  const ProductDetailPage({super.key, required this.productData});

  @override
  Widget build(BuildContext context) {
    final ProductService productService = ProductService();
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    // Extract display data with fallbacks
    final imageUrl = productData['imageUrl'] ?? productData['imageURL'] ?? '';
    final name = productData['name'] ?? 'No Name';
    final String category = productData['category'] ?? 'N/A';
    final String subcategory = productData['subcategory'] ?? 'N/A';
    
    // Normalize color data for display (handling both single string and array)
    final dynamic rawColours = productData['colours'] ?? productData['colour'];
    List<dynamic> coloursList = [];
    if (rawColours is List) {
      coloursList = rawColours;
    } else if (rawColours != null && rawColours.toString().isNotEmpty) {
      coloursList = [rawColours];
    }

    final String colourDisplay = coloursList.isNotEmpty
        ? coloursList.map((c) {
            final s = c.toString().trim();
            if (s.isEmpty) return s;
            return s[0].toUpperCase() + s.substring(1).toLowerCase();
          }).join(', ')
        : 'N/A';

    final gender = productData['gender'] ?? 'N/A';
    final visibility = productData['visibility'] ?? 'private';
    final posterId = productData['userId'];
    
    // Identify the product ID correctly (original vs local copy)
    final String? originalProductId = productData['originalProductId'];
    final productId = originalProductId ?? productData['id'];

    final bool isMe = posterId == currentUserId;
    // Show favourite button if it's not our own upload, or if it's a saved copy
    final bool isFavouriteInWardrobe = isMe && originalProductId != null;
    final bool showFavouriteButton = !isMe || isFavouriteInWardrobe;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Favourite (Heart) icon in AppBar
          if (showFavouriteButton && productId != null)
            StreamBuilder<bool>(
              stream: productService.isInWardrobe(currentUserId, productId),
              builder: (context, snapshot) {
                final isSaved = snapshot.data ?? false;
                return IconButton(
                  icon: Icon(
                    isSaved ? Icons.favorite : Icons.favorite_border,
                    color: isSaved ? Colors.red : Colors.black,
                  ),
                  onPressed: () => productService.toggleWardrobeItem(
                    userId: currentUserId,
                    productId: productId,
                    productData: productData,
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
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity)
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, size: 100, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster Name
                  if (posterId != null)
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(posterId).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
                        final userData = snapshot.data!.data() as Map<String, dynamic>;
                        final posterName = userData['displayName'] ?? 'User';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            children: [
                              const Text("Posted by: ", style: TextStyle(color: Colors.grey)),
                              Text(posterName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D0140))),
                            ],
                          ),
                        );
                      },
                    ),
                  // Product Name and Details
                  Text(
                    name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow("Category", category),
                  _buildDetailRow("Subcategory", subcategory),
                  _buildDetailRow("Colours", colourDisplay),
                  _buildDetailRow("Gender", gender),
                  _buildDetailRow("Visibility", visibility),
                  const SizedBox(height: 30),
                  // Try On (AR) Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CameraScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D0140),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        "Try On",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // Add to Wardrobe Primary Action Button
                  if (showFavouriteButton && productId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: StreamBuilder<bool>(
                        stream: productService.isInWardrobe(currentUserId, productId),
                        builder: (context, snapshot) {
                          final isSaved = snapshot.data ?? false;
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await productService.toggleWardrobeItem(
                                    userId: currentUserId,
                                    productId: productId,
                                    productData: productData,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isSaved ? "Removed from Wardrobe" : "Added to Wardrobe"),
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
                                isSaved ? Icons.favorite : Icons.favorite_border,
                                color: isSaved ? Colors.red : Colors.white,
                              ),
                              label: Text(
                                isSaved ? "In Your Wardrobe" : "Add to Wardrobe",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSaved ? const Color(0xFF0D0140).withValues(alpha: 0.8) : const Color(0xFF0D0140),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                            ),
                          );
                        },
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
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            displayValue,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
