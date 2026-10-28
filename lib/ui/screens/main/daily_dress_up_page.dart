// Home: an X-style feed of looks — My Fashion Makeover, My Daily Dress Up and
// Community — with a floating Makeover button that starts a new look, like
// composing a tweet.
//
// Under each look sits one evenly spaced row: affirm (affirming and
// commenting are one action), repost, quote, save to Smart Wardrobe, more,
// forward.
//
// Kept deliberately simple (September 2026 review): no weather or calendar
// banner here. Style by Occasion, Plan Ahead and Shopping Intelligence live on
// My Fashion Style.
//
// UNCLEAR: Shopping Intelligence should become an "order / get this look"
// action beside each post. For now each post's menu has "Find pieces"; its
// final placement and wording are still to be agreed.
// UNCLEAR: this class is still called DailyDressUpPage although it is Home.
// Daily Dress Up is meant to be a separate feature whose role after the
// review is undecided; rename once that is settled.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../data/models/affirmation.dart';
import '../../../data/models/feed_ranking.dart';
import '../../../data/models/geo_cell.dart';
import '../../../data/models/post.dart';
import '../../../data/services/area_service.dart';
import '../../../data/services/author_cities.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/outfit_service.dart';
import '../../../data/services/post_service.dart';
import '../../../data/services/visible_posts.dart';
import '../../../data/services/friend_service.dart';
import '../../../data/services/product_service.dart';
import '../../../core/app_routes.dart';
import '../../../core/theme_provider.dart';
import '../../widgets/affirmation_composer_sheet.dart';
import '../../widgets/affirmation_row.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/dress_up_post_card.dart';
import '../../widgets/find_pieces_sheet.dart';
import '../../widgets/forward_look_sheet.dart';
import '../../widgets/look_viewer_page.dart';
import '../../widgets/home_feed_tabs.dart';
import '../../widgets/consent_sheet.dart';
import '../../widgets/makeover_fab.dart';
import '../../widgets/near_me_bar.dart';
import '../../widgets/saved_to_wardrobe_sheet.dart';
import '../wardrobe/wardrobe_page.dart';
import '../events/community_events_strip.dart';
import '../../widgets/fashion_news_section.dart';
import '../../widgets/cart_badge_button.dart';
import '../../widgets/safe_product_image.dart';
import '../../widgets/repost_actions.dart';
import '../../widgets/share_audience_sheet.dart';
import '../../widgets/try_on_product_picker.dart';
import '../makeover/makeover_page.dart';
import '../makeover/makeover_start_sheet.dart';
import 'widgets/daily_dress_up_feed.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/menu_or_back_button.dart';

/// Home feed of the user's own looks, friends' looks and the community.
class DailyDressUpPage extends StatefulWidget {
  const DailyDressUpPage({super.key});

  static final ValueNotifier<HomeFeed?> _feedRequests = ValueNotifier(null);

  /// Switches Home to [feed] from anywhere, e.g. "My Fashion Community" in
  /// the drawer.
  static void showFeed(HomeFeed feed) {
    _feedRequests.value = null;
    _feedRequests.value = feed;
  }

  @override
  State<DailyDressUpPage> createState() => _DailyDressUpPageState();
}

class _DailyDressUpPageState extends State<DailyDressUpPage>
    with SingleTickerProviderStateMixin {
  // The shown feed, shared by the tabs and the swipeable feed pages.
  late final TabController _feeds;
  static Color primaryColor = Color(0xFF0D0140);

  // The Makeover button folds to its sparkle while a feed scrolls down.
  bool _fabExtended = true;

  @override
  void initState() {
    super.initState();
    _feeds = TabController(
      length: HomeFeed.values.length,
      vsync: this,
      initialIndex: (_takeFeedRequest() ?? HomeFeed.myMakeover).index,
    )..addListener(_unfoldFab);
    DailyDressUpPage._feedRequests.addListener(_handleFeedRequest);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _visiblePostsSub =
          watchVisiblePosts(
            viewerId: userId,
            following: _friendService.getFollowingIds(),
            friends: _friendService.getMutualFriendsIds(),
          ).listen(
            (posts) {
              if (mounted) setState(() => _visiblePosts = posts);
              _authorCities.ensure(posts.map((post) => post.authorId)).then((
                learned,
              ) {
                if (learned && mounted) setState(() {});
              });
            },
            onError: (Object error) {
              if (mounted) setState(() => _postsError = error);
            },
          );
      _followingSub = _friendService.getFollowingIds().listen(
        (ids) {
          if (mounted) setState(() => _following = ids.toSet());
        },
        onError: (Object error) =>
            debugPrint('Unable to load who you follow: $error'),
      );
      _loadViewerCity(userId);
      _area.refreshIfDue(userId).then((_) => _loadViewerArea(userId));
      _savedPostsSub = _outfitService.watchSavedPostIds(userId).listen(
        (ids) {
          if (mounted) setState(() => _savedPostIds = ids);
        },
        onError: (Object error) =>
            debugPrint('Unable to load saved looks: $error'),
      );
    }
  }

  @override
  void dispose() {
    unawaited(_followingSub?.cancel());
    unawaited(_savedPostsSub?.cancel());
    unawaited(_visiblePostsSub?.cancel());
    DailyDressUpPage._feedRequests.removeListener(_handleFeedRequest);
    _feeds.dispose();
    super.dispose();
  }

  /// Returns a pending request and clears it, so it is applied only once.
  HomeFeed? _takeFeedRequest() {
    final feed = DailyDressUpPage._feedRequests.value;
    DailyDressUpPage._feedRequests.value = null;
    return feed;
  }

  /// Folds the Makeover button while a feed scrolls down, so it covers less
  /// of the looks, and unfolds it on the way back up or at the top.
  bool _foldFabOnScroll(UserScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final extended = makeoverFabExtendedAfter(
      notification.direction,
      wasExtended: _fabExtended,
      offset: notification.metrics.pixels,
    );
    if (extended != _fabExtended) setState(() => _fabExtended = extended);
    return false;
  }

  /// A newly picked feed shows the full button again.
  void _unfoldFab() {
    if (_fabExtended || !mounted) return;
    setState(() => _fabExtended = true);
  }

  void _handleFeedRequest() {
    if (!mounted) return;
    if (_takeFeedRequest() case final feed?) {
      _feeds.animateTo(feed.index);
    }
  }

  final PostService _postService = PostService();
  final OutfitService _outfitService = OutfitService();
  final FriendService _friendService = FriendService();
  final ProductService _productService = ProductService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, Future<_PostAuthor>> _authorProfiles = {};

  // Every post this user may see, for the My Fashion Makeover and Community
  // feeds (one set of listeners shared by both tabs).
  StreamSubscription<List<Post>>? _visiblePostsSub;
  List<Post>? _visiblePosts;
  Object? _postsError;

  // Who I follow and the city each author chose, for ranking the feeds and
  // for "Near me" on Community.
  final AuthorCities _authorCities = AuthorCities();
  StreamSubscription<List<String>>? _followingSub;
  Set<String> _following = const {};
  final AreaService _area = AreaService();
  String _viewerCity = '';
  GeoCell? _viewerCell;
  bool _nearMe = true;

  /// Near me needs somewhere to be near: a location or a city. Until then
  /// the Community feed shows everyone instead of an empty list.
  bool get _hasPlace => _viewerCell != null || _viewerCity.trim().isNotEmpty;

  // Posts saved to the Smart Wardrobe, so the save icon can show as on.
  StreamSubscription<Set<String>>? _savedPostsSub;
  Set<String> _savedPostIds = const {};

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

      // Looks made with the photo-first makeover have no products: copy the
      // look itself onto the user as their style twin instead.
      if (products.isEmpty && post.imageURL.isNotEmpty) {
        await _postService.notifyPostTryOn(post);
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => MakeoverPage(initialTwinUrl: post.imageURL),
          ),
        );
        return;
      }

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
        leading: MenuOrBackButton(color: colors.onSurface),
        title: Row(
          children: [
            // The app name, written like the logo wordmark; the bottom bar
            // already says this is Home.
            Expanded(
              child: Text(
                'Banigoba',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: colors.primary,
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('home_find_people'),
              tooltip: 'Find people',
              icon: Icon(Icons.person_search_outlined, color: colors.onSurface),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.search),
            ),
            _buildAppBarAction(
              Icons.shopping_bag_outlined,
              () => Navigator.pushNamed(context, AppRoutes.cart),
            ),
          ],
        ),
        actions: [SizedBox(width: 20)],
        bottom: HomeFeedTabs(controller: _feeds),
      ),
      body: NotificationListener<UserScrollNotification>(
        onNotification: _foldFabOnScroll,
        child: TabBarView(
          controller: _feeds,
          children: [
            for (final feed in HomeFeed.values)
              _KeepAlive(
                child: SingleChildScrollView(
                  key: PageStorageKey(feed),
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (feed == HomeFeed.community) ...[
                        const CommunityEventsStrip(),
                        const FashionNewsSection(),
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 12),
                          child: NearMeBar(
                            city: _viewerCity,
                            nearMe: _nearMe && _hasPlace,
                            onChanged: (value) =>
                                setState(() => _nearMe = value),
                            onSetCity: _addCity,
                            hasLocation: _viewerCell != null,
                            onUseLocation: _useLocation,
                          ),
                        ),
                      ],
                      _buildPostsFeed(feed),
                      // Clears the floating Makeover button so it never covers
                      // the last post's actions.
                      SizedBox(height: 96),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: MakeoverFab(
        color: primaryColor,
        isExtended: _fabExtended,
        onPressed: () => startMakeover(context),
      ),
    );
  }

  Future<void> _loadViewerCity(String userId) async {
    final city = await _authorCities.cityOf(userId);
    if (mounted) setState(() => _viewerCity = city);
  }

  Future<void> _loadViewerArea(String userId) async {
    final record = await _area.load(userId);
    final cell = record != null && record.enabled ? record.cell : null;
    if (mounted) setState(() => _viewerCell = cell);
  }

  /// "Use my location": explain, ask the phone, and say what happened.
  Future<void> _useLocation() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final agreed = await showConsentSheet(
      context,
      title: 'Use my location for Near me',
      points: kLocationConsentText,
    );
    if (!agreed) return;
    final result = await _area.enable(userId);
    await _loadViewerArea(userId);
    final message = switch (result) {
      AreaResult.enabled => null,
      AreaResult.serviceOff => 'Location is switched off on your phone.',
      AreaResult.denied => 'Banigoba was not allowed to use your location.',
      AreaResult.deniedForever =>
        'Location is blocked for Banigoba. Allow it in your phone settings.',
      AreaResult.failed => 'We could not find your location. Try again.',
    };
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// Opens Settings to add a city, then picks up the answer.
  Future<void> _addCity() async {
    await Navigator.pushNamed(context, AppRoutes.settings);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null && mounted) await _loadViewerCity(userId);
  }

  Widget _buildPostsFeed(HomeFeed feed) {
    if (feed == HomeFeed.dailyDressUp) {
      return DailyDressUpFeed(
        emptyBuilder: (icon, message) =>
            _buildFeedMessage(icon: icon, message: message),
      );
    }
    final error = _postsError;
    if (error != null) {
      debugPrint('Unable to load posts: $error');
      return _buildFeedMessage(
        icon: Icons.cloud_off_outlined,
        message: 'Posts could not be loaded.',
      );
    }
    final visiblePosts = _visiblePosts;
    if (visiblePosts == null) {
      return Center(child: CircularProgressIndicator());
    }
    // Only posts this user may see arrive here (the rules enforce it).
    // Daily dress-ups live in My Daily Dress Up, not the makeover feeds.
    // My Fashion Makeover shows yours and everyone else's (H-5); Community
    // shows only other people's.
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isMyMakeover = feed == HomeFeed.myMakeover;
    final candidates = visiblePosts.where(
      (post) =>
          !post.isDressUp && (isMyMakeover || post.authorId != currentUserId),
    );
    // People I follow first, then people in my city, then everyone (A-5).
    final ranked = rankPosts(
      candidates,
      viewerId: currentUserId,
      following: _following,
      cityOf: _authorCities.known,
      viewerCity: _viewerCity,
      viewerCell: _viewerCell,
      cellOf: _authorCities.knownCells,
      now: DateTime.now(),
    );
    final nearOnly = !isMyMakeover && _nearMe && _hasPlace;
    final posts = nearOnly
        ? nearMe(
            ranked,
            viewerId: currentUserId,
            following: _following,
            cityOf: _authorCities.known,
            viewerCity: _viewerCity,
            viewerCell: _viewerCell,
            cellOf: _authorCities.knownCells,
          )
        : ranked;
    return _buildPostList(
      posts,
      feed: feed,
      emptyMessage: isMyMakeover
          ? 'Your looks and your friends\' looks will appear here. '
                'Tap "$kMakeoverFabLabel" to make your first one.'
          : nearOnly
          ? 'No looks near you yet. Switch to Everyone, or follow people '
                'to see theirs here.'
          : 'No community looks yet. Follow people to see theirs here.',
    );
  }

  Widget _buildPostList(
    List<Post> posts, {
    required HomeFeed feed,
    required String emptyMessage,
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
          _buildPostItem(posts[index], index, feed),
          if (index != posts.length - 1) SizedBox(height: 18),
        ],
      ],
    );
  }

  Widget _buildPostItem(Post post, int index, HomeFeed feed) {
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
        final isMineTab = feed == HomeFeed.myMakeover;
        final imageUrl = post.imageURL.isNotEmpty
            ? post.imageURL
            : author.fullBodyImageUrl;
        final caption = post.caption.trim().isEmpty
            ? 'Daily Outfit'
            : post.caption.trim();
        final styleLabel = author.stylePreference.isEmpty
            ? 'Styled for your day'
            : '${_titleCase(author.stylePreference)} style';
        final repostedFrom = post.isRepost
            ? _authorProfiles.putIfAbsent(
                post.repostOfAuthorId,
                () => _loadPostAuthor(post.repostOfAuthorId),
              )
            : null;

        if (repostedFrom == null) {
          return _buildPostCard(
            post,
            index: index,
            author: author,
            isOwner: isOwner,
            isMineTab: isMineTab,
            imageUrl: imageUrl,
            caption: caption,
            styleLabel: styleLabel,
            currentUserId: currentUserId,
          );
        }
        return FutureBuilder<_PostAuthor>(
          future: repostedFrom,
          builder: (context, sourceSnapshot) {
            final source =
                sourceSnapshot.data ??
                _PostAuthor.fallback(post.repostOfAuthorId);
            final sourceName = post.repostOfAuthorId == currentUserId
                ? 'you'
                : source.displayName;
            return _buildPostCard(
              post,
              index: index,
              author: author,
              isOwner: isOwner,
              isMineTab: isMineTab,
              imageUrl: imageUrl,
              caption: caption,
              styleLabel: styleLabel,
              currentUserId: currentUserId,
              repostLabel: post.isQuote
                  ? 'Quoting $sourceName'
                  : 'Reposted from $sourceName',
            );
          },
        );
      },
    );
  }

  Widget _buildPostCard(
    Post post, {
    required int index,
    required _PostAuthor author,
    required bool isOwner,
    required bool isMineTab,
    required String imageUrl,
    required String caption,
    required String styleLabel,
    required String currentUserId,
    String repostLabel = '',
  }) {
    return DressUpPostCard(
      key: ValueKey('dress_up_post_${post.id}'),
      isMineLayout: isMineTab,
      title: author.displayName,
      subtitle: isMineTab && !post.isQuote ? caption : '',
      detail: isMineTab ? styleLabel : '',
      captionLead: isOwner ? 'Your look' : "${author.displayName}'s",
      caption: isMineTab || post.isQuote ? '' : caption,
      quote: post.quoteText,
      repostLabel: repostLabel,
      avatarUrl: author.profileImageUrl.isNotEmpty
          ? author.profileImageUrl
          : author.fullBodyImageUrl,
      timeLabel: _formatPostTime(post.createdAt),
      imageBackground: kLookBackdrops[index % kLookBackdrops.length],
      visual: _buildPostImage(imageUrl),
      onImageTap: imageUrl.isEmpty
          ? null
          : () => openLookViewer(
              context,
              imageUrl: imageUrl,
              title: author.displayName,
              caption: caption,
            ),
      // One row: the Affirm pill (and comment) · repost · quote · save to
      // Smart Wardrobe, then send to at the far end; the rest is in the ⋯
      // menu. Reposting a private look asks to share it first.
      actions: [
        DressUpCardAction(
          glyph: 'a',
          chipLabel: isOwner ? 'Affirmations' : 'Affirm',
          label: isOwner
              ? 'Affirmations & comments received'
              : 'Affirm & comment',
          onTap: () => _openAffirmations(
            post,
            isOwner: isOwner,
            ownerName: author.displayName,
          ),
        ),
        // Always offered; a private look is shared first (P-8).
        DressUpCardAction(
          icon: Icons.repeat,
          label: 'Repost',
          onTap: () => _passOn(post, repostLook),
        ),
        DressUpCardAction(
          icon: Icons.format_quote_outlined,
          label: 'Quote',
          onTap: () => _passOn(post, quoteLook),
        ),
        DressUpCardAction(
          icon: Icons.checkroom_outlined,
          activeIcon: Icons.checkroom,
          isActive: _savedPostIds.contains(post.id),
          label: _savedPostIds.contains(post.id)
              ? 'Saved to Smart Wardrobe. Tap to remove'
              : 'Save to Smart Wardrobe',
          onTap: () => _savedPostIds.contains(post.id)
              ? _removeFromWardrobe(post)
              : _saveToWardrobe(post, imageUrl, caption),
        ),
      ],
      menuItems: [
        if (isOwner && !post.isRepost)
          DressUpMenuItem(
            icon: Icons.edit_outlined,
            label: 'Edit my look',
            onSelected: () => _editPost(post, imageUrl),
          ),
        DressUpMenuItem(
          icon: Icons.shopping_bag_outlined,
          label: 'Place Order',
          onSelected: () => showFindPiecesSheet(context),
        ),
        // Post decides who sees the look in the feeds; Send to (the share
        // icon) passes it to someone specific (P-4).
        if (isOwner && !post.isRepost)
          DressUpMenuItem(
            icon: Icons.send_outlined,
            label: post.isShared ? 'Post: change who sees it' : 'Post',
            onSelected: () => _sharePost(post),
          ),
        DressUpMenuItem(
          icon: Icons.accessibility_new,
          label: 'Try On',
          onSelected: () => _tryOnPost(post),
        ),
        if (isOwner && post.isShared)
          DressUpMenuItem(
            icon: Icons.lock_outline,
            label: 'Make private',
            onSelected: () => _privatePost(post),
          ),
        if (isOwner)
          DressUpMenuItem(
            icon: Icons.delete_outline,
            label: 'Delete',
            isDestructive: true,
            onSelected: () => _deletePost(post),
          ),
      ],
      trailingAction: DressUpCardAction(
        icon: Icons.share_outlined,
        label: kSendToLabel,
        onTap: () => showForwardLookSheet(
          context,
          imageUrl: imageUrl,
          caption: post.caption,
        ),
      ),
      // Which affirmations the look received; never how many (BNG SRS 001,
      // AFF-003). The affirm action is in the row above, so not repeated.
      footer: AffirmationRow(
        targetType: AffirmationTargetType.post,
        targetId: post.id,
        targetOwnerId: post.authorId,
        currentUserId: currentUserId,
        ownerName: isOwner ? 'your look' : author.displayName,
        showAction: false,
      ),
    );
  }

  Future<void> _openAffirmations(
    Post post, {
    required bool isOwner,
    required String ownerName,
  }) async {
    if (isOwner) {
      await showReceivedAffirmations(
        context,
        targetType: AffirmationTargetType.post,
        targetId: post.id,
      );
      return;
    }
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sign in to affirm looks.')));
      return;
    }
    final sent = await showAffirmationComposer(
      context,
      targetType: AffirmationTargetType.post,
      targetId: post.id,
      targetOwnerId: post.authorId,
      recipientName: ownerName,
    );
    if (!sent || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Affirmation sent.')));
  }

  /// Shows where the look went and files it under the chosen category.
  Future<void> _fileSavedLook(String userId, String postId) async {
    var categories = const <String>[];
    try {
      categories = await _outfitService.savedLookCategories(userId);
    } on FirebaseException catch (error) {
      // Still show the sheet, with the starter categories.
      debugPrint('Unable to load look categories: ${error.message}');
    }
    if (!mounted) return;
    final category = await showSavedToWardrobeSheet(
      context,
      existingCategories: categories,
      onOpenWardrobe: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              const WardrobePage(initialTab: WardrobeTab.savedLooks),
        ),
      ),
    );
    if (category == null || category.isEmpty) return;
    try {
      await _outfitService.setSavedLookCategory(
        userId: userId,
        postId: postId,
        category: category,
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to add to $category: ${error.message}')),
      );
    }
  }

  Future<void> _removeFromWardrobe(Post post) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final previous = _savedPostIds;
    setState(
      () => _savedPostIds = previous.where((id) => id != post.id).toSet(),
    );
    try {
      await _outfitService.removeLookFromWardrobe(
        userId: userId,
        postId: post.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from your Smart Wardrobe.')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() => _savedPostIds = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to remove look: ${error.message}')),
      );
    }
  }

  Future<void> _saveToWardrobe(
    Post post,
    String imageUrl,
    String caption,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sign in to save looks.')));
      return;
    }
    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This look has no picture to save.')),
      );
      return;
    }
    try {
      await _outfitService.saveLookToWardrobe(
        userId: userId,
        postId: post.id,
        imageUrl: imageUrl,
        name: caption,
        products: post.products,
      );
      if (!mounted) return;
      setState(() => _savedPostIds = {..._savedPostIds, post.id});
      await _fileSavedLook(userId, post.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save look: $error')));
    }
  }

  /// Opens the Makeover on a saved look so it can be changed and saved back.
  Future<void> _editPost(Post post, String imageUrl) async {
    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This look has no picture to edit.')),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            MakeoverPage(initialPhotoUrl: imageUrl, editingPostId: post.id),
      ),
    );
  }

  /// Reposts or quotes [post], sharing it first when it is private.
  Future<void> _passOn(
    Post post,
    Future<void> Function(BuildContext, Post, {PostService? posts}) action,
  ) async {
    final shared = await ensureLookShared(
      context,
      post,
      share: (audience) => _shareToAudience(post, audience),
    );
    if (!shared || !mounted) return;
    await action(context, post, posts: _postService);
  }

  Future<void> _sharePost(Post post) async {
    final audience = await showShareAudienceSheet(context);
    if (audience == null || !mounted) return;
    await _shareToAudience(post, audience);
  }

  Future<void> _shareToAudience(Post post, PostVisibility audience) async {
    try {
      await _postService.sharePost(post.id, audience);
      // Only a public share goes out to everyone who follows the author;
      // narrower shares stay quiet and simply appear in Community.
      if (audience == PostVisibility.public) {
        await NotificationService().notifyFollowersNewPost(
          post.caption.isEmpty ? 'Daily Outfit' : post.caption,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (audience) {
            PostVisibility.friends => 'Post shared with friends.',
            PostVisibility.followers => 'Post shared with your followers.',
            PostVisibility.public => 'Post is now public.',
            PostVisibility.private => 'Post is now private.',
          }),
        ),
      );
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

    // The whole look, standing on the bottom of the card's studio frame.
    return AppNetworkImage(
      imageUrl,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      fallback: Align(
        alignment: Alignment.center,
        child: Icon(
          Icons.broken_image_outlined,
          size: 54,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
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

/// Keeps a feed's scroll position and loaded posts while another feed is
/// swiped into view.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
