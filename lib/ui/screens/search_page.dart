import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../data/services/product_service.dart';
import 'product_detail_page.dart';
import 'notifications_page.dart';

/// Screen for searching and filtering community products
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();
  String _searchQuery = "";
  int _selectedTabIndex = 0;
  static const Color primaryColor = Color(0xFF0D0140);
  
  // Local state for filters
  String _selectedColor = "all";
  String _selectedCategory = "all";
  String _selectedSubcategory = "all";
  String _selectedGender = "all";
  String _selectedWeatherTag = "all";
  String _selectedFunctionalTag = "all";

  final List<String> _colors = ['all', 'black', 'white', 'grey', 'blue', 'red', 'green', 'yellow', 'orange'];
  final List<String> _genders = ['all', 'male', 'female', 'unisex'];
  final List<String> _weatherTags = ["all", "hot", "mild", "cool", "cold", "rainy"];
  final List<String> _functionalTags = ["all", "waterproof", "breathable", "insulated", "windproof"];
  
  final Map<String, List<String>> _categoryData = {
    'all': ['all'],
    'accessories': ['all', 'none', 'caps', 'glasses', 'hats'],
    'bottoms': ['all', 'none', 'jeans', 'joggers', 'leggings', 'shorts', 'skirts'],
    'outerwear': ['all', 'none', 'blazers', 'jackets'],
    'tops': ['all', 'none', 'hoodies', 'polo shirts', 'shirts', 'sweatshirts', 't-shirts', 'tank tops'],
    'dresses':['all','none'],
    'other': ['all', 'none'],
  };

  List<String> get _categories => _categoryData.keys.toList();
  List<String> get _subcategories => _categoryData[_selectedCategory.toLowerCase()] ?? ['all'];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _productService.getAppMetadata(),
      builder: (context, metadataSnapshot) {
        // Dynamically update available colors from Firestore metadata if available
        if (metadataSnapshot.hasData && metadataSnapshot.data!.exists) {
          final data = metadataSnapshot.data!.data() as Map<String, dynamic>;
          if (data.containsKey('colors')) {
            final List<dynamic> firestoreColors = data['colors'];
            _colors.clear();
            _colors.add('all');
            for (var c in firestoreColors) {
              if (c != null) {
                final String s = c.toString().toLowerCase().trim();
                if (!_colors.contains(s)) _colors.add(s);
              }
            }
          }
        }
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
              _buildAppBarAction(Icons.shopping_bag_outlined, () {}),
              _buildAppBarAction(Icons.chat_bubble_outline, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage()));
              }, hasNotification: true),
              const SizedBox(width: 10),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Search',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                // Search Bar and Filter toggle
                _buildSearchBar(),
                const SizedBox(height: 25),
                // Category Tabs
                _buildTabs(),
                const SizedBox(height: 25),
                // Dynamic Search Results
                Expanded(
                  child: _selectedTabIndex == 0 
                    ? _buildProductSearch() 
                    : Center(child: Text(_selectedTabIndex == 1 ? "Events Coming Soon" : "Trending News Coming Soon")),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  /// AppBar action buttons
  Widget _buildAppBarAction(IconData icon, VoidCallback onTap, {bool hasNotification = false}) {
    return Stack(
      children: [
        IconButton(icon: Icon(icon, color: Colors.black, size: 28), onPressed: onTap),
        if (hasNotification)
          Positioned(
            right: 12, top: 12,
            child: Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
            ),
          ),
      ],
    );
  }

  /// Search input field and filter trigger
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200, width: 1.5)),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey.shade400, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              decoration: InputDecoration(hintText: "Search Product", hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 16), border: InputBorder.none),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          GestureDetector(
            onTap: _showFilterSheet,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.tune, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  /// Navigation tabs for Community/Events/News
  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tabButton("Community", 0),
          const SizedBox(width: 15),
          _tabButton("Events", 1),
          const SizedBox(width: 15),
          _tabButton("Trending News", 2),
        ],
      ),
    );
  }

  /// Single tab button widget
  Widget _tabButton(String title, int index) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade100, width: 1.5),
        ),
        child: Text(
          title,
          style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }

  /// Main search logic and results list
  Widget _buildProductSearch() {
    return StreamBuilder<QuerySnapshot>(
      stream: _productService.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        // Perform client-side filtering for search query and dropdown filters
        final products = docs.where((doc) {
          final p = doc.data() as Map<String, dynamic>;
          final name = (p['name']?.toString() ?? '').toLowerCase();
          final category = (p['category']?.toString() ?? '').toLowerCase();
          final subcategory = (p['subcategory']?.toString() ?? '').toLowerCase();
          final gender = (p['gender']?.toString() ?? '').toLowerCase();
          
          final dynamic rawColours = p['colours'] ?? p['colour'];
          List<String> colourList = [];
          if (rawColours is List) colourList = rawColours.map((c) => c.toString().toLowerCase().trim()).toList();
          else if (rawColours != null && rawColours.toString().isNotEmpty) colourList = [rawColours.toString().toLowerCase().trim()];

          final matchesSearch = name.contains(_searchQuery);
          final matchesColour = _selectedColor == 'all' || colourList.contains(_selectedColor);
          final matchesCategory = _selectedCategory == 'all' || category == _selectedCategory;
          final matchesSubcategory = _selectedSubcategory == 'all' || (_selectedSubcategory == 'none' && subcategory.isEmpty) || subcategory == _selectedSubcategory;
          final matchesGender = _selectedGender == 'all' || gender == _selectedGender;

          final List<String> weatherTags = List<String>.from(p['weatherTags'] ?? []);
          final List<String> functionalTags = List<String>.from(p['functionalTags'] ?? []);

          final matchesWeather = _selectedWeatherTag == 'all' || weatherTags.contains(_selectedWeatherTag);
          final matchesFunctional = _selectedFunctionalTag == 'all' || functionalTags.contains(_selectedFunctionalTag);

          return matchesSearch && matchesColour && matchesCategory && matchesSubcategory && matchesGender && matchesWeather && matchesFunctional;
        }).toList();

        if (products.isEmpty && _searchQuery.isEmpty) return Center(child: Text("Type to search your wardrobe", style: TextStyle(color: Colors.grey.shade400, fontSize: 16)));
        if (products.isEmpty) return const Center(child: Text('No products found'));

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: products.length,
          separatorBuilder: (context, index) => const SizedBox(height: 15),
          itemBuilder: (context, index) {
            final doc = products[index];
            final product = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
            product['id'] = doc.id;
            final imageUrl = product['imageUrl'] ?? product['imageURL'] as String?;
            final rawImageUrl = product['rawImageUrl'] ?? imageUrl;
            
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailPage(productData: product))),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))]),
                child: Row(
                  children: [
                    // Product thumbnail
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
                      child: rawImageUrl != null && rawImageUrl.startsWith('http')
                        ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(rawImageUrl, fit: BoxFit.contain))
                        : const Icon(Icons.image, color: Colors.grey),
                    ),
                    const SizedBox(width: 20),
                    // Product info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                          const SizedBox(height: 4),
                          Builder(
                            builder: (context) {
                              final dynamic rawColours = product['colours'] ?? product['colour'];
                              List<dynamic> coloursList = [];
                              if (rawColours is List) coloursList = rawColours;
                              else if (rawColours != null && rawColours.toString().isNotEmpty) coloursList = [rawColours];
                              String colourText = coloursList.isNotEmpty ? coloursList.map((c) {
                                final s = c.toString().trim();
                                if (s.isEmpty) return '';
                                return s[0].toUpperCase() + s.substring(1).toLowerCase();
                              }).where((s) => s.isNotEmpty).join(', ') : 'N/A';
                              if (colourText.length > 20) colourText = '${colourText.substring(0, 17)}...';
                              return Text(colourText, style: TextStyle(color: Colors.grey.shade400, fontSize: 14));
                            }
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    );
  }

  /// Show BottomSheet for advanced filtering
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    TextButton(onPressed: () {
                      setModalState(() { 
                        _selectedColor = 'all'; 
                        _selectedCategory = 'all'; 
                        _selectedSubcategory = 'all'; 
                        _selectedGender = 'all'; 
                        _selectedWeatherTag = 'all';
                        _selectedFunctionalTag = 'all';
                      });
                      setState(() {});
                    }, child: const Text('Reset All')),
                  ]),
                  const Divider(),
                  _buildDropdownFilter('Category', _categories, _selectedCategory, (val) {
                    setModalState(() { _selectedCategory = val ?? 'all'; _selectedSubcategory = 'all'; });
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
                  _buildDropdownFilter('Weather', _weatherTags, _selectedWeatherTag, (val) {
                    setModalState(() => _selectedWeatherTag = val ?? 'all');
                    setState(() {});
                  }),
                  _buildDropdownFilter('Functionality', _functionalTags, _selectedFunctionalTag, (val) {
                    setModalState(() => _selectedFunctionalTag = val ?? 'all');
                    setState(() {});
                  }),
                  _buildDropdownFilter('Colour', _colors, _selectedColor, (val) {
                    setModalState(() => _selectedColor = val ?? 'all');
                    setState(() {});
                  }),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: () => Navigator.pop(context), child: const Text('Apply Filters'),
                  )),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      },
    );
  }

  /// Helper to build a filter dropdown in the sheet
  Widget _buildDropdownFilter(String label, List<String> options, String selectedValue, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            value: !options.contains(selectedValue) ? options[0] : selectedValue,
            items: options.map((e) => DropdownMenuItem(value: e, child: Text(e[0].toUpperCase() + e.substring(1)))).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
            ),
          ),
        ],
      ),
    );
  }
}
