import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/product_service.dart';
import '../onboarding/camera_screen.dart';

/// Screen displaying detailed information about a product
class ProductDetailPage extends StatefulWidget {
  final String? productId;
  final Map<String, dynamic> productData;

  const ProductDetailPage({super.key, this.productId, required this.productData});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Map<String, dynamic> _currentProductData;
  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    _currentProductData = Map<String, dynamic>.from(widget.productData);
    if (widget.productId != null) {
      _currentProductData['id'] = widget.productId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    // Extract display data with fallbacks
    final imageUrl = _currentProductData['imageUrl'] ?? _currentProductData['imageURL'] ?? '';
    final rawImageUrl = _currentProductData['rawImageUrl'] ?? imageUrl;
    final name = _currentProductData['name'] ?? 'No Name';
    final String category = _currentProductData['category'] ?? 'N/A';
    final String subcategory = _currentProductData['subcategory'] ?? 'N/A';
    final String styleTag = _currentProductData['styleTag'] ?? _currentProductData['style'] ?? 'casual';
    
    // Normalize color data for display
    final dynamic rawColours = _currentProductData['colours'] ?? _currentProductData['colour'];
    List<dynamic> coloursList = [];
    if (rawColours is List) coloursList = rawColours;
    else if (rawColours != null && rawColours.toString().isNotEmpty) coloursList = [rawColours];

    final String colourDisplay = coloursList.isNotEmpty
        ? coloursList.map((c) {
            final s = c.toString().trim();
            if (s.isEmpty) return s;
            return s[0].toUpperCase() + s.substring(1).toLowerCase();
          }).join(', ')
        : 'N/A';

    final gender = _currentProductData['gender'] ?? 'N/A';
    final visibility = _currentProductData['visibility'] ?? 'private';
    
    // Identify the product ID and uploader
    final String? originalProductId = _currentProductData['originalProductId'];
    final String? originalPosterId = _currentProductData['originalPosterId'];
    final String? uploaderId = _currentProductData['userId'] ?? _currentProductData['uploaderId'];
    
    final productId = _currentProductData['id'] ?? originalProductId;

    // Check if current user is the owner
    final bool isMe = uploaderId == currentUserId;
    
    // Determine if it's a catalog product or user product copy
    final bool isCatalogProduct = _currentProductData.containsKey('uploaderId') && originalProductId == null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.white,
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
              onPressed: () => _confirmDelete(productId, name, isCatalogProduct),
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
              child: rawImageUrl.isNotEmpty
                  ? Image.network(rawImageUrl, fit: BoxFit.contain, width: double.infinity)
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
                  if (uploaderId != null)
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(uploaderId).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
                        final userData = snapshot.data!.data() as Map<String, dynamic>;
                        final bool isAdmin = userData['role'] == 'admin' || userData['isAdmin'] == true;
                        if (isAdmin && !isMe) return const SizedBox.shrink();

                        final posterName = userData['displayName'] ?? 'User';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            children: [
                              Text(isMe ? "Uploaded by: " : "Uploaded by: ", style: const TextStyle(color: Colors.grey)),
                              Expanded(
                                child: Text(
                                  isMe ? "You" : posterName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D0140)),
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
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow("Category", category),
                  _buildDetailRow("Subcategory", subcategory),
                  _buildDetailRow("Style", styleTag),
                  _buildDetailRow("Colours", colourDisplay),
                  _buildDetailRow("Gender", gender),
                  if (_currentProductData.containsKey('visibility'))
                    _buildDetailRow("Visibility", visibility),
                  
                  // Weather and Functional Tags
                  if (_currentProductData.containsKey('weatherTags'))
                    _buildTagsRow("Weather", List<String>.from(_currentProductData['weatherTags'] ?? [])),
                  if (_currentProductData.containsKey('functionalTags'))
                    _buildTagsRow("Functional", List<String>.from(_currentProductData['functionalTags'] ?? [])),
                  
                  const SizedBox(height: 30),
                  // Try On (AR) Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CameraScreen(
                              imageUrl: imageUrl,
                              category: category,
                            ),
                          ),
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
                  // Add to Wardrobe button
                  if (!isMe && productId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: StreamBuilder<bool>(
                        stream: _productService.isInWardrobe(currentUserId, productId),
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

  /// Helper for building tag chips
  Widget _buildTagsRow(String label, List<String> tags) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label Tags:", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 5),
          Wrap(
            spacing: 8,
            children: tags.map((tag) => Chip(
              label: Text(tag[0].toUpperCase() + tag.substring(1)),
              backgroundColor: const Color(0xFF0D0140).withValues(alpha: 0.1),
              labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF0D0140)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  /// Confirm deletion
  void _confirmDelete(String id, String name, bool isCatalog) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Item?"),
        content: Text("Are you sure you want to delete '$name'? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
              if (isCatalog) {
                await _productService.deleteProduct(id);
              } else {
                await _productService.deleteUserProduct(currentUserId, id);
              }
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back from detail page
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item deleted")));
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Show edit dialog
  void _showEditDialog(String id, bool isCatalog) {
    final nameController = TextEditingController(text: _currentProductData['name']);
    String category = _currentProductData['category'] ?? 'tops';
    String styleTag = _currentProductData['styleTag'] ?? _currentProductData['style'] ?? 'casual';
    String visibility = _currentProductData['visibility'] ?? 'private';
    List<String> selectedColours = List<String>.from(_currentProductData['colours'] ?? []);
    List<String> selectedWeatherTags = List<String>.from(_currentProductData['weatherTags'] ?? []);
    List<String> selectedFunctionalTags = List<String>.from(_currentProductData['functionalTags'] ?? []);

    final List<String> availableColors = ['black', 'white', 'grey', 'blue', 'red', 'green', 'yellow', 'orange', 'pink', 'purple', 'brown', 'beige'];
    final List<String> styleTags = ['casual', 'afrochic', 'corporate', 'streetwear', 'glamour'];
    final List<String> weatherTags = ["hot", "mild", "cool", "cold", "rainy"];
    final List<String> functionalTags = ["waterproof", "breathable", "insulated", "windproof"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Edit Item", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name", border: OutlineInputBorder())),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: styleTag,
                  decoration: const InputDecoration(labelText: "Style", border: OutlineInputBorder()),
                  items: styleTags.map((v) => DropdownMenuItem(value: v, child: Text(_formatLabel(v)))).toList(),
                  onChanged: (v) => setModalState(() => styleTag = v!),
                ),
                const SizedBox(height: 15),
                if (!isCatalog)
                  DropdownButtonFormField<String>(
                    value: visibility,
                    decoration: const InputDecoration(labelText: "Visibility", border: OutlineInputBorder()),
                    items: ['private', 'public'].map((v) => DropdownMenuItem(value: v, child: Text(v.toUpperCase()))).toList(),
                    onChanged: (v) => setModalState(() => visibility = v!),
                  ),
                const SizedBox(height: 15),
                const Text("Colours", style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: availableColors.map((color) => FilterChip(
                    label: Text(color),
                    selected: selectedColours.contains(color),
                    onSelected: (selected) => setModalState(() {
                      if (selected) selectedColours.add(color); else selectedColours.remove(color);
                    }),
                  )).toList(),
                ),
                const SizedBox(height: 15),
                const Text("Weather Tags", style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: weatherTags.map((tag) => FilterChip(
                    label: Text(tag),
                    selected: selectedWeatherTags.contains(tag),
                    onSelected: (selected) => setModalState(() {
                      if (selected) selectedWeatherTags.add(tag); else selectedWeatherTags.remove(tag);
                    }),
                  )).toList(),
                ),
                const SizedBox(height: 15),
                const Text("Functional Tags", style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: functionalTags.map((tag) => FilterChip(
                    label: Text(tag),
                    selected: selectedFunctionalTags.contains(tag),
                    onSelected: (selected) => setModalState(() {
                      if (selected) selectedFunctionalTags.add(tag); else selectedFunctionalTags.remove(tag);
                    }),
                  )).toList(),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D0140), padding: const EdgeInsets.symmetric(vertical: 15)),
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
                          userId: FirebaseAuth.instance.currentUser!.uid,
                          updatedData: updated,
                        );
                      }
                      
                      setState(() {
                        _currentProductData.addAll(updated);
                      });
                      
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item updated")));
                      }
                    },
                    child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
