import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/friend_service.dart';
import '../services/product_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  final FriendService _friendService = FriendService();
  final ProductService _productService = ProductService();
  late TabController _tabController;
  String _searchQuery = "";
  
  // Filters
  String _selectedColor = "all";
  String _selectedCategory = "all";
  String _selectedSubcategory = "all";
  String _selectedGender = "all";

  final List<String> _colors = ['all', 'black', 'white', 'grey', 'blue', 'red', 'green', 'yellow', 'orange'];
  final List<String> _genders = ['all', 'male', 'female', 'unisex'];
  
  final Map<String, List<String>> _categoryData = {
    'all': ['all'],
    'accessories': ['all', 'caps', 'glasses', 'hats'],
    'bottoms': ['all', 'jeans', 'joggers', 'leggings', 'shorts', 'skirts'],
    'outerwear': ['all', 'blazers', 'jackets'],
    'tops': ['all', 'hoodies', 'polo shirts', 'shirts', 'sweatshirts', 't-shirts', 'tank tops'],
  };

  List<String> get _categories => _categoryData.keys.toList();
  List<String> get _subcategories => _categoryData[_selectedCategory.toLowerCase()] ?? ['all'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedColor = 'all';
                            _selectedCategory = 'all';
                            _selectedSubcategory = 'all';
                            _selectedGender = 'all';
                          });
                          setState(() {});
                        },
                        child: const Text('Reset All'),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildDropdownFilter('Category', _categories, _selectedCategory, (val) {
                    setModalState(() {
                      _selectedCategory = val ?? 'all';
                      _selectedSubcategory = 'all';
                    });
                    setState(() {});
                  }),
                  _buildDropdownFilter('Subcategory', _subcategories, _selectedSubcategory, (val) {
                    setModalState(() => _selectedSubcategory = val ?? 'all');
                    setState(() {});
                  }),
                  _buildDropdownFilter('Gender', _genders, _selectedGender, (val) {
                    setModalState(() => _selectedGender = val ?? 'all');
                    setState(() {});
                  }),
                  _buildDropdownFilter('Colour', _colors, _selectedColor, (val) {
                    setModalState(() => _selectedColor = val ?? 'all');
                    setState(() {});
                  }),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D0140),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildDropdownFilter(String label, List<String> options, String selectedValue, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            initialValue: !options.contains(selectedValue) ? options[0] : selectedValue,
            items: options.map((e) => DropdownMenuItem(
              value: e, 
              child: Text(e[0].toUpperCase() + e.substring(1)),
            )).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(
            hintText: "Search products or friends...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[400]),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterSheet,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF0D0140),
          labelColor: const Color(0xFF0D0140),
          onTap: (index) => setState(() {}),
          tabs: const [
            Tab(text: "Products"),
            Tab(text: "Friends"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductSearch(),
          _buildFriendSearch(),
        ],
      ),
    );
  }

  Widget _buildProductSearch() {
    return StreamBuilder<QuerySnapshot>(
      stream: _productService.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        final products = docs.where((doc) {
          final p = doc.data() as Map<String, dynamic>;
          final name = (p['name'] ?? '').toLowerCase();
          final colour = (p['colour'] ?? '').toLowerCase();
          final category = (p['category'] ?? '').toLowerCase();
          final subcategory = (p['subcategory'] ?? '').toLowerCase();
          final gender = (p['gender'] ?? '').toLowerCase();

          final matchesSearch = name.contains(_searchQuery);
          
          final matchesColor = _selectedColor == 'all' || colour == _selectedColor;
          final matchesCategory = _selectedCategory == 'all' || category == _selectedCategory;
          final matchesSubcategory = _selectedSubcategory == 'all' || subcategory == _selectedSubcategory;
          final matchesGender = _selectedGender == 'all' || gender == _selectedGender;

          return matchesSearch && matchesColor && matchesCategory && matchesSubcategory && matchesGender;
        }).toList();

        return Column(
          children: [
            _buildActiveFilters(),
            Expanded(
              child: products.isEmpty 
                ? const Center(child: Text('No products found'))
                : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index].data() as Map<String, dynamic>;
                  final imageUrl = product['imageURL'] as String?;
                  
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            child: imageUrl != null && imageUrl.startsWith('http')
                              ? ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity),
                                )
                              : const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text('${product['colour'] ?? 'N/A'} • ${product['gender'] ?? ''}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                              ),
                              StreamBuilder<bool>(
                                stream: _productService.isFavourited(
                                  FirebaseAuth.instance.currentUser?.uid ?? '',
                                  products[index].id,
                                ),
                                builder: (context, favSnapshot) {
                                  final isFav = favSnapshot.data ?? false;
                                  return IconButton(
                                    icon: Icon(
                                      isFav ? Icons.favorite : Icons.favorite_border,
                                      size: 20,
                                      color: isFav ? Colors.red : null,
                                    ),
                                    onPressed: () async {
                                      final userId = FirebaseAuth.instance.currentUser?.uid;
                                      if (userId != null) {
                                        try {
                                          await _productService.toggleFavourite(
                                            userId: userId,
                                            productId: products[index].id,
                                            productData: product,
                                          );
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(isFav 
                                                  ? "Removed from wardrobe" 
                                                  : "Added to wardrobe and favourites!"),
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
                                      }
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildActiveFilters() {
    List<Widget> chips = [];
    if (_selectedCategory != 'all') chips.add(_filterChip(_selectedCategory, () => setState(() => _selectedCategory = 'all')));
    if (_selectedSubcategory != 'all') chips.add(_filterChip(_selectedSubcategory, () => setState(() => _selectedSubcategory = 'all')));
    if (_selectedGender != 'all') chips.add(_filterChip(_selectedGender, () => setState(() => _selectedGender = 'all')));
    if (_selectedColor != 'all') chips.add(_filterChip(_selectedColor, () => setState(() => _selectedColor = 'all')));

    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: chips,
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback onDeleted) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(label[0].toUpperCase() + label.substring(1), style: const TextStyle(fontSize: 12)),
        onDeleted: onDeleted,
        deleteIconColor: Colors.black54,
        backgroundColor: Colors.grey[200],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildFriendSearch() {
    return StreamBuilder<QuerySnapshot>(
      stream: _friendService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Something went wrong'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final users = snapshot.data!.docs.where((doc) {
          final userData = doc.data() as Map<String, dynamic>;
          final userName = (userData['displayName'] ?? '').toLowerCase();
          final userEmail = (userData['email'] ?? '').toLowerCase();
          return userName.contains(_searchQuery) || userEmail.contains(_searchQuery);
        }).toList();

        if (users.isEmpty) return const Center(child: Text('No users found'));

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            final userId = users[index].id;
            final userName = userData['displayName'] ?? 'User';
            final userEmail = userData['email'] ?? '';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF0D0140),
                child: Text(
                  userName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(userName),
              subtitle: Text(userEmail),
              trailing: StreamBuilder<bool>(
                stream: _friendService.isFollowing(userId),
                builder: (context, followSnapshot) {
                  final isFollowing = followSnapshot.data ?? false;
                  return ElevatedButton(
                    onPressed: () {
                      if (isFollowing) {
                        _friendService.unfollowUser(userId);
                      } else {
                        _friendService.followUser(userId);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing ? Colors.grey : const Color(0xFF0D0140),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
