import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/product_service.dart';
import '../services/friend_service.dart';
import 'product_detail_page.dart';
import 'profile_page.dart';

class WardrobePage extends StatefulWidget {
  const WardrobePage({super.key});

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  final ProductService _productService = ProductService();
  final FriendService _friendService = FriendService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  int _selectedTabIndex = 0;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Daily Dress Up',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTabs(),
            const SizedBox(height: 20),
            Expanded(
              child: _buildSelectedTab(),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedTabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showUploadItemDialog,
              backgroundColor: const Color(0xFF0D0140),
              icon: const Icon(Icons.cloud_upload, color: Colors.white),
              label: const Text('Upload Item', style: TextStyle(color: Colors.white)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            )
          : null,
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        _tabButton("Mine", 0),
        const SizedBox(width: 10),
        _tabButton("My Friends", 1),
        const SizedBox(width: 10),
        _tabButton("Community", 2),
      ],
    );
  }

  Widget _tabButton(String title, int index) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D0140) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isSelected ? const Color(0xFF0D0140) : Colors.grey.shade300),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

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

  Widget _buildFriendsTab() {
    return StreamBuilder<List<String>>(
      stream: _friendService.getMutualFriendsIds(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final mutualIds = snapshot.data ?? [];
        if (mutualIds.isEmpty) {
          return const Center(child: Text("Mutual friends will appear here. Follow people back to see them!"));
        }

        return ListView.builder(
          itemCount: mutualIds.length,
          itemBuilder: (context, index) {
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(mutualIds[index]).snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) return const SizedBox.shrink();
                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final name = userData['displayName'] ?? 'User';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF0D0140),
                    child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(name),
                  subtitle: const Text("View Wardrobe"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage(userId: mutualIds[index])),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCommunityTab() {
    return StreamBuilder<List<String>>(
      stream: _friendService.getMutualFriendsIds(),
      builder: (context, mutualSnapshot) {
        final mutualIds = mutualSnapshot.data ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').limit(20).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No users found"));

            final users = snapshot.data!.docs.where((doc) {
              return doc.id != _currentUserId && !mutualIds.contains(doc.id);
            }).toList();

            if (users.isEmpty) return const Center(child: Text("All current users are your mutual friends!"));

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final userData = users[index].data() as Map<String, dynamic>;
                final name = userData['displayName'] ?? 'User';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF0D0140),
                    child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(name),
                  subtitle: const Text("View Profile"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage(userId: users[index].id)),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMineTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _productService.getUserProducts(_currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Your wardrobe is empty. Upload some items!"));
        }

        final items = snapshot.data!.docs;

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final data = items[index].data() as Map<String, dynamic>;
            return _buildWardrobeCard(data);
          },
        );
      },
    );
  }

  Widget _buildWardrobeCard(Map<String, dynamic> data) {
    final imageUrl = data['imageUrl'] ?? data['imageURL'] ?? '';
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity)
                    : Container(color: Colors.grey.shade200, child: const Icon(Icons.image, size: 40)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? 'No Name',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${data['colour'] ?? ''} • ${data['gender'] ?? ''}',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadItemDialog() {
    final TextEditingController nameController = TextEditingController();
    String visibility = 'private';
    String category = 'tops';
    String subcategory = 't-shirts';
    String colour = 'black';
    String gender = 'unisex';
    File? selectedImage;

    final Map<String, List<String>> categoryData = {
      'accessories': ['caps', 'glasses', 'hats'],
      'bottoms': ['jeans', 'joggers', 'leggings', 'shorts', 'skirts'],
      'outerwear': ['blazers', 'jackets'],
      'tops': ['hoodies', 'polo shirts', 'shirts', 'sweatshirts', 't-shirts', 'tank tops'],
    };

    final List<String> colors = ['black', 'white', 'grey', 'blue', 'red', 'green', 'yellow', 'orange'];
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
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Upload to Wardrobe", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setModalState(() {
                      selectedImage = File(image.path);
                    });
                  }
                },
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(selectedImage!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                            SizedBox(height: 10),
                            Text("Select Image", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Item Name", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildSimpleDropdown("Category", category, categoryData.keys.toList(), (val) {
                      setModalState(() {
                        category = val!;
                        subcategory = categoryData[category]![0];
                      });
                    }),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSimpleDropdown("Subcategory", subcategory, categoryData[category]!, (val) {
                      setModalState(() => subcategory = val!);
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildSimpleDropdown("Colour", colour, colors, (val) => setModalState(() => colour = val!)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSimpleDropdown("Gender", gender, genders, (val) => setModalState(() => gender = val!)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildSimpleDropdown("Visibility", visibility, ['private', 'public'], (val) => setModalState(() => visibility = val!)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D0140),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () async {
                    if (selectedImage == null || nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Missing info")));
                      return;
                    }

                    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

                    try {
                      // Upload to Supabase instead of Firebase Storage
                      final imageUrl = await _productService.uploadToSupabase(
                        imageFile: selectedImage!,
                        category: category,
                        subcategory: subcategory,
                      );

                      await _productService.uploadUserProduct(
                        userId: _currentUserId,
                        name: nameController.text,
                        imageUrl: imageUrl,
                        category: category,
                        subcategory: subcategory,
                        colour: colour,
                        gender: gender,
                        visibility: visibility,
                      );
                      
                      if (context.mounted) {
                        Navigator.pop(context); // Pop loading
                        Navigator.pop(context); // Pop sheet
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uploaded to Supabase & Firestore!")));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
                      }
                    }
                  },
                  child: const Text("Upload Item", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e[0].toUpperCase() + e.substring(1)))).toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10), border: OutlineInputBorder()),
        ),
      ],
    );
  }
}
