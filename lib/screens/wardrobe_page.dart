import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/product_service.dart';

class WardrobePage extends StatefulWidget {
  const WardrobePage({super.key});

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  final ProductService _productService = ProductService();
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
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
              child: _selectedTabIndex == 0 ? _buildMineTab() : const Center(child: Text("Coming Soon")),
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
    final imageUrl = data['imageUrl'] ?? '';
    return Container(
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
                  data['visibility'] ?? 'private',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadItemDialog() {
    final TextEditingController nameController = TextEditingController();
    String visibility = 'private';
    File? selectedImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                  height: 150,
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
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Item Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: visibility,
                decoration: const InputDecoration(
                  labelText: "Visibility",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'private', child: Text("Private")),
                  DropdownMenuItem(value: 'public', child: Text("Public")),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => visibility = val);
                },
              ),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select an image and enter a name")),
                      );
                      return;
                    }

                    // Show loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      final imageUrl = await _productService.uploadProductImage(_currentUserId, selectedImage!);
                      await _productService.uploadUserProduct(
                        userId: _currentUserId,
                        name: nameController.text,
                        imageUrl: imageUrl,
                        visibility: visibility,
                      );
                      
                      if (context.mounted) {
                        Navigator.pop(context); // Pop loading
                        Navigator.pop(context); // Pop sheet
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Item uploaded successfully!")),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context); // Pop loading
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Upload failed: $e")),
                        );
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
}
