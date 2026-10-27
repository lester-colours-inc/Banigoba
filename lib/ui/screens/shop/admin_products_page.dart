// Seller inventory manager for boutiques.
//
// This screen creates and edits catalog products in Firestore, uploads product
// images, and stores optional per-size inventory. When size inventory exists,
// the total stock field is still saved for legacy screens and quick summaries.
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/body_profile.dart';
import '../../../data/models/fit_check.dart';
import '../../../data/models/piece_details.dart';
import '../../../data/services/product_service.dart';
import '../../../data/services/storage_service.dart';
import '../../widgets/back_photo_field.dart';
import '../../widgets/piece_extra_details_fields.dart';
import '../../widgets/safe_product_image.dart';

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
  // Preset sizes speed up entry while still allowing custom labels in the
  // editable size rows below.
  static const List<String> _suggestedSizes = [
    'XXS',
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'XXXL',
    'UK 4',
    'UK 6',
    'UK 8',
    'UK 10',
    'UK 12',
    'UK 14',
    'UK 16',
    'UK 18',
    'UK 20',
    'UK 22',
    'UK 24',
  ];

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
              final sizeInventory = _sizeInventoryFor(data);
              // For sized items, total stock is derived from the size buckets.
              final stock = sizeInventory.isNotEmpty
                  ? sizeInventory.values.fold<int>(
                      0,
                      (total, quantity) => total + quantity,
                    )
                  : (data['stock'] as num?)?.toInt() ?? 0;

              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SafeProductImage(
                    imageUrl: rawImageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    iconSize: 26,
                  ),
                ),
                title: Text(name),
                subtitle: Text(
                  "${data['category'] ?? 'No Category'} • "
                  "\$${((data['price'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)} • "
                  "$stock in stock"
                  "${sizeInventory.isEmpty ? '' : ' • ${sizeInventory.length} sizes'}",
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
      builder: (dialogContext) => AlertDialog(
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
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(dialogContext).showSnackBar(
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
    final List<_SizeInventoryEntry> sizeEntries = _sizeEntriesFor(
      existingData ?? const <String, dynamic>{},
    );
    final pieceDetails = PieceDetails.fromMap(existingData);
    final shoulderController = TextEditingController(
      text: pieceDetails.shoulderMeasurement,
    );
    final heightMeasurementController = TextEditingController(
      text: pieceDetails.heightMeasurement,
    );
    final linenTypeController = TextEditingController(
      text: pieceDetails.linenType,
    );
    final madeWhereController = TextEditingController(
      text: pieceDetails.madeWhere,
    );
    final otherDetailControllers = [
      for (final detail in pieceDetails.otherDetails)
        TextEditingController(text: detail),
    ];
    String gender = existingData?['gender'] ?? 'unisex';
    File? selectedImage;
    String existingImageUrl = existingData?['imageUrl'] ?? '';
    String existingRawImageUrl = existingData?['rawImageUrl'] ?? '';
    File? selectedBackImage;
    String existingBackImageUrl = (existingData?['backImageUrl'] ?? '')
        .toString();

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
                                child: SafeProductImage(
                                  imageUrl: existingImageUrl,
                                  width: double.infinity,
                                  height: 120,
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
              const SizedBox(height: 10),
              BackPhotoField(
                picked: selectedBackImage,
                existingUrl: existingBackImageUrl,
                onPick: () async {
                  final File? image = await _pickImageSource();
                  if (image != null) {
                    setModalState(() => selectedBackImage = image);
                  }
                },
                onRemove: () => setModalState(() {
                  selectedBackImage = null;
                  existingBackImageUrl = '';
                }),
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
                  const Expanded(
                    child: Text(
                      "Size Inventory",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setModalState(() {
                        final usedSizes = sizeEntries
                            .map(
                              (entry) => entry.sizeController.text
                                  .trim()
                                  .toUpperCase(),
                            )
                            .toSet();
                        final nextSize = _suggestedSizes.firstWhere(
                          (size) => !usedSizes.contains(size),
                          orElse: () => '',
                        );
                        sizeEntries.add(
                          _SizeInventoryEntry(
                            size: nextSize,
                            quantity: nextSize.isEmpty ? 0 : 1,
                          ),
                        );
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Size'),
                  ),
                ],
              ),
              if (sizeEntries.isEmpty)
                Text(
                  'Use XXS-XXXL or UK numeric sizes. Leave empty for one-size items.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Column(
                  children: [
                    for (int index = 0; index < sizeEntries.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller:
                                        sizeEntries[index].sizeController,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    decoration: const InputDecoration(
                                      labelText: "Size",
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller:
                                        sizeEntries[index].quantityController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: "Quantity",
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Remove size',
                                  onPressed: () {
                                    setModalState(() {
                                      sizeEntries.removeAt(index);
                                    });
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Optional size chart: what the garment measures
                            // in this size, so buyers get a fit check.
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final part in kChartParts)
                                  SizedBox(
                                    width: 104,
                                    child: TextField(
                                      key: ValueKey(
                                        'chart_${index}_${part.key}',
                                      ),
                                      controller: sizeEntries[index]
                                          .measureControllers[part],
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: InputDecoration(
                                        labelText:
                                            part == BodyMeasurement.insideLeg
                                            ? 'Inseam (cm)'
                                            : '${_chartLabel(part)} (cm)',
                                        isDense: true,
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    Text(
                      'Optional: measure the garment itself, all the way '
                      'around for chest, waist and hips. Buyers see a fit '
                      'check against their own measurements.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 15),
              buildPieceExtraDetailsFields(
                context,
                shoulderController: shoulderController,
                heightController: heightMeasurementController,
                linenTypeController: linenTypeController,
                madeWhereController: madeWhereController,
                otherDetailControllers: otherDetailControllers,
                onAddDetail: () => setModalState(
                  () => otherDetailControllers.add(TextEditingController()),
                ),
                onRemoveDetail: (index) =>
                    setModalState(() => otherDetailControllers.removeAt(index)),
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
                        if (selected) {
                          selectedColours.add(color);
                        } else {
                          selectedColours.remove(color);
                        }
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
                        if (selected) {
                          selectedWeatherTags.add(tag);
                        } else {
                          selectedWeatherTags.remove(tag);
                        }
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
                        if (selected) {
                          selectedFunctionalTags.add(tag);
                        } else {
                          selectedFunctionalTags.remove(tag);
                        }
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
                    final sizeInventory = _sizeInventoryFromEntries(
                      sizeEntries,
                    );
                    // Duplicate or malformed size rows would make checkout
                    // stock checks unreliable, so validate before saving.
                    final hasInvalidSizes =
                        sizeEntries.any(
                          (entry) =>
                              entry.sizeController.text.trim().isEmpty ||
                              int.tryParse(
                                    entry.quantityController.text.trim(),
                                  ) ==
                                  null ||
                              int.parse(entry.quantityController.text.trim()) <
                                  0,
                        ) ||
                        sizeInventory.length != sizeEntries.length;
                    final stock = sizeInventory.isNotEmpty
                        ? sizeInventory.values.fold<int>(
                            0,
                            (total, quantity) => total + quantity,
                          )
                        : int.tryParse(stockController.text) ?? -1;
                    if ((selectedImage == null && !isEditing) ||
                        nameController.text.isEmpty ||
                        double.tryParse(priceController.text) == null ||
                        stock < 0 ||
                        hasInvalidSizes ||
                        selectedColours.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Add an image, name, valid price, inventory, and colour.",
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

                      // The optional back photo goes up as it is (no
                      // background removal): it is only a reference for the
                      // turn-around view.
                      var backImageUrl = existingBackImageUrl;
                      if (selectedBackImage != null) {
                        backImageUrl = await StorageService()
                            .uploadProductImageBytes(
                              await selectedBackImage!.readAsBytes(),
                              _currentUserId,
                              filename:
                                  'back_${DateTime.now().millisecondsSinceEpoch}.jpg',
                            );
                      }

                      final productUpdateData = {
                        'uploaderId': _currentUserId,
                        'name': nameController.text,
                        'price': double.parse(priceController.text),
                        'stock': stock,
                        'imageUrl': imageUrl,
                        'rawImageUrl': rawImageUrl,
                        if (backImageUrl.isNotEmpty)
                          'backImageUrl': backImageUrl
                        else if (isEditing)
                          'backImageUrl': FieldValue.delete(),
                        'category': category,
                        'subcategory': subcategory == 'none'
                            ? null
                            : subcategory,
                        'styleTag': styleTag,
                        'colours': selectedColours,
                        'gender': gender,
                        'weatherTags': selectedWeatherTags,
                        'functionalTags': selectedFunctionalTags,
                        if (sizeInventory.isNotEmpty)
                          'sizeInventory': sizeInventory,
                        if (sizeInventory.isEmpty && isEditing)
                          'sizeInventory': FieldValue.delete(),
                        if (_sizeChartFromEntries(sizeEntries) case final chart
                            when !chart.isEmpty)
                          'sizeChart': chart.toMap()
                        else if (isEditing)
                          'sizeChart': FieldValue.delete(),
                        ...PieceDetails.fromControllerText(
                          shoulderMeasurement: shoulderController.text,
                          heightMeasurement: heightMeasurementController.text,
                          linenType: linenTypeController.text,
                          madeWhere: madeWhereController.text,
                          otherDetails: otherDetailControllers.map(
                            (controller) => controller.text,
                          ),
                        ).toMap(),
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
          initialValue: value,
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

  List<_SizeInventoryEntry> _sizeEntriesFor(Map<String, dynamic> data) {
    final inventory = _sizeInventoryFor(data);
    final chart = SizeChart.fromProduct(data);
    return inventory.entries
        .map(
          (entry) => _SizeInventoryEntry(
            size: entry.key,
            quantity: entry.value,
            measures: chart.sizes[entry.key] ?? const {},
          ),
        )
        .toList();
  }

  /// The size chart typed into the form: only sizes with a valid size label
  /// and at least one measurement.
  SizeChart _sizeChartFromEntries(List<_SizeInventoryEntry> entries) {
    final sizes = <String, Map<BodyMeasurement, double>>{};
    for (final entry in entries) {
      final size = entry.sizeController.text.trim().toUpperCase();
      if (size.isEmpty) continue;
      final measures = <BodyMeasurement, double>{};
      for (final part in kChartParts) {
        final text = entry.measureControllers[part]!.text.trim().replaceAll(
          ',',
          '.',
        );
        final cm = double.tryParse(text);
        if (cm != null && cm > 0) measures[part] = cm;
      }
      if (measures.isNotEmpty) sizes[size] = measures;
    }
    return SizeChart(sizes);
  }

  String _chartLabel(BodyMeasurement part) => switch (part) {
    BodyMeasurement.shoulders => 'Shoulders',
    BodyMeasurement.chest => 'Chest',
    BodyMeasurement.waist => 'Waist',
    BodyMeasurement.hips => 'Hips',
    _ => part.label,
  };

  Map<String, int> _sizeInventoryFor(Map<String, dynamic> data) {
    final raw = data['sizeInventory'];
    if (raw is! Map) return <String, int>{};
    final inventory = <String, int>{};
    raw.forEach((key, value) {
      final size = key.toString().trim().toUpperCase();
      final quantity = value is num
          ? value.toInt()
          : int.tryParse(value.toString().trim()) ?? 0;
      if (size.isNotEmpty) inventory[size] = quantity;
    });
    return inventory;
  }

  Map<String, int> _sizeInventoryFromEntries(
    List<_SizeInventoryEntry> entries,
  ) {
    final inventory = <String, int>{};
    for (final entry in entries) {
      final size = entry.sizeController.text.trim().toUpperCase();
      final quantity = int.tryParse(entry.quantityController.text.trim()) ?? -1;
      if (size.isNotEmpty && quantity >= 0) inventory[size] = quantity;
    }
    return inventory;
  }
}

class _SizeInventoryEntry {
  _SizeInventoryEntry({
    required String size,
    required int quantity,
    Map<BodyMeasurement, double> measures = const {},
  }) : sizeController = TextEditingController(text: size),
       quantityController = TextEditingController(text: quantity.toString()),
       measureControllers = {
         for (final part in kChartParts)
           part: TextEditingController(
             text: measures[part] == null ? '' : formatNumber(measures[part]!),
           ),
       };

  final TextEditingController sizeController;
  final TextEditingController quantityController;

  /// The garment's measurements in this size, by body part (optional).
  final Map<BodyMeasurement, TextEditingController> measureControllers;
}
