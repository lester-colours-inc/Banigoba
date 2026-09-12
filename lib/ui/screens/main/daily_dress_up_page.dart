// Shows daily outfit inspiration using local weather and wardrobe actions.
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../data/models/affirmation.dart';
import '../../../data/models/post.dart';
import '../../../data/services/weather_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/post_service.dart';
import '../../../data/services/friend_service.dart';
import '../../../data/services/product_service.dart';
import '../../../data/services/upcoming_event_service.dart';
import '../../../data/models/weather.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/app_routes.dart';
import '../../widgets/affirmation_row.dart';
import '../../widgets/post_comments_sheet.dart';
import '../../widgets/cart_badge_button.dart';
import '../../widgets/safe_product_image.dart';
import '../../widgets/try_on_product_picker.dart';
import '../wardrobe/wardrobe_calendar_page.dart';

/// Page displaying daily dress up recommendations and user posts
class DailyDressUpPage extends StatefulWidget {
  const DailyDressUpPage({super.key});

  @override
  State<DailyDressUpPage> createState() => _DailyDressUpPageState();
}

class _DailyDressUpPageState extends State<DailyDressUpPage> {
  int _selectedTabIndex = 0;
  static Color primaryColor = Color(0xFF0D0140);

  final WeatherService _weatherService = WeatherService();
  final PostService _postService = PostService();
  final FriendService _friendService = FriendService();
  final ProductService _productService = ProductService();
  final UpcomingEventService _upcomingEventService = UpcomingEventService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, Future<_PostAuthor>> _authorProfiles = {};
  Weather? _currentWeather;
  bool _isLoadingWeather = true;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  /// Fetches weather data using the current device location
  Future<void> _fetchWeather() async {
    // Check permissions before attempting to fetch weather
    final status = await Geolocator.checkPermission();

    if (status == LocationPermission.deniedForever) {
      // Silently fail - location permissions permanently denied
      if (!mounted) return;
      setState(() {
        _isLoadingWeather = false;
      });
      return;
    }

    setState(() {
      _isLoadingWeather = true;
    });
    try {
      final Position position = await _determinePosition();
      final String latLong = "${position.latitude},${position.longitude}";
      final weather = await _weatherService.fetchOptionalWeather(latLong);
      if (mounted) {
        setState(() {
          _currentWeather = weather;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
        });
      }
      debugPrint("Weather fetch error: $e");
    }
  }

  /// Handles location permission and returns the current position
  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    var status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      status = await Geolocator.requestPermission();
      if (status == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (status == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.low),
    );
  }

  // Kept temporarily for compatibility while all active entry points use the
  // shared Build Your Look picker.
  // ignore: unused_element
  Future<void> _openTryOnProductPicker({
    Map<String, dynamic>? fallbackProduct,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please sign in to choose a product.')),
      );
      return;
    }

    Future<_TryOnSources> loadProducts() async {
      final results = await Future.wait([
        _productService.getCatalogProducts(),
        _productService.getWardrobeProducts(user.uid),
      ]);
      final catalogProducts = results[0];
      final wardrobeProducts = results[1];
      final fallbackImage = fallbackProduct == null
          ? ''
          : _productImageUrl(fallbackProduct);
      if (fallbackImage.isNotEmpty &&
          !catalogProducts.any(
            (product) => _productImageUrl(product) == fallbackImage,
          )) {
        catalogProducts.insert(0, fallbackProduct!);
      }
      return _TryOnSources(
        catalog: catalogProducts,
        wardrobe: wardrobeProducts,
      );
    }

    try {
      var productsFuture = loadProducts();
      final products = await showModalBottomSheet<List<Map<String, dynamic>>>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black54,
        builder: (sheetContext) {
          var selectedGroup = 'all';
          var selectedSource = 'catalog';
          final selectedProducts = <String, Map<String, dynamic>>{};

          return StatefulBuilder(
            builder: (context, setSheetState) {
              return FractionallySizedBox(
                heightFactor: 0.9,
                child: SafeArea(
                  top: false,
                  child: Builder(
                    builder: (context) {
                      final colors = Theme.of(context).colorScheme;
                      return Container(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 44,
                                height: 5,
                                margin: EdgeInsets.only(top: 12),
                                decoration: BoxDecoration(
                                  color: colors.outlineVariant,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(20, 18, 12, 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Choose what to try on',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Build a look from the catalog or your wardrobe.',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        Navigator.pop(sheetContext),
                                    icon: Icon(Icons.close),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                              child: SegmentedButton<String>(
                                segments: [
                                  ButtonSegment(
                                    value: 'catalog',
                                    icon: Icon(Icons.storefront_outlined),
                                    label: Text('Catalog'),
                                  ),
                                  ButtonSegment(
                                    value: 'wardrobe',
                                    icon: Icon(Icons.favorite_outline),
                                    label: Text('My Wardrobe'),
                                  ),
                                ],
                                selected: {selectedSource},
                                onSelectionChanged: (selection) {
                                  setSheetState(() {
                                    selectedSource = selection.first;
                                    selectedGroup = 'all';
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              height: 84,
                              child: ListView(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                scrollDirection: Axis.horizontal,
                                children: [
                                  _buildTryOnCategory(
                                    label: 'All',
                                    value: 'all',
                                    icon: Icons.grid_view_rounded,
                                    selectedValue: selectedGroup,
                                    onTap: (value) {
                                      setSheetState(
                                        () => selectedGroup = value,
                                      );
                                    },
                                  ),
                                  _buildTryOnCategory(
                                    label: 'Accessories',
                                    value: 'accessories',
                                    icon: Icons.watch_outlined,
                                    selectedValue: selectedGroup,
                                    onTap: (value) {
                                      setSheetState(
                                        () => selectedGroup = value,
                                      );
                                    },
                                  ),
                                  _buildTryOnCategory(
                                    label: 'Bottoms',
                                    value: 'bottoms',
                                    icon: Icons.dry_cleaning_outlined,
                                    selectedValue: selectedGroup,
                                    onTap: (value) {
                                      setSheetState(
                                        () => selectedGroup = value,
                                      );
                                    },
                                  ),
                                  _buildTryOnCategory(
                                    label: 'Dresses',
                                    value: 'dresses',
                                    icon: Icons.woman_2_outlined,
                                    selectedValue: selectedGroup,
                                    onTap: (value) {
                                      setSheetState(
                                        () => selectedGroup = value,
                                      );
                                    },
                                  ),
                                  _buildTryOnCategory(
                                    label: 'Outerwear',
                                    value: 'outerwear',
                                    icon: Icons.layers_outlined,
                                    selectedValue: selectedGroup,
                                    onTap: (value) {
                                      setSheetState(
                                        () => selectedGroup = value,
                                      );
                                    },
                                  ),
                                  _buildTryOnCategory(
                                    label: 'Tops',
                                    value: 'tops',
                                    icon: Icons.checkroom_outlined,
                                    selectedValue: selectedGroup,
                                    onTap: (value) {
                                      setSheetState(
                                        () => selectedGroup = value,
                                      );
                                    },
                                  ),
                                  _buildTryOnCategory(
                                    label: 'Other',
                                    value: 'other',
                                    icon: Icons.more_horiz,
                                    selectedValue: selectedGroup,
                                    onTap: (value) {
                                      setSheetState(
                                        () => selectedGroup = value,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 1),
                            Expanded(
                              child: FutureBuilder<_TryOnSources>(
                                future: productsFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Unable to load products right now.',
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(height: 12),
                                            FilledButton.icon(
                                              onPressed: () {
                                                setSheetState(() {
                                                  productsFuture =
                                                      loadProducts();
                                                });
                                              },
                                              icon: Icon(Icons.refresh),
                                              label: Text('Retry'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  final sources =
                                      snapshot.data ?? const _TryOnSources();
                                  final allProducts =
                                      selectedSource == 'wardrobe'
                                      ? sources.wardrobe
                                      : sources.catalog;
                                  final products = allProducts
                                      .where(
                                        (item) =>
                                            (selectedGroup == 'all' ||
                                                _tryOnGroup(item) ==
                                                    selectedGroup) &&
                                            _productImageUrl(item).isNotEmpty,
                                      )
                                      .toList();

                                  if (products.isEmpty) {
                                    return Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.inventory_2_outlined,
                                              size: 58,
                                              color: colors.outline,
                                            ),
                                            SizedBox(height: 12),
                                            Text(
                                              allProducts.isEmpty
                                                  ? 'No products are available yet.'
                                                  : 'No ${_tryOnGroupLabel(selectedGroup).toLowerCase()} available. Try another category.',
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  return GridView.builder(
                                    padding: EdgeInsets.all(16),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                          childAspectRatio: 0.72,
                                        ),
                                    itemCount: products.length,
                                    itemBuilder: (context, index) {
                                      final data = products[index];
                                      final imageUrl = _productImageUrl(data);
                                      final name = (data['name'] ?? 'Clothing')
                                          .toString();
                                      final selectionKey = _tryOnSelectionKey(
                                        data,
                                      );
                                      final selected =
                                          selectedProducts[selectionKey] !=
                                              null &&
                                          _productImageUrl(
                                                selectedProducts[selectionKey]!,
                                              ) ==
                                              imageUrl;

                                      return Material(
                                        color: colors.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(18),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          onTap: () {
                                            setSheetState(() {
                                              if (selected) {
                                                selectedProducts.remove(
                                                  selectionKey,
                                                );
                                                return;
                                              }
                                              _addTryOnProductToSelection(
                                                selectedProducts,
                                                data,
                                              );
                                            });
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              border: Border.all(
                                                color: selected
                                                    ? primaryColor
                                                    : colors.outlineVariant,
                                                width: selected ? 3 : 1,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Stack(
                                                    fit: StackFit.expand,
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.vertical(
                                                              top:
                                                                  Radius.circular(
                                                                    17,
                                                                  ),
                                                            ),
                                                        child: Container(
                                                          color: colors
                                                              .surfaceContainerLow,
                                                          child:
                                                              SafeProductImage(
                                                                imageUrl:
                                                                    imageUrl,
                                                                width: double
                                                                    .infinity,
                                                                height: double
                                                                    .infinity,
                                                                fit: BoxFit
                                                                    .contain,
                                                                iconSize: 42,
                                                              ),
                                                        ),
                                                      ),
                                                      if (selected)
                                                        Positioned(
                                                          top: 8,
                                                          right: 8,
                                                          child: CircleAvatar(
                                                            radius: 15,
                                                            backgroundColor:
                                                                primaryColor,
                                                            child: Icon(
                                                              Icons.check,
                                                              size: 18,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(12),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        name,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      SizedBox(height: 4),
                                                      Text(
                                                        'Tap to try on',
                                                        style: TextStyle(
                                                          color: primaryColor
                                                              .withValues(
                                                                alpha: 0.7,
                                                              ),
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            SafeArea(
                              top: false,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                                child: FilledButton.icon(
                                  onPressed: selectedProducts.isEmpty
                                      ? null
                                      : () => Navigator.pop(
                                          sheetContext,
                                          selectedProducts.values.toList(),
                                        ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    minimumSize: Size(double.infinity, 54),
                                  ),
                                  icon: Icon(Icons.auto_awesome),
                                  label: Text(
                                    selectedProducts.isEmpty
                                        ? 'Select products'
                                        : 'Complete Look (${selectedProducts.length})',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      );

      if (!mounted || products == null || products.isEmpty) return;

      await Navigator.pushNamed(
        context,
        AppRoutes.avatarTryOn,
        arguments: {
          'products': products,
          'category':
              (products.first['category'] ?? _tryOnGroup(products.first))
                  .toString(),
        },
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to open try-on product picker: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open products: $error')),
      );
    }
  }

  Future<void> _tryOnPost(Post post) async {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please sign in first.')));
      return;
    }

    var loadingVisible = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );

    try {
      final products = await _postService.getPostOutfitProducts(post);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      loadingVisible = false;

      if (products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This older post has no saved product details. Choose products to recreate the look.',
            ),
          ),
        );
      }

      final selectedProducts = await showTryOnProductPicker(
        context,
        initialProducts: products,
        outfitLabel: post.authorId == FirebaseAuth.instance.currentUser?.uid
            ? 'This Look'
            : "Friend's Look",
      );
      if (!mounted || selectedProducts == null || selectedProducts.isEmpty) {
        return;
      }

      await _postService.notifyPostTryOn(post);
      if (!mounted) return;

      await Navigator.pushNamed(
        context,
        AppRoutes.avatarTryOn,
        arguments: {
          'products': selectedProducts,
          'category':
              (selectedProducts.first['category'] ??
                      _tryOnGroup(selectedProducts.first))
                  .toString(),
          'sourcePostId': post.id,
          'sourceOutfitId': post.outfitId,
        },
      );
    } catch (error) {
      if (!mounted) return;
      if (loadingVisible) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to load outfit: $error')));
    }
  }

  Widget _buildTryOnCategory({
    required String label,
    required String value,
    required IconData icon,
    required String selectedValue,
    required ValueChanged<String> onTap,
  }) {
    final isSelected = value == selectedValue;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(right: 10, top: 8, bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 180),
          width: 104,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? primaryColor : colors.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 19,
                color: isSelected ? Colors.white : primaryColor,
              ),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _tryOnGroup(Map<String, dynamic> product) {
    final category = (product['category'] ?? '').toString().toLowerCase();
    final subcategory = (product['subcategory'] ?? '').toString().toLowerCase();
    final value = '$category $subcategory';

    if (value.contains('accessor') ||
        value.contains('hat') ||
        value.contains('cap') ||
        value.contains('glass') ||
        value.contains('bag') ||
        value.contains('jewel') ||
        value.contains('watch')) {
      return 'accessories';
    }
    if (value.contains('dress') ||
        value.contains('jumpsuit') ||
        value.contains('one-piece')) {
      return 'dresses';
    }
    if (value.contains('outerwear') ||
        value.contains('jacket') ||
        value.contains('blazer') ||
        value.contains('coat') ||
        value.contains('hoodie') ||
        value.contains('cardigan')) {
      return 'outerwear';
    }
    if (value.contains('bottom') ||
        value.contains('trouser') ||
        value.contains('pants') ||
        value.contains('jean') ||
        value.contains('short') ||
        value.contains('skirt') ||
        value.contains('legging') ||
        value.contains('jogger')) {
      return 'bottoms';
    }
    if (value.contains('top') ||
        value.contains('shirt') ||
        value.contains('tee') ||
        value.contains('tank') ||
        value.contains('blouse') ||
        value.contains('polo') ||
        value.contains('sweatshirt')) {
      return 'tops';
    }
    return 'other';
  }

  String _tryOnGroupLabel(String group) {
    switch (group) {
      case 'accessories':
        return 'Accessories';
      case 'bottoms':
        return 'Bottoms';
      case 'dresses':
        return 'Dresses';
      case 'outerwear':
        return 'Outerwear';
      case 'other':
        return 'Other';
      case 'all':
        return 'Products';
      default:
        return 'Tops';
    }
  }

  String _tryOnSelectionKey(Map<String, dynamic> product) {
    final group = _tryOnGroup(product);
    if (group != 'accessories') return group;

    final imageUrl = _productImageUrl(product);
    final id =
        (product['id'] ??
                product['productId'] ??
                product['originalProductId'] ??
                (imageUrl.isNotEmpty ? imageUrl : null) ??
                product['name'] ??
                product.hashCode)
            .toString();
    return '$group:$id';
  }

  void _addTryOnProductToSelection(
    Map<String, Map<String, dynamic>> selectedProducts,
    Map<String, dynamic> product,
  ) {
    final group = _tryOnGroup(product);
    if (group == 'accessories') {
      selectedProducts[_tryOnSelectionKey(product)] = product;
      return;
    }

    if (group == 'dresses') {
      _removeTryOnGroups(selectedProducts, const {'tops', 'bottoms', 'other'});
      selectedProducts[group] = product;
      return;
    }

    if (group == 'tops' || group == 'bottoms' || group == 'other') {
      _removeTryOnGroups(selectedProducts, const {'dresses'});
    }
    selectedProducts[group] = product;
  }

  void _removeTryOnGroups(
    Map<String, Map<String, dynamic>> selectedProducts,
    Set<String> groups,
  ) {
    selectedProducts.removeWhere(
      (_, product) => groups.contains(_tryOnGroup(product)),
    );
  }

  String _productImageUrl(Map<String, dynamic> product) {
    const imageFields = [
      'rawImageUrl',
      'imageUrl',
      'imageURL',
      'processedImageUrl',
      'processed_url',
      'raw_url',
    ];
    for (final field in imageFields) {
      final value = product[field];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: colors.onSurface),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'My Daily Dress Up',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
            ),
            _buildAppBarAction(
              Icons.shopping_bag_outlined,
              () => Navigator.pushNamed(context, AppRoutes.cart),
            ),
          ],
        ),
        actions: [SizedBox(width: 20)],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            _buildTabs(),
            SizedBox(height: 20),
            _buildStatusHeader(),
            SizedBox(height: 25),
            _buildPostsFeed(),
            SizedBox(height: 30),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WardrobeCalendarPage(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostsFeed() {
    return StreamBuilder<List<Post>>(
      stream: _postService.getPosts(),
      builder: (context, postSnapshot) {
        if (postSnapshot.hasError) {
          debugPrint('Unable to load posts: ${postSnapshot.error}');
          return _buildFeedMessage(
            icon: Icons.cloud_off_outlined,
            message: 'Posts could not be loaded.',
          );
        }

        if (!postSnapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final posts = postSnapshot.data!;
        if (_selectedTabIndex == 1) {
          return StreamBuilder<List<String>>(
            stream: _friendService.getMutualFriendsIds(),
            builder: (context, friendSnapshot) {
              if (friendSnapshot.hasError) {
                return _buildFeedMessage(
                  icon: Icons.people_outline,
                  message: 'Friend posts could not be loaded.',
                );
              }
              if (!friendSnapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final friendIds = friendSnapshot.data!.toSet();
              return _buildPostList(
                posts
                    .where(
                      (post) =>
                          post.isPublic && friendIds.contains(post.authorId),
                    )
                    .toList(),
                emptyMessage: 'No posts from your friends yet.',
              );
            },
          );
        }

        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final filteredPosts = _selectedTabIndex == 0
            ? posts.where((post) => post.authorId == currentUserId).toList()
            : posts.where((post) => post.isPublic).toList();

        return _buildPostList(
          filteredPosts,
          emptyMessage: _selectedTabIndex == 0
              ? 'You have not shared a daily dress-up post yet.'
              : 'No community posts yet.',
          useMineLayout: _selectedTabIndex == 0,
        );
      },
    );
  }

  Widget _buildPostList(
    List<Post> posts, {
    required String emptyMessage,
    bool useMineLayout = false,
  }) {
    if (posts.isEmpty) {
      return _buildFeedMessage(
        icon: Icons.checkroom_outlined,
        message: emptyMessage,
      );
    }

    return Column(
      children: [
        for (var index = 0; index < posts.length; index++) ...[
          useMineLayout
              ? _buildMinePostItem(posts[index], index)
              : _buildDressUpItem(posts[index], index),
          if (index != posts.length - 1) SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildMinePostItem(Post post, int index) {
    final cardColors = [
      Color(0xFFF1B4F1),
      Color(0xFFBDB7FF),
      Color(0xFFFFECB0),
      Color(0xFFBDEDD8),
    ];

    return FutureBuilder<_PostAuthor>(
      future: _authorProfiles.putIfAbsent(
        post.authorId,
        () => _loadPostAuthor(post.authorId),
      ),
      builder: (context, authorSnapshot) {
        final author =
            authorSnapshot.data ?? _PostAuthor.fallback(post.authorId);
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
        final isOwner = currentUserId == post.authorId;
        final imageUrl = post.imageURL.isNotEmpty
            ? post.imageURL
            : author.fullBodyImageUrl;
        final username = isOwner ? 'You' : author.displayName;
        final caption = post.caption.trim().isEmpty
            ? 'Daily Outfit'
            : post.caption.trim();
        final styleLabel = author.stylePreference.isEmpty
            ? 'Styled for your day'
            : '${_titleCase(author.stylePreference)} style';
        final cardHeight = caption.length > 95
            ? 310.0
            : caption.length > 55
            ? 270.0
            : 220.0;

        return Column(
          children: [
            Container(
              width: double.infinity,
              height: cardHeight,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: cardColors[index % cardColors.length],
                borderRadius: BorderRadius.circular(16),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final imageWidth = constraints.maxWidth * 0.46;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  20,
                                  50,
                                  imageWidth > 160 ? 6 : 12,
                                  20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      username,
                                      softWrap: true,
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: _responsiveCardFontSize(
                                          username,
                                          base: 22,
                                          compact: 18,
                                        ),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      caption,
                                      softWrap: true,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        fontSize: _responsiveCardFontSize(
                                          caption,
                                          base: 17,
                                          compact: 13,
                                        ),
                                        fontWeight: FontWeight.w700,
                                        height: 1.18,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      styleLabel,
                                      softWrap: true,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        fontSize: 13,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: imageWidth,
                              child: ColoredBox(
                                color: imageUrl.isEmpty
                                    ? Colors.transparent
                                    : Colors.white,
                                child: _buildMinePostVisual(post, imageUrl),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatPostTime(post.createdAt),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMineCommand(
                    icon: Icons.shortcut_outlined,
                    label: 'Try On',
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    onTap: () => _tryOnPost(post),
                  ),
                ),
                SizedBox(width: 8),
                if (post.isPublic) ...[
                  Expanded(
                    child: _buildMineCommand(
                      icon: Icons.chat_bubble_outline,
                      label: 'Comment',
                      backgroundColor: Color(0xFFFF8A2A),
                      foregroundColor: Colors.white,
                      onTap: () => showPostCommentsSheet(context, post),
                    ),
                  ),
                  SizedBox(width: 8),
                  if (isOwner) ...[
                    Expanded(
                      child: _buildMineCommand(
                        icon: Icons.lock_outline,
                        label: 'Private',
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface,
                        onTap: () => _privatePost(post),
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                ],
                if (isOwner && !post.isPublic)
                  Expanded(
                    child: _buildMineCommand(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      onTap: () => _sharePost(post),
                    ),
                  ),
                if (isOwner && !post.isPublic) SizedBox(width: 8),
                if (isOwner)
                  Expanded(
                    child: _buildMineCommand(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                      onTap: () => _deletePost(post),
                    ),
                  ),
              ],
            ),
            if (post.isPublic) ...[
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Column(
                  children: [
                    AffirmationRow(
                      targetType: AffirmationTargetType.post,
                      targetId: post.id,
                      targetOwnerId: post.authorId,
                      currentUserId: currentUserId,
                      ownerName: isOwner ? 'your look' : author.displayName,
                      onOpenReceived: () => showReceivedAffirmations(
                        context,
                        targetType: AffirmationTargetType.post,
                        targetId: post.id,
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    SizedBox(
                      height: 40,
                      child: _buildMineReaction(
                        icon: Icons.chat_bubble_outline,
                        label: '${post.commentCount} comments',
                        color: primaryColor,
                        onTap: () => showPostCommentsSheet(context, post),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _sharePost(Post post) async {
    final shouldShare = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Make this post public?'),
        content: const Text(
          'Friends and community members will be able to see, like, and comment on this look.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.public),
            label: const Text('Make Public'),
          ),
        ],
      ),
    );
    if (shouldShare != true) return;

    try {
      await _postService.makePostPublic(post.id);
      await NotificationService().notifyFollowersNewPost(
        post.caption.isEmpty ? 'Daily Outfit' : post.caption,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post is now public.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to share post: $error')));
    }
  }

  Future<void> _privatePost(Post post) async {
    final shouldPrivate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Make this post private?'),
        content: const Text(
          'This look will be removed from friends and community feeds. Likes and comments stay saved if you share it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.lock_outline),
            label: const Text('Make Private'),
          ),
        ],
      ),
    );
    if (shouldPrivate != true) return;

    try {
      await _postService.makePostPrivate(post.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post is now private.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to make post private: $error')),
      );
    }
  }

  Future<void> _deletePost(Post post) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this Daily Dress Up?'),
        content: const Text(
          'This removes the look from My Daily Dress Up and deletes its likes and comments. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    try {
      await _postService.deletePost(post.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Daily Dress Up deleted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete Daily Dress Up: $error')),
      );
    }
  }

  Widget _buildMinePostImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Align(
        alignment: Alignment.center,
        child: Icon(
          Icons.checkroom_outlined,
          size: 72,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      webHtmlElementStrategy: kIsWeb
          ? WebHtmlElementStrategy.prefer
          : WebHtmlElementStrategy.never,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Unable to display Mine post image: $error');
        return Align(
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image_outlined,
            size: 54,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        );
      },
    );
  }

  Widget _buildMinePostVisual(Post post, String imageUrl) {
    final products = _collageProducts(post);
    if (products.isEmpty) return _buildMinePostImage(imageUrl);

    return Padding(
      padding: EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomCount = _collageBottomCount(products.length);
            final tileSize = _collageProductTileSize(
              itemCount: products.length,
              bottomCount: bottomCount,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            );
            final gap = tileSize <= 42 ? 4.0 : 6.0;
            final bottomProducts = products.take(bottomCount).toList();
            final sideProducts = products.skip(bottomCount).toList();
            final bottomGap = _collageEvenGap(
              extent: constraints.maxWidth,
              itemCount: bottomProducts.length,
              tileSize: tileSize,
              fallback: gap,
            );
            final sideAvailableHeight = constraints.maxHeight - tileSize - gap;
            final sideGap = _collageEvenGap(
              extent: sideAvailableHeight,
              itemCount: sideProducts.length,
              tileSize: tileSize,
              fallback: gap,
            );

            return Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: _buildMinePostImage(imageUrl),
                ),
                for (var index = 0; index < sideProducts.length; index++)
                  Positioned(
                    right: gap,
                    top: sideGap + index * (tileSize + sideGap),
                    width: tileSize,
                    height: tileSize,
                    child: _buildCollageProduct(sideProducts[index]),
                  ),
                for (var index = 0; index < bottomProducts.length; index++)
                  Positioned(
                    left: bottomGap + index * (tileSize + bottomGap),
                    bottom: gap,
                    width: tileSize,
                    height: tileSize,
                    child: _buildCollageProduct(bottomProducts[index]),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  int _collageBottomCount(int itemCount) {
    if (itemCount <= 3) return itemCount;
    if (itemCount == 4) return 3;
    return math.min(3, itemCount);
  }

  double _collageProductTileSize({
    required int itemCount,
    required int bottomCount,
    required double width,
    required double height,
  }) {
    final shortestSide = math.min(width, height);
    final maxTile = shortestSide < 360
        ? 72.0
        : shortestSide < 520
        ? 84.0
        : 104.0;
    const minTile = 44.0;
    const gap = 6.0;

    final sideCount = itemCount - bottomCount;
    final bottomFit = bottomCount == 0
        ? maxTile
        : (width - gap * (bottomCount + 1)) / bottomCount;
    final sideFit = sideCount == 0
        ? maxTile
        : (height - bottomFit - gap * (sideCount + 2)) / sideCount;
    final fit = math.min(maxTile, math.min(bottomFit, sideFit));
    return fit.clamp(minTile, maxTile).toDouble();
  }

  double _collageEvenGap({
    required double extent,
    required int itemCount,
    required double tileSize,
    required double fallback,
  }) {
    if (itemCount <= 0) return fallback;
    final available = extent - itemCount * tileSize;
    if (available <= fallback * (itemCount + 1)) return fallback;
    return available / (itemCount + 1);
  }

  Widget _buildMineCommand({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 34,
      child: Material(
        color: onTap == null
            ? backgroundColor.withValues(alpha: 0.45)
            : backgroundColor,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: foregroundColor),
              SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _responsiveCardFontSize(
    String text, {
    required double base,
    required double compact,
  }) {
    if (text.length > 110) return compact;
    if (text.length > 70) return (base + compact) / 2;
    return base;
  }

  Widget _buildMineReaction({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: color),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedMessage({required IconData icon, required String message}) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 44),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: colors.outline),
          SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// Helper to build consistent action buttons in the AppBar
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
              if (unreadCount == 0) return SizedBox.shrink();

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
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
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

  /// Horizontal tab selector for filtering content
  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tabButton("Mine", 0),
          SizedBox(width: 15),
          _tabButton("My Friends", 1),
          SizedBox(width: 15),
          _tabButton("Community", 2),
        ],
      ),
    );
  }

  /// Individual tab button with selection state
  Widget _tabButton(String title, int index) {
    bool isSelected = _selectedTabIndex == index;
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? primaryColor : colors.outlineVariant,
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Header showing current weather and next calendar event
  Widget _buildStatusHeader() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (_isLoadingWeather) {
      return Container(
        constraints: BoxConstraints(minHeight: 58),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Color(0xFFC5CAE9),
          borderRadius: BorderRadius.circular(15),
        ),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }

    String conditionText = _currentWeather?.condition ?? "Weather Unavailable";
    String tempText = _currentWeather != null
        ? "${_currentWeather!.temperatureC.round()}°C"
        : "";

    return StreamBuilder<UpcomingEvent?>(
      stream: _upcomingEventService.watchClosestEvent(currentUserId),
      builder: (context, eventSnapshot) {
        final eventLabel =
            eventSnapshot.data?.shortLabel ?? 'No upcoming event';

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Color(0xFFC5CAE9),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Wrap(
            spacing: 14,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _statusChip(
                icon: Icons.cloud_outlined,
                label: _currentWeather != null
                    ? "$conditionText • $tempText • ${_currentWeather!.locationName}"
                    : conditionText,
                flex: 2,
              ),
              _statusChip(
                icon: Icons.calendar_today_outlined,
                label: eventLabel,
                flex: 1,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusChip({
    required IconData icon,
    required String label,
    required int flex,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: flex == 2 ? 210 : 150,
        maxWidth: flex == 2 ? 420 : 260,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Friends and community posts use the same visual card as My Daily Dress Up.
  Widget _buildDressUpItem(Post post, int index) {
    return _buildMinePostItem(post, index);
  }

  List<Map<String, dynamic>> _collageProducts(Post post) {
    return post.products
        .where((product) => _productImageUrl(product).isNotEmpty)
        .toList();
  }

  Widget _buildCollageProduct(Map<String, dynamic> product) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SafeProductImage(
          imageUrl: _productImageUrl(product),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
          iconSize: 34,
        ),
      ),
    );
  }

  Future<_PostAuthor> _loadPostAuthor(String authorId) async {
    if (authorId.isEmpty) return _PostAuthor.fallback(authorId);

    try {
      final snapshot = await _firestore.collection('users').doc(authorId).get();
      final data = snapshot.data();
      if (data == null) return _PostAuthor.fallback(authorId);

      return _PostAuthor(
        displayName: (data['displayName'] ?? data['name'] ?? 'User').toString(),
        fullBodyImageUrl: (data['latestFullBodyImageUrl'] ?? '').toString(),
        stylePreference: (data['stylePreference'] ?? data['style'] ?? '')
            .toString(),
      );
    } catch (error) {
      debugPrint('Unable to load post author $authorId: $error');
      return _PostAuthor.fallback(authorId);
    }
  }

  String _formatPostTime(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);
    if (difference.isNegative || difference.inMinutes < 1) return 'Now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String _titleCase(String value) {
    final words = value
        .trim()
        .split(RegExp(r'[\s_-]+'))
        .where((word) => word.isNotEmpty);
    return words
        .map(
          (word) =>
              '${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

class _PostAuthor {
  final String displayName;
  final String fullBodyImageUrl;
  final String stylePreference;

  _PostAuthor({
    required this.displayName,
    required this.fullBodyImageUrl,
    required this.stylePreference,
  });

  factory _PostAuthor.fallback(String authorId) {
    final suffix = authorId.length >= 4
        ? authorId.substring(0, 4).toUpperCase()
        : authorId.toUpperCase();
    return _PostAuthor(
      displayName: suffix.isEmpty ? 'User' : 'User $suffix',
      fullBodyImageUrl: '',
      stylePreference: '',
    );
  }
}

class _TryOnSources {
  final List<Map<String, dynamic>> catalog;
  final List<Map<String, dynamic>> wardrobe;

  const _TryOnSources({this.catalog = const [], this.wardrobe = const []});
}
