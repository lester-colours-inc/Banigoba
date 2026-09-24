// Home: an X-style feed of looks — My Timeline, Friends and Community — with a
// floating Makeover button that starts a new look, like composing a tweet.
//
// Kept deliberately simple (September 2026 review): no weather or calendar
// banner here. Style by Occasion, Plan Ahead and Shopping Intelligence live on
// My Fashion Style.
//
// UNCLEAR: Shopping Intelligence should become an "order / get this look"
// action beside each post, but its placement and wording were left to be
// decided while building Home. Not added yet.
// UNCLEAR: this class is still called DailyDressUpPage although it is Home.
// Daily Dress Up is meant to be a separate feature whose role after the
// review is undecided; rename once that is settled.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../data/models/affirmation.dart';
import '../../../data/models/post.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/post_service.dart';
import '../../../data/services/friend_service.dart';
import '../../../data/services/product_service.dart';
import '../../../core/app_routes.dart';
import '../../../core/theme_provider.dart';
import '../../widgets/affirmation_row.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/dress_up_post_card.dart';
import '../../widgets/home_feed_tabs.dart';
import '../../widgets/post_comments_sheet.dart';
import '../../widgets/cart_badge_button.dart';
import '../../widgets/safe_product_image.dart';
import '../../widgets/try_on_product_picker.dart';

/// Home feed of the user's own looks, friends' looks and the community.
class DailyDressUpPage extends StatefulWidget {
  const DailyDressUpPage({super.key});

  @override
  State<DailyDressUpPage> createState() => _DailyDressUpPageState();
}

class _DailyDressUpPageState extends State<DailyDressUpPage> {
  HomeFeed _selectedFeed = HomeFeed.myTimeline;
  static Color primaryColor = Color(0xFF0D0140);

  final PostService _postService = PostService();
  final FriendService _friendService = FriendService();
  final ProductService _productService = ProductService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, Future<_PostAuthor>> _authorProfiles = {};

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
      // This is the Home tab. It keeps its own drawer because it is also
      // reachable as a standalone route, where there is no MainScreen drawer.
      drawer: AppDrawer(themeProvider: themeProvider),
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
                'Home',
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
        bottom: HomeFeedTabs(
          selected: _selectedFeed,
          onSelected: (feed) => setState(() => _selectedFeed = feed),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPostsFeed(),
            // Clears the floating Makeover button so it never covers the
            // last post's actions.
            SizedBox(height: 96),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('home_makeover_button'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: Icon(Icons.auto_awesome),
        label: Text('Makeover', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.pushNamed(context, AppRoutes.makeover),
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
        if (_selectedFeed == HomeFeed.friends) {
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
        final filteredPosts = _selectedFeed == HomeFeed.myTimeline
            ? posts.where((post) => post.authorId == currentUserId).toList()
            : posts.where((post) => post.isPublic).toList();

        return _buildPostList(
          filteredPosts,
          emptyMessage: _selectedFeed == HomeFeed.myTimeline
              ? 'Your looks will appear here. Tap Makeover to create your first one.'
              : 'No community posts yet.',
        );
      },
    );
  }

  Widget _buildPostList(List<Post> posts, {required String emptyMessage}) {
    if (posts.isEmpty) {
      return _buildFeedMessage(
        icon: Icons.checkroom_outlined,
        message: emptyMessage,
      );
    }

    return Column(
      children: [
        for (var index = 0; index < posts.length; index++) ...[
          _buildPostItem(posts[index], index),
          if (index != posts.length - 1) SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildPostItem(Post post, int index) {
    final cardColors = [
      Color(0xFFE3A6E6),
      Color(0xFF7F7FC0),
      Color(0xFFF3D98B),
      Color(0xFFA9DDC4),
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
        final isMineTab = _selectedFeed == HomeFeed.myTimeline;
        final imageUrl = post.imageURL.isNotEmpty
            ? post.imageURL
            : author.fullBodyImageUrl;
        final caption = post.caption.trim().isEmpty
            ? 'Daily Outfit'
            : post.caption.trim();
        final styleLabel = author.stylePreference.isEmpty
            ? 'Styled for your day'
            : '${_titleCase(author.stylePreference)} style';
        final canComment = post.isPublic;
        final canQuickReply = post.isPublic && !isOwner && !isMineTab;

        return DressUpPostCard(
          key: ValueKey('dress_up_post_${post.id}'),
          isMineLayout: isMineTab,
          title: author.displayName,
          subtitle: isMineTab ? caption : '',
          detail: isMineTab ? styleLabel : '',
          captionLead: isOwner ? 'Your look' : "${author.displayName}'s",
          caption: isMineTab ? '' : caption,
          avatarUrl: author.profileImageUrl.isNotEmpty
              ? author.profileImageUrl
              : author.fullBodyImageUrl,
          timeLabel: _formatPostTime(post.createdAt),
          imageBackground: cardColors[index % cardColors.length],
          visual: _buildPostImage(imageUrl),
          actions: [
            DressUpCardAction(
              icon: Icons.shortcut_outlined,
              label: 'Try On',
              onTap: () => _tryOnPost(post),
            ),
            if (canComment)
              DressUpCardAction(
                icon: Icons.chat_bubble_outline,
                label: post.commentCount > 0
                    ? '${post.commentCount}'
                    : 'Comment',
                onTap: () => showPostCommentsSheet(context, post),
              ),
            if (isOwner && !post.isPublic)
              DressUpCardAction(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: () => _sharePost(post),
              ),
          ],
          menuItems: [
            if (!isOwner && canComment)
              DressUpMenuItem(
                icon: Icons.chat_bubble_outline,
                label: 'Comment',
                onSelected: () => showPostCommentsSheet(context, post),
              ),
            if (isOwner && post.isPublic)
              DressUpMenuItem(
                icon: Icons.lock_outline,
                label: 'Make private',
                onSelected: () => _privatePost(post),
              ),
            if (isOwner && !post.isPublic)
              DressUpMenuItem(
                icon: Icons.public,
                label: 'Share publicly',
                onSelected: () => _sharePost(post),
              ),
            if (isOwner)
              DressUpMenuItem(
                icon: Icons.delete_outline,
                label: 'Delete',
                isDestructive: true,
                onSelected: () => _deletePost(post),
              ),
          ],
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Affirmations stand in for the design's like counter: public
              // reaction totals are prohibited (BNG SRS 001, AFF-003).
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
              if (canQuickReply) ...[
                SizedBox(height: 6),
                PostQuickReplies(post: post),
              ],
            ],
          ),
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
          'Friends and community members will be able to see this look, send affirmations and reply.',
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
          'This look will be removed from friends and community feeds. Affirmations and replies stay saved if you share it again later.',
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
        title: const Text('Delete this look?'),
        content: const Text(
          'This removes the look from your timeline and deletes its affirmations and replies. This cannot be undone.',
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
      ).showSnackBar(const SnackBar(content: Text('Look deleted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to delete look: $error')));
    }
  }

  /// The generated try-on image, filling the card.
  Widget _buildPostImage(String imageUrl) {
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
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      webHtmlElementStrategy: kIsWeb
          ? WebHtmlElementStrategy.prefer
          : WebHtmlElementStrategy.never,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Unable to display post image: $error');
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

  /// Friends and community posts use the same visual card as My Daily Dress Up.
  Future<_PostAuthor> _loadPostAuthor(String authorId) async {
    if (authorId.isEmpty) return _PostAuthor.fallback(authorId);

    try {
      final snapshot = await _firestore.collection('users').doc(authorId).get();
      final data = snapshot.data();
      if (data == null) return _PostAuthor.fallback(authorId);

      return _PostAuthor(
        displayName: (data['displayName'] ?? data['name'] ?? 'User').toString(),
        fullBodyImageUrl: (data['latestFullBodyImageUrl'] ?? '').toString(),
        profileImageUrl:
            (data['profileImageURL'] ?? data['profileImageUrl'] ?? '')
                .toString(),
        stylePreference: (data['stylePreference'] ?? data['style'] ?? '')
            .toString(),
      );
    } catch (error) {
      debugPrint('Unable to load post author $authorId: $error');
      return _PostAuthor.fallback(authorId);
    }
  }

  String _formatPostTime(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    if (difference.isNegative) return 'Today';

    final today = DateTime(now.year, now.month, now.day);
    final postDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final dayGap = today.difference(postDay).inDays;
    if (dayGap == 0) return 'Today';
    if (dayGap == 1) return 'Yesterday';
    if (dayGap < 7) return '$dayGap Days Ago';
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
  final String profileImageUrl;
  final String stylePreference;

  _PostAuthor({
    required this.displayName,
    required this.fullBodyImageUrl,
    required this.stylePreference,
    this.profileImageUrl = '',
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
