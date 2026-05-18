import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/services/product_service.dart';

/// Admin-only screen to manage (add/delete) products in the main global catalog
class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final ProductService _productService = ProductService();
  final ImagePicker _picker = ImagePicker();
  static const Color primaryColor = Color(0xFF0D0140);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Product Manager"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Logout for admin to exit the panel
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _productService.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No products found in catalog."));
          }

          final products = snapshot.data!.docs;

          // List of all catalog products with delete actions
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final doc = products[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'No Name';
              final imageUrl = data['imageUrl'] ?? data['imageURL'] ?? '';
              final rawImageUrl = data['rawImageUrl'] ?? imageUrl;

              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: rawImageUrl.isNotEmpty
                      ? Image.network(rawImageUrl, width: 50, height: 50, fit: BoxFit.cover)
                      : Container(width: 50, height: 50, color: Colors.grey.shade200, child: const Icon(Icons.image)),
                ),
                title: Text(name),
                subtitle: Text(data['category'] ?? 'No Category'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(doc.id, name),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Confirm deletion of a catalog product
  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product?"),
        content: Text("Are you sure you want to delete '$name' from the global catalog? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await _productService.deleteProduct(id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product deleted from catalog")));
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Dialog to add a new product to the catalog with multi-colour selection
  void _showAddProductDialog() {
    final nameController = TextEditingController();
    String category = 'tops';
    String subcategory = 'none';
    List<String> selectedColours = [];
    String gender = 'unisex';
    File? selectedImage;

    final Map<String, List<String>> categoryData = {
      'accessories': ['none', 'caps', 'glasses', 'hats'],
      'bottoms': ['none', 'jeans', 'joggers', 'leggings', 'shorts', 'skirts'],
      'dresses': ['none'],
      'outerwear': ['none', 'blazers', 'jackets'],
      'tops': ['none', 'hoodies', 'polo shirts', 'shirts', 'sweatshirts', 't-shirts', 'tank tops'],
      'other': ['none'],
    };

    final List<String> availableColors = ['black', 'white', 'grey', 'blue', 'red', 'green', 'yellow', 'orange', 'pink', 'purple', 'brown', 'beige'];
    final List<String> genders = ['male', 'female', 'unisex'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: Text("Add New Catalog Product", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              const SizedBox(height: 20),
              // Image Picker Area
              GestureDetector(
                onTap: () async {
                  final File? image = await _pickImageSource();
                  if (image != null) setModalState(() => selectedImage = image);
                },
                child: Container(
                  height: 120, width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
                  child: selectedImage != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(selectedImage!, fit: BoxFit.cover))
                      : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40, color: Colors.grey), SizedBox(height: 10), Text("Select Image", style: TextStyle(color: Colors.grey))]),
                ),
              ),
              const SizedBox(height: 15),
              // Form Fields
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Product Name", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              Row(children: [
                Expanded(child: _buildSimpleDropdown("Category", category, categoryData.keys.toList(), (val) {
                  setModalState(() { category = val!; subcategory = categoryData[category]![0]; });
                })),
                const SizedBox(width: 10),
                Expanded(child: _buildSimpleDropdown("Subcategory", subcategory, categoryData[category]!, (val) => setModalState(() => subcategory = val!))),
              ]),
              const SizedBox(height: 15),
              const Text("Select Colours", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // Multi-colour selection using Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableColors.map((color) {
                  final isSelected = selectedColours.contains(color);
                  return FilterChip(
                    label: Text(color[0].toUpperCase() + color.substring(1)),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setModalState(() {
                        if (selected) selectedColours.add(color);
                        else selectedColours.remove(color);
                      });
                    },
                    selectedColor: primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? primaryColor : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 15),
              _buildSimpleDropdown("Gender", gender, genders, (val) => setModalState(() => gender = val!)),
              const SizedBox(height: 25),
              // Submit Action
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    if (selectedImage == null || nameController.text.isEmpty || selectedColours.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Missing info (ensure image, name, and at least one colour)")));
                      return;
                    }
                    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
                    try {
                      // 1. Process image with background remover API using product name as filename
                      final urls = await _productService.removeBackground(
                        selectedImage!, 
                        customFilename: nameController.text,
                      );
                      final imageUrl = urls['processed_url'] ?? '';
                      final rawImageUrl = urls['raw_url'] ?? '';
                      
                      if (imageUrl.isEmpty) throw Exception('API returned empty processed image URL');

                      // 2. Save to global 'products' collection
                      await _productService.addProduct({
                        'name': nameController.text,
                        'imageUrl': imageUrl,
                        'rawImageUrl': rawImageUrl,
                        'category': category,
                        'subcategory': subcategory == 'none' ? null : subcategory,
                        'colours': selectedColours,
                        'gender': gender,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      if (context.mounted) {
                        Navigator.pop(context); // Close loading
                        Navigator.pop(context); // Close sheet
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product successfully added to catalog!")));
                      }
                    } catch (e) {
                      if (context.mounted) { 
                        Navigator.pop(context); 
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e"))); 
                      }
                    }
                  },
                  child: const Text("Add Product to Catalog", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper for building consistent dropdown menus
  Widget _buildSimpleDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e[0].toUpperCase() + e.substring(1)))).toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10), border: OutlineInputBorder()),
        ),
      ],
    );
  }

  /// Show a dialog to choose between camera and gallery
  Future<File?> _pickImageSource() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) return File(image.path);
    }
    return null;
  }
}
