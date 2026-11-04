// Manages the signed-in user's wardrobe, uploads, filters, and product actions.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import '../../../core/supabase/app_auth.dart';
import '../../../data/services/profile_service.dart';
import '../../../data/supabase/rows.dart';
import '../../../core/app_routes.dart';
import '../../../data/models/body_profile.dart';
import '../../../data/models/piece_details.dart';
import '../../../data/models/wear_tracking.dart';
import '../../../data/services/garment_tagger.dart';
import '../../../data/utils/garment_colour.dart';
import '../../../data/services/product_service.dart';
import '../../../data/services/notification_service.dart';
import '../../widgets/cart_badge_button.dart';
import '../shop/product_detail_page.dart';
import '../main/notifications_page.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/menu_or_back_button.dart';
import 'widgets/saved_looks_grid.dart';
import 'widgets/wardrobe_connections.dart';

/// My Smart Wardrobe: the user's clothes, the looks they saved, and the
/// shops and designers the wardrobe draws on (October 2026 review, W-1).
/// The wardrobe's sections, in tab order.
enum WardrobeTab { clothes, savedLooks, shops }

class WardrobePage extends StatefulWidget {
  const WardrobePage({super.key, this.initialTab = WardrobeTab.clothes});

  final WardrobeTab initialTab;

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  final ProductService _productService = ProductService();
  final GarmentTagger _tagger = GeminiGarmentTagger();
  final String _currentUserId = AppAuth.instance.currentUser?.uid ?? '';
  late int _selectedTabIndex = widget.initialTab.index;
  final ImagePicker _picker = ImagePicker();
  static Color primaryColor = Color(0xFF0D0140);

  /// Draws the eye to pieces that have gone unworn a long time.
  static const Color _nudgeColor = Color(0xFFD9822B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: const MenuOrBackButton(),
        actions: [
          _buildAppBarAction(
            Icons.shopping_bag_outlined,
            () => Navigator.pushNamed(context, AppRoutes.cart),
          ),
          _buildAppBarAction(Icons.notifications_none_rounded, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationsPage()),
            );
          }, hasNotification: true),
          SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page heading (G-1). Back/menu lives in the app bar.
                Text(
                  'My Smart Wardrobe',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 25),
                // Custom Tab Bar
                _buildTabs(),
                SizedBox(height: 25),
                // Main Content depending on selected tab
                Expanded(child: _buildSelectedTab()),
              ],
            ),
          ),
          // Floating Action Button for adding new items (visible in "Mine" tab)
          if (_selectedTabIndex == 0)
            Positioned(bottom: 30, right: 25, child: _buildAddItemButton()),
        ],
      ),
    );
  }

  /// Build a single action button for the AppBar
  Widget _buildAppBarAction(
    IconData icon,
    VoidCallback onTap, {
    bool hasNotification = false,
  }) {
    if (icon == Icons.shopping_bag_outlined) {
      return CartBadgeButton(
        onPressed: onTap,
        color: Theme.of(context).colorScheme.onSurface,
      );
    }

    return Stack(
      children: [
        IconButton(
          icon: Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurface,
            size: 28,
          ),
          onPressed: onTap,
        ),
        if (hasNotification)
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount == 0) return const SizedBox.shrink();
              return Positioned(
                right: 5,
                top: 5,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  /// Build the top navigation tabs
  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tabButton("My Clothes", 0),
          SizedBox(width: 12),
          _tabButton("Saved Looks", 1),
          SizedBox(width: 12),
          _tabButton("Shops & Designers", 2),
        ],
      ),
    );
  }

  /// Build a single tab button widget
  Widget _tabButton(String title, int index) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : Theme.of(context).colorScheme.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  /// Floating Add Item button widget
  Widget _buildAddItemButton() {
    return GestureDetector(
      onTap: _showUploadItemDialog,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'Add Item',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Switch between different tab views
  Widget _buildSelectedTab() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildMineTab();
      case 1:
        return SavedLooksGrid(userId: _currentUserId);
      case 2:
        return WardrobeConnections(userId: _currentUserId);
      default:
        return _buildMineTab();
    }
  }

  /// Shared helper to build a scrollable list of products grouped by category
  Widget _buildGroupedProductList(List<Map<String, dynamic>> items) {
    final Map<String, List<Map<String, dynamic>>> groupedItems = {};
    for (var item in items) {
      final data = item;
      final category = (data['category']?.toString() ?? 'Other').toLowerCase();
      if (!groupedItems.containsKey(category)) groupedItems[category] = [];
      groupedItems[category]!.add(item);
    }

    final categories = groupedItems.keys.toList()..sort();

    return ListView.builder(
      padding: EdgeInsets.only(bottom: 100),
      itemCount: categories.length,
      itemBuilder: (context, catIndex) {
        final category = categories[catIndex];
        final categoryItems = groupedItems[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                category[0].toUpperCase() + category.substring(1),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.64,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: categoryItems.length,
              itemBuilder: (context, index) {
                return _buildWardrobeCard(
                  Map<String, dynamic>.from(categoryItems[index]),
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Tab showing user's own items (uploaded and saved)
  Widget _buildMineTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _productService.getUserProducts(_currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text("Your wardrobe is empty. Upload some items!"),
          );
        }

        final items = List<Map<String, dynamic>>.from(snapshot.data!);
        items.sort((a, b) {
          final aTime = asDateTime(a['createdAt']);
          final bTime = asDateTime(b['createdAt']);
          if (aTime == null) return -1;
          if (bTime == null) return 1;
          return bTime.compareTo(aTime);
        });

        return _buildGroupedProductList(items);
      },
    );
  }

  /// Build a single product card in the grid
  Widget _buildWardrobeCard(Map<String, dynamic> data) {
    final imageUrl = data['imageUrl'] ?? data['imageURL'] ?? '';
    final rawImageUrl = data['rawImageUrl'] ?? imageUrl;

    final String? originalProductId = data['originalProductId'];
    final String? originalPosterId = data['originalPosterId'];
    final String? uploaderId = data['userId'];

    // Only attribute to a user if it was an original upload or saved from a user
    final String? posterId = originalProductId != null
        ? originalPosterId
        : uploaderId;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(productData: data),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                child: rawImageUrl.isNotEmpty
                    ? AppNetworkImage(
                        rawImageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      )
                    : Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? 'No Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  // Display original poster name if not admin
                  if (posterId != null)
                    StreamBuilder<Map<String, dynamic>>(
                      stream: ProfileService().watch(posterId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty)
                          return SizedBox.shrink();
                        final userData = snapshot.data!;

                        // Check if user is admin
                        final bool isAdmin =
                            userData['role'] == 'admin' ||
                            userData['isAdmin'] == true;
                        if (isAdmin) {
                          // For admin items, show colors or nothing extra
                          return _buildColorSubtitle(data);
                        }

                        final posterName = userData['displayName'] ?? 'User';
                        return Text(
                          posterId == _currentUserId
                              ? 'by you'
                              : 'by $posterName',
                          style: TextStyle(
                            color: primaryColor.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    )
                  else
                    _buildColorSubtitle(data),
                  if (uploaderId == _currentUserId) _buildWearRow(data),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Worn 3 weeks ago" / "Not worn in 10 months", and a tap to record
  /// wearing it today (W-7).
  Widget _buildWearRow(Map<String, dynamic> data) {
    final status = wearStatus(
      lastWorn: timestampToDate(data['lastWornAt']),
      addedAt: timestampToDate(data['createdAt']),
      now: DateTime.now(),
    );
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            status.label,
            key: ValueKey('wear_status_${data['id']}'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: status.isNudge ? FontWeight.w700 : FontWeight.w500,
              color: status.isNudge ? _nudgeColor : colors.onSurfaceVariant,
            ),
          ),
        ),
        IconButton(
          key: ValueKey('wore_today_${data['id']}'),
          tooltip: 'I wore this today',
          visualDensity: VisualDensity.compact,
          iconSize: 20,
          onPressed: status.label == 'Worn today'
              ? null
              : () => _markWorn(data['id'].toString()),
          icon: const Icon(Icons.check_circle_outline),
        ),
      ],
    );
  }

  Future<void> _markWorn(String itemId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _productService.markUserProductWorn(itemId);
      messenger.showSnackBar(
        const SnackBar(content: Text('Noted: worn today.')),
      );
    } on PostgrestException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not save that: ${error.message}')),
      );
    }
  }

  /// Helper to build the color subtitle for a product card
  Widget _buildColorSubtitle(Map<String, dynamic> data) {
    final dynamic rawColours = data['colours'] ?? data['colour'];
    List<dynamic> coloursList = [];
    if (rawColours is List)
      coloursList = rawColours;
    else if (rawColours != null && rawColours.toString().isNotEmpty)
      coloursList = [rawColours];

    String colourText = 'Various';
    if (coloursList.isNotEmpty) {
      final first = coloursList[0].toString().trim();
      if (first.isNotEmpty) {
        colourText = first[0].toUpperCase() + first.substring(1).toLowerCase();
        if (coloursList.length > 1) colourText += ' +${coloursList.length - 1}';
      }
    }
    return Text(
      colourText,
      style: TextStyle(
        color: Theme.of(context).colorScheme.outline,
        fontSize: 11,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Show a BottomSheet for uploading a new item to the wardrobe
  void _showUploadItemDialog() {
    final TextEditingController nameController = TextEditingController();
    String visibility = 'private';
    String category = 'tops';
    String subcategory = 'none';
    String styleTag = 'casual';
    List<String> selectedColours = [];
    List<String> selectedWeatherTags = [];
    List<String> selectedFunctionalTags = [];
    String gender = 'unisex';
    String size = '';
    final shoulderController = TextEditingController();
    final lengthController = TextEditingController();
    File? selectedImage;
    // Colours picked from the photo, until the user changes them (W-3).
    bool coloursFromPhoto = false;
    // The AI's suggestion from the photo, while it is working and once used.
    bool tagging = false;
    bool taggedFromPhoto = false;

    final Map<String, List<String>> categoryData = {
      'accessories': ['none', 'caps', 'glasses', 'hats'],
      'bottoms': ['none', 'jeans', 'joggers', 'leggings', 'shorts', 'skirts'],
      'dresses': ['none'],
      'outerwear': ['none', 'blazers', 'jackets'],
      'shoes': ['none', 'boots', 'flats', 'heels', 'sandals', 'sneakers'],
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
      shape: RoundedRectangleBorder(
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
                    key: const ValueKey('wardrobe_upload_back'),
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      "Upload to Wardrobe",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Balances the back button so the title stays centred.
                  const SizedBox(width: 48),
                ],
              ),
              SizedBox(height: 12),
              // Image Picker Box
              GestureDetector(
                onTap: () async {
                  final File? image = await _pickImageSource();
                  if (image == null) return;
                  setModalState(() => selectedImage = image);
                  // Suggest the colours from the photo, unless the user has
                  // already chosen some.
                  final found = await coloursFromFile(image);
                  if (mounted && found.isNotEmpty) {
                    setModalState(() {
                      if (selectedColours.isEmpty) {
                        selectedColours.addAll(found);
                        coloursFromPhoto = true;
                      }
                    });
                  }
                  // Then let the AI fill in the rest from the photo. Only
                  // fields the person has not touched are filled.
                  if (!_tagger.isConfigured) return;
                  setModalState(() => tagging = true);
                  final tags = await _tagger.tag(await image.readAsBytes());
                  if (!mounted) return;
                  setModalState(() {
                    tagging = false;
                    if (tags == null) return;
                    if (nameController.text.trim().isEmpty &&
                        tags.name.isNotEmpty) {
                      nameController.text = tags.name;
                    }
                    if (category == 'tops' && subcategory == 'none') {
                      if (tags.category != null) category = tags.category!;
                      subcategory = tags.subcategory ?? 'none';
                    }
                    if (styleTag == 'casual' && tags.styleTag != null) {
                      styleTag = tags.styleTag!;
                    }
                    if (gender == 'unisex' && tags.gender != null) {
                      gender = tags.gender!;
                    }
                    if (selectedWeatherTags.isEmpty) {
                      selectedWeatherTags.addAll(tags.weatherTags);
                    }
                    if (selectedFunctionalTags.isEmpty) {
                      selectedFunctionalTags.addAll(tags.functionalTags);
                    }
                    if ((selectedColours.isEmpty || coloursFromPhoto) &&
                        tags.colours.isNotEmpty) {
                      selectedColours
                        ..clear()
                        ..addAll(tags.colours);
                      coloursFromPhoto = true;
                    }
                    taggedFromPhoto = true;
                  });
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
                          child: Image.file(
                            selectedImage!,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Column(
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
                        ),
                ),
              ),
              if (tagging)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Row(
                    key: ValueKey('tagging_progress'),
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('Looking at your photo…'),
                    ],
                  ),
                )
              else if (taggedFromPhoto)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Filled in from your photo. Check it and change '
                    'anything that is not right.',
                    key: const ValueKey('tagged_note'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              SizedBox(height: 15),
              // Name input and dropdowns for category, color, etc.
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Item Name",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15),
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
                  SizedBox(width: 10),
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
              SizedBox(height: 15),
              _buildSimpleDropdown(
                "Style",
                styleTag,
                styleTags,
                (val) => setModalState(() => styleTag = val!),
              ),
              SizedBox(height: 15),
              // Size and key measurements (W-4), so the wardrobe knows what
              // fits and shops can match like for like.
              Text(
                "Size",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in BodyProfile.clothingSizes)
                    ChoiceChip(
                      key: ValueKey('wardrobe_size_$option'),
                      label: Text(option),
                      selected: size == option,
                      onSelected: (selected) =>
                          setModalState(() => size = selected ? option : ''),
                    ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('wardrobe_shoulders'),
                      controller: shoulderController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Shoulders (cm)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      key: const ValueKey('wardrobe_length'),
                      controller: lengthController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Length (cm)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Text(
                "Select Colours",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              if (coloursFromPhoto)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Picked from your photo. Tap to change.',
                    key: const ValueKey('colours_from_photo'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              SizedBox(height: 8),
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
                        coloursFromPhoto = false;
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
              SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildSimpleDropdown(
                      "Gender",
                      gender,
                      genders,
                      (val) => setModalState(() => gender = val!),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _buildSimpleDropdown("Visibility", visibility, [
                      'private',
                      'public',
                    ], (val) => setModalState(() => visibility = val!)),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Text(
                "Weather Tags",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
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
              SizedBox(height: 15),
              Text(
                "Functional Tags",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
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
              SizedBox(height: 25),
              // Upload Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (selectedImage == null ||
                        nameController.text.isEmpty ||
                        selectedColours.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Missing info (ensure image, name, and at least one colour)",
                          ),
                        ),
                      );
                      return;
                    }
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) =>
                          Center(child: CircularProgressIndicator()),
                    );
                    try {
                      // Process image with background remover API using item name as filename
                      final urls = await _productService.removeBackground(
                        selectedImage!,
                        customFilename: nameController.text,
                      );
                      final imageUrl = urls['processed_url'] ?? '';
                      final rawImageUrl = urls['raw_url'] ?? '';

                      if (imageUrl.isEmpty)
                        throw Exception(
                          'API returned empty processed image URL',
                        );

                      // Save the piece to the wardrobe
                      await _productService.uploadUserProduct(
                        userId: _currentUserId,
                        name: nameController.text,
                        imageUrl: imageUrl,
                        rawImageUrl: rawImageUrl,
                        category: category,
                        subcategory: subcategory == 'none' ? null : subcategory,
                        styleTag: styleTag,
                        colours: selectedColours,
                        gender: gender,
                        visibility: visibility,
                        weatherTags: selectedWeatherTags,
                        functionalTags: selectedFunctionalTags,
                        size: size,
                        details: PieceDetails.fromControllerText(
                          shoulderMeasurement: shoulderController.text,
                          heightMeasurement: lengthController.text,
                          linenType: '',
                          madeWhere: '',
                          otherDetails: const [],
                        ),
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Uploaded successfully!")),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Failed: $e")));
                      }
                    }
                  },
                  child: Text(
                    "Upload Item",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper for building standard dropdowns in the upload form
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
        SizedBox(height: 4),
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
          decoration: InputDecoration(
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
              leading: Icon(Icons.photo_library),
              title: Text('Photo Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: Icon(Icons.photo_camera),
              title: Text('Camera'),
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
