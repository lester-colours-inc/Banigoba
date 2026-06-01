import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/app_routes.dart';
import '../../../data/services/product_service.dart';
import '../../../data/services/friend_service.dart';
import '../shop/product_detail_page.dart';
import '../main/notifications_page.dart';

/// Screen representing the "My Daily Dress Up" section, managing the user's wardrobe items
class WardrobePage extends StatefulWidget {
  const WardrobePage({super.key});

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  final ProductService _productService = ProductService();
  final FriendService _friendService = FriendService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  int _selectedTabIndex = 0; // 0: Mine, 1: My Friends, 2: Community
  final ImagePicker _picker = ImagePicker();
  static const Color primaryColor = Color(0xFF0D0140);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        actions: [
          _buildAppBarAction(Icons.shopping_bag_outlined, () => Navigator.pushNamed(context, AppRoutes.cart)),
          _buildAppBarAction(Icons.chat_bubble_outline, () {
             Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsPage()),
              );
          }, hasNotification: true),
          const SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'My Daily Dress Up',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                // Custom Tab Bar
                _buildTabs(),
                const SizedBox(height: 25),
                // Main Content depending on selected tab
                Expanded(
                  child: _buildSelectedTab(),
                ),
              ],
            ),
          ),
          // Floating Action Button for adding new items (visible in "Mine" tab)
          if (_selectedTabIndex == 0)
            Positioned(
              bottom: 30,
              right: 25,
              child: _buildAddItemButton(),
            ),
        ],
      ),
    );
  }

  /// Build a single action button for the AppBar
  Widget _buildAppBarAction(IconData icon, VoidCallback onTap, {bool hasNotification = false}) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.black, size: 28),
          onPressed: onTap,
        ),
        if (hasNotification)
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
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
          _tabButton("Mine", 0),
          const SizedBox(width: 15),
          _tabButton("My Friends", 1),
          const SizedBox(width: 15),
          _tabButton("Community", 2),
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
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Row(
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
        return _buildFriendsTab();
      case 2:
        return _buildCommunityTab();
      default:
        return _buildMineTab();
    }
  }

  /// Tab showing items from followed friends
  Widget _buildFriendsTab() {
    return StreamBuilder<List<String>>(
      stream: _friendService.getMutualFriendsIds(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final mutualIds = snapshot.data ?? [];
        if (mutualIds.isEmpty) {
          return const Center(child: Text("Mutual friends' items will appear here. Follow people back to see them!"));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('user_products')
              .where('userId', whereIn: mutualIds)
              .where('visibility', isEqualTo: 'public')
              .snapshots(),
          builder: (context, prodSnapshot) {
            if (prodSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final items = List<QueryDocumentSnapshot>.from(prodSnapshot.data?.docs ?? []);
            if (items.isEmpty) return const Center(child: Text("No public items from friends."));

            // Sort by creation date in memory to avoid needing complex indexes
            items.sort((a, b) {
              final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              if (aTime == null) return -1;
              if (bTime == null) return 1;
              return bTime.compareTo(aTime);
            });

            return _buildGroupedProductList(items);
          },
        );
      },
    );
  }

  /// Tab showing public items from the whole community
  Widget _buildCommunityTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_products')
          .where('visibility', isEqualTo: 'public')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final items = List<QueryDocumentSnapshot>.from(snapshot.data?.docs ?? []);
        if (items.isEmpty) return const Center(child: Text("No community items found."));

        // Filter out own items and sort by date in memory
        final communityItems = items.where((doc) => (doc.data() as Map<String, dynamic>)['userId'] != _currentUserId).toList();
        communityItems.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTime == null) return -1;
          if (bTime == null) return 1;
          return bTime.compareTo(aTime);
        });

        return _buildGroupedProductList(communityItems.take(50).toList());
      },
    );
  }

  /// Shared helper to build a scrollable list of products grouped by category
  Widget _buildGroupedProductList(List<QueryDocumentSnapshot> items) {
    final Map<String, List<QueryDocumentSnapshot>> groupedItems = {};
    for (var item in items) {
      final data = item.data() as Map<String, dynamic>;
      final category = (data['category']?.toString() ?? 'Other').toLowerCase();
      if (!groupedItems.containsKey(category)) groupedItems[category] = [];
      groupedItems[category]!.add(item);
    }

    final categories = groupedItems.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: categories.length,
      itemBuilder: (context, catIndex) {
        final category = categories[catIndex];
        final categoryItems = groupedItems[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                category[0].toUpperCase() + category.substring(1),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: categoryItems.length,
              itemBuilder: (context, index) {
                final data = Map<String, dynamic>.from(categoryItems[index].data() as Map<String, dynamic>);
                data['id'] = categoryItems[index].id;
                return _buildWardrobeCard(data);
              },
            ),
          ],
        );
      },
    );
  }

  /// Tab showing user's own items (uploaded and saved)
  Widget _buildMineTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _productService.getUserProducts(_currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Your wardrobe is empty. Upload some items!"));
        }

        final items = List<QueryDocumentSnapshot>.from(snapshot.data!.docs);
        items.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
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
    final String? posterId = originalProductId != null ? originalPosterId : uploaderId;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProductDetailPage(productData: data)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: rawImageUrl.isNotEmpty
                    ? Image.network(rawImageUrl, fit: BoxFit.contain, width: double.infinity)
                    : Container(color: Colors.grey.shade100, child: const Icon(Icons.image, size: 40, color: Colors.grey)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? 'No Name',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Display original poster name if not admin
                  if (posterId != null)
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(posterId).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
                        final userData = snapshot.data!.data() as Map<String, dynamic>;
                        
                        // Check if user is admin
                        final bool isAdmin = userData['role'] == 'admin' || userData['isAdmin'] == true;
                        if (isAdmin) {
                          // For admin items, show colors or nothing extra
                          return _buildColorSubtitle(data);
                        }

                        final posterName = userData['displayName'] ?? 'User';
                        return Text(
                          posterId == _currentUserId ? 'by you' : 'by $posterName',
                          style: TextStyle(color: primaryColor.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        );
                      },
                    )
                  else
                    _buildColorSubtitle(data),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to build the color subtitle for a product card
  Widget _buildColorSubtitle(Map<String, dynamic> data) {
    final dynamic rawColours = data['colours'] ?? data['colour'];
    List<dynamic> coloursList = [];
    if (rawColours is List) coloursList = rawColours;
    else if (rawColours != null && rawColours.toString().isNotEmpty) coloursList = [rawColours];

    String colourText = 'Various';
    if (coloursList.isNotEmpty) {
      final first = coloursList[0].toString().trim();
      if (first.isNotEmpty) {
        colourText = first[0].toUpperCase() + first.substring(1).toLowerCase();
        if (coloursList.length > 1) colourText += ' +${coloursList.length - 1}';
      }
    }
    return Text(colourText, style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
      maxLines: 1, overflow: TextOverflow.ellipsis,
    );
  }

  /// Show a BottomSheet for uploading a new item to the wardrobe
  void _showUploadItemDialog() {
    final TextEditingController nameController = TextEditingController();
    String visibility = 'private';
    String category = 'tops';
    String subcategory = 'none';
    List<String> selectedColours = [];
    List<String> selectedWeatherTags = [];
    List<String> selectedFunctionalTags = [];
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
    final List<String> weatherTags = ["hot", "mild", "cool", "cold", "rainy"];
    final List<String> functionalTags = ["waterproof", "breathable", "insulated", "windproof"];
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
              const Center(child: Text("Upload to Wardrobe", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              const SizedBox(height: 20),
              // Image Picker Box
              GestureDetector(
                onTap: () async {
                  final File? image = await _pickImageSource();
                  if (image != null) setModalState(() => selectedImage = image);
                },
                child: Container(
                  height: 120, width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
                  child: selectedImage != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(selectedImage!, fit: BoxFit.contain))
                      : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40, color: Colors.grey), SizedBox(height: 10), Text("Select Image", style: TextStyle(color: Colors.grey))]),
                ),
              ),
              const SizedBox(height: 15),
              // Name input and dropdowns for category, color, etc.
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Item Name", border: OutlineInputBorder())),
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
              Row(children: [
                Expanded(child: _buildSimpleDropdown("Gender", gender, genders, (val) => setModalState(() => gender = val!))),
                const SizedBox(width: 10),
                Expanded(child: _buildSimpleDropdown("Visibility", visibility, ['private', 'public'], (val) => setModalState(() => visibility = val!))),
              ]),
              const SizedBox(height: 15),
              const Text("Weather Tags", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                        if (selected) selectedWeatherTags.add(tag);
                        else selectedWeatherTags.remove(tag);
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
              const Text("Functional Tags", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                        if (selected) selectedFunctionalTags.add(tag);
                        else selectedFunctionalTags.remove(tag);
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
              const SizedBox(height: 25),
              // Upload Button
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
                      // Process image with background remover API using item name as filename
                      final urls = await _productService.removeBackground(
                        selectedImage!,
                        customFilename: nameController.text,
                      );
                      final imageUrl = urls['processed_url'] ?? '';
                      final rawImageUrl = urls['raw_url'] ?? '';

                      if (imageUrl.isEmpty) throw Exception('API returned empty processed image URL');

                      // Save record to Firestore
                      await _productService.uploadUserProduct(
                        userId: _currentUserId, 
                        name: nameController.text, 
                        imageUrl: imageUrl, 
                        rawImageUrl: rawImageUrl,
                        category: category,
                        subcategory: subcategory == 'none' ? null : subcategory, 
                        colours: selectedColours, 
                        gender: gender, 
                        visibility: visibility,
                        weatherTags: selectedWeatherTags,
                        functionalTags: selectedFunctionalTags,
                      );
                      if (context.mounted) {
                        Navigator.pop(context); Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uploaded successfully!")));
                      }
                    } catch (e) {
                      if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e"))); }
                    }
                  },
                  child: const Text("Upload Item", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper for building standard dropdowns in the upload form
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
