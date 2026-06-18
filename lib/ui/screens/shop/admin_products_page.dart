// Lets sellers manage products listed by their shop or boutique.
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/services/product_service.dart';

/// Product and inventory manager for the current seller.
class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final ProductService _productService = ProductService();
  final ImagePicker _picker = ImagePicker();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  static const Color primaryColor = Color(0xFF0D0140);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Products & Inventory"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _productService.getAdminProducts(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No products yet. Add your first listing."),
            );
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
                      ? Image.network(
                          rawImageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          color: Theme.of(context).colorScheme.outlineVariant,
                          child: const Icon(Icons.image),
                        ),
                ),
                title: Text(name),
                subtitle: Text(
                  "${data['category'] ?? 'No Category'} • "
                  "\$${((data['price'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)} • "
                  "${(data['stock'] as num?)?.toInt() ?? 0} in stock",
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditProductDialog(doc.id, data),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(doc.id, name),
                    ),
                  ],
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
        content: Text(
          "Are you sure you want to remove '$name' from your boutique? This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await _productService.deleteProduct(id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Product removed")),
                );
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
    _showProductFormDialog();
  }

  /// Dialog to edit an existing catalog product
  void _showEditProductDialog(String docId, Map<String, dynamic> data) {
    _showProductFormDialog(docId: docId, existingData: data);
  }

  /// Generic form for adding/editing products
  void _showProductFormDialog({
    String? docId,
    Map<String, dynamic>? existingData,
  }) {
    final bool isEditing = docId != null;
    final nameController = TextEditingController(
      text: existingData?['name'] ?? '',
    );
    final priceController = TextEditingController(
      text: ((existingData?['price'] as num?)?.toDouble() ?? 0).toStringAsFixed(
        2,
      ),
    );
    final stockController = TextEditingController(
      text: ((existingData?['stock'] as num?)?.toInt() ?? 0).toString(),
    );
    String category = existingData?['category'] ?? 'tops';
    String subcategory = existingData?['subcategory'] ?? 'none';
    String styleTag =
        existingData?['styleTag'] ?? existingData?['style'] ?? 'casual';
    List<String> selectedColours = List<String>.from(
      existingData?['colours'] ?? [],
    );
    List<String> selectedWeatherTags = List<String>.from(
      existingData?['weatherTags'] ?? [],
    );
    List<String> selectedFunctionalTags = List<String>.from(
      existingData?['functionalTags'] ?? [],
    );
    String gender = existingData?['gender'] ?? 'unisex';
    File? selectedImage;
    String existingImageUrl = existingData?['imageUrl'] ?? '';
    String existingRawImageUrl = existingData?['rawImageUrl'] ?? '';

    final Map<String, List<String>> categoryData = {
      'accessories': ['none', 'caps', 'glasses', 'hats'],
      'bottoms': ['none', 'jeans', 'joggers', 'leggings', 'shorts', 'skirts'],
      'dresses': ['none'],
      'outerwear': ['none', 'blazers', 'jackets'],
      'tops': [
        'none',
        'hoodies',
        'polo shirts',
        'shirts',
        'sweatshirts',
        't-shirts',
        'tank tops',
      ],
      'other': ['none'],
    };

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
    final List<String> weatherTags = ["hot", "mild", "cool", "cold", "rainy"];
    final List<String> functionalTags = [
      "waterproof",
      "breathable",
      "insulated",
      "windproof",
    ];
    final List<String> genders = ['male', 'female', 'unisex'];
    final List<String> styleTags = [
      'casual',
      'afrochic',
      'corporate',
      'streetwear',
      'glamour',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      isEditing ? "Edit Product" : "Add Boutique Product",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
                ),
              ),
              const SizedBox(height: 20),
              // Image Picker Area
              GestureDetector(
                onTap: () async {
                  final File? image = await _pickImageSource();
                  if (image != null) setModalState(() => selectedImage = image);
                },
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(selectedImage!, fit: BoxFit.cover),
                        )
                      : (existingImageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.network(
                                  existingImageUrl,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "Select Image",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              )),
                ),
              ),
              const SizedBox(height: 15),
              // Form Fields
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Product Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: "Price",
                        prefixText: "\$ ",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Stock",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildSimpleDropdown(
                      "Category",
                      category,
                      categoryData.keys.toList(),
                      (val) {
                        setModalState(() {
                          category = val!;
                          subcategory = categoryData[category]![0];
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSimpleDropdown(
                      "Subcategory",
                      subcategory,
                      categoryData[category]!,
                      (val) => setModalState(() => subcategory = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildSimpleDropdown(
                "Style Tag",
                styleTag,
                styleTags,
                (val) => setModalState(() => styleTag = val!),
              ),
              const SizedBox(height: 15),
              const Text(
                "Select Colours",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
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
                        if (selected)
                          selectedColours.add(color);
                        else
                          selectedColours.remove(color);
                      });
                    },
                    selectedColor: primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? primaryColor : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 15),
              _buildSimpleDropdown(
                "Gender",
                gender,
                genders,
                (val) => setModalState(() => gender = val!),
              ),
              const SizedBox(height: 15),
              const Text(
                "Weather Tags",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: weatherTags.map((tag) {
                  final isSelected = selectedWeatherTags.contains(tag);
                  return FilterChip(
                    label: Text(tag[0].toUpperCase() + tag.substring(1)),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setModalState(() {
                        if (selected)
                          selectedWeatherTags.add(tag);
                        else
                          selectedWeatherTags.remove(tag);
                      });
                    },
                    selectedColor: primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? primaryColor : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 15),
              const Text(
                "Functional Tags",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: functionalTags.map((tag) {
                  final isSelected = selectedFunctionalTags.contains(tag);
                  return FilterChip(
                    label: Text(tag[0].toUpperCase() + tag.substring(1)),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setModalState(() {
                        if (selected)
                          selectedFunctionalTags.add(tag);
                        else
                          selectedFunctionalTags.remove(tag);
                      });
                    },
                    selectedColor: primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? primaryColor : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 25),
              // Submit Action
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if ((selectedImage == null && !isEditing) ||
                        nameController.text.isEmpty ||
                        double.tryParse(priceController.text) == null ||
                        int.tryParse(stockController.text) == null ||
                        selectedColours.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Add an image, name, valid price, stock, and colour.",
                          ),
                        ),
                      );
                      return;
                    }
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) =>
                          const Center(child: CircularProgressIndicator()),
                    );
                    try {
                      debugPrint(
                        '[ProductUpload] Submit started: '
                        'isEditing=$isEditing, userId=$_currentUserId, '
                        'hasSelectedImage=${selectedImage != null}, docId=$docId',
                      );
                      String imageUrl = existingImageUrl;
                      String rawImageUrl = existingRawImageUrl;

                      if (selectedImage != null) {
                        debugPrint(
                          '[ProductUpload] Uploading selected image: '
                          '${selectedImage!.path}',
                        );
                        final uploadedImageUrl = await _productService
                            .uploadCatalogProductImage(
                              userId: _currentUserId,
                              image: selectedImage!,
                              customFilename: nameController.text,
                            );
                        imageUrl = uploadedImageUrl;
                        rawImageUrl = uploadedImageUrl;
                        debugPrint(
                          '[ProductUpload] Image upload returned URL: '
                          '${imageUrl.split('?').first}',
                        );

                        if (imageUrl.isEmpty) {
                          throw Exception(
                            'Firebase Storage returned an empty image URL',
                          );
                        }
                      }

                      final productUpdateData = {
                        'uploaderId': _currentUserId,
                        'name': nameController.text,
                        'price': double.parse(priceController.text),
                        'stock': int.parse(stockController.text),
                        'imageUrl': imageUrl,
                        'rawImageUrl': rawImageUrl,
                        'category': category,
                        'subcategory': subcategory == 'none'
                            ? null
                            : subcategory,
                        'styleTag': styleTag,
                        'colours': selectedColours,
                        'gender': gender,
                        'weatherTags': selectedWeatherTags,
                        'functionalTags': selectedFunctionalTags,
                        if (!isEditing)
                          'createdAt': FieldValue.serverTimestamp(),
                        if (isEditing)
                          'updatedAt': FieldValue.serverTimestamp(),
                      };

                      debugPrint('[ProductUpload] Loading seller profile.');
                      final sellerSnapshot = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(_currentUserId)
                          .get();
                      final sellerData =
                          sellerSnapshot.data() ?? const <String, dynamic>{};
                      final shop = Map<String, dynamic>.from(
                        sellerData['shop'] as Map? ?? const {},
                      );
                      productUpdateData['shopName'] =
                          (shop['name'] ??
                                  sellerData['displayName'] ??
                                  'Boutique')
                              .toString();
                      debugPrint(
                        '[ProductUpload] Saving product document: '
                        'isEditing=$isEditing, shopName=${productUpdateData['shopName']}, '
                        'imageUrl=${imageUrl.split('?').first}',
                      );

                      if (isEditing) {
                        await _productService.updateCatalogProduct(
                          docId,
                          productUpdateData,
                        );
                      } else {
                        await _productService.addProduct(productUpdateData);
                      }
                      debugPrint('[ProductUpload] Product document saved.');

                      if (context.mounted) {
                        Navigator.pop(context); // Close loading
                        Navigator.pop(context); // Close sheet
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEditing
                                  ? "Product successfully updated!"
                                  : "Product added to your boutique!",
                            ),
                          ),
                        );
                      }
                    } catch (e, stackTrace) {
                      debugPrint('[ProductUpload] Product save failed: $e');
                      debugPrintStack(stackTrace: stackTrace);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Action failed: $e")),
                        );
                      }
                    }
                  },
                  child: Text(
                    isEditing ? "Update Product" : "Add Product",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
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
  Widget _buildSimpleDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e[0].toUpperCase() + e.substring(1)),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 10),
            border: OutlineInputBorder(),
          ),
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
