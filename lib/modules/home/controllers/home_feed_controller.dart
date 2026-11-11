// ignore_for_file: use_build_context_synchronously
// (the context is Get.context, re-read after each await and guarded by isClosed)
// Home: the three feeds (My Fashion Makeover, My Daily Dress Up, Community),
// who the viewer follows and where they are, which looks they saved, and
// everything a look's menu can do (save, share, repost, try on, delete).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'package:banigoba/app/routes/app_routes.dart';
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/home/models/feed_ranking.dart' as ranking;
import 'package:banigoba/modules/home/models/geo_cell.dart';
import 'package:banigoba/modules/home/models/post_author.dart';
import 'package:banigoba/modules/home/models/try_on_group.dart';
import 'package:banigoba/modules/home/services/area_service.dart';
import 'package:banigoba/modules/home/services/author_cities.dart';
import 'package:banigoba/modules/home/widgets/home_feed_tabs.dart';
import 'package:banigoba/modules/makeover/views/makeover_page.dart';
import 'package:banigoba/modules/makeover/widgets/makeover_fab.dart';
import 'package:banigoba/modules/makeover/widgets/try_on_product_picker.dart';
import 'package:banigoba/modules/notifications/services/notification_service.dart';
import 'package:banigoba/modules/settings/services/safety_service.dart';
import 'package:banigoba/modules/social/models/affirmation.dart';
import 'package:banigoba/modules/social/models/post.dart';
import 'package:banigoba/modules/social/services/friend_service.dart';
import 'package:banigoba/modules/social/services/like_service.dart';
import 'package:banigoba/modules/social/services/post_service.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/modules/social/services/visible_posts.dart';
import 'package:banigoba/modules/social/widgets/affirmation_composer_sheet.dart';
import 'package:banigoba/modules/social/widgets/affirmation_row.dart';
import 'package:banigoba/modules/social/widgets/repost_actions.dart';
import 'package:banigoba/modules/social/widgets/share_audience_sheet.dart';
import 'package:banigoba/modules/wardrobe/services/outfit_service.dart';
import 'package:banigoba/modules/wardrobe/views/wardrobe_page.dart';
import 'package:banigoba/modules/wardrobe/widgets/saved_to_wardrobe_sheet.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';
import 'package:banigoba/shared/widgets/consent_sheet.dart';

class HomeFeedController extends GetxController
    with GetSingleTickerProviderStateMixin {
  HomeFeedController({
    PostService? postService,
    OutfitService? outfitService,
    FriendService? friendService,
    ProfileService? profiles,
    AreaService? area,
  }) : _postService = postService ?? PostService(),
       _outfitService = outfitService ?? OutfitService(),
       _friendService = friendService ?? FriendService(),
       _profiles = profiles ?? ProfileService(),
       _area = area ?? AreaService();

  static final ValueNotifier<HomeFeed?> _feedRequests = ValueNotifier(null);

  /// Switches Home to [feed] from anywhere, e.g. "My Fashion Community" in
  /// the drawer.
  static void showFeed(HomeFeed feed) {
    _feedRequests.value = null;
    _feedRequests.value = feed;
  }

  final PostService _postService;
  final OutfitService _outfitService;
  final FriendService _friendService;
  final ProfileService _profiles;
  final AreaService _area;
  final AuthorCities _authorCities = AuthorCities();
  final Map<String, Future<PostAuthor>> _authorProfiles = {};

  /// The shown feed, shared by the tabs and the swipeable feed pages.
  late final TabController feeds;

  /// The Makeover button folds to its sparkle while a feed scrolls down.
  final RxBool fabExtended = true.obs;

  // Every post this user may see, for the My Fashion Makeover and Community
  // feeds (one set of listeners shared by both tabs).
  final Rxn<List<Post>> visiblePosts = Rxn<List<Post>>();
  final Rxn<Object> postsError = Rxn<Object>();

  // Who I follow and the city each author chose, for ranking the feeds and
  // for "Near me" on Community.
  final Rx<Set<String>> following = Rx<Set<String>>(const {});
  final RxString viewerCity = ''.obs;
  final Rxn<GeoCell> viewerCell = Rxn<GeoCell>();
  final RxBool nearMe = true.obs;

  // Posts saved to the Smart Wardrobe, so the save icon can show as on.
  final Rx<Set<String>> savedPostIds = Rx<Set<String>>(const {});

  // Bumped when the blocked list or the learned author cities change, so the
  // feeds re-rank.
  final RxInt _rankingTick = 0.obs;

  StreamSubscription<List<Post>>? _visiblePostsSub;
  StreamSubscription<List<String>>? _followingSub;
  StreamSubscription<Set<String>>? _savedPostsSub;

  /// Near me needs somewhere to be near: a location or a city. Until then
  /// the Community feed shows everyone instead of an empty list.
  bool get hasPlace =>
      viewerCell.value != null || viewerCity.value.trim().isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    feeds = TabController(
      length: HomeFeed.values.length,
      vsync: this,
      initialIndex: (_takeFeedRequest() ?? HomeFeed.myMakeover).index,
    )..addListener(_unfoldFab);
    _feedRequests.addListener(_handleFeedRequest);
    SafetyService.instance.blockedIds.addListener(_onBlockedChanged);
    final userId = AppAuth.instance.currentUser?.uid;
    if (userId != null) _start(userId);
  }

  void _start(String userId) {
    _visiblePostsSub =
        watchVisiblePosts(
          viewerId: userId,
          following: _friendService.getFollowingIds(),
          friends: _friendService.getMutualFriendsIds(),
        ).listen(
          (posts) {
            if (isClosed) return;
            visiblePosts.value = posts;
            _authorCities.ensure(posts.map((post) => post.authorId)).then((
              learned,
            ) {
              if (learned && !isClosed) _rankingTick.value++;
            });
          },
          onError: (Object error) {
            if (!isClosed) postsError.value = error;
          },
        );
    _followingSub = _friendService.getFollowingIds().listen(
      (ids) {
        if (!isClosed) following.value = ids.toSet();
      },
      onError: (Object error) =>
          debugPrint('Unable to load who you follow: $error'),
    );
    _loadViewerCity(userId);
    _area.refreshIfDue(userId).then((_) => _loadViewerArea(userId));
    LikeService.instance.loadLiked().catchError(
      (Object error) => debugPrint('Unable to load liked looks: $error'),
    );
    _savedPostsSub = _outfitService.watchSavedPostIds(userId).listen(
      (ids) {
        if (!isClosed) savedPostIds.value = ids;
      },
      onError: (Object error) =>
          debugPrint('Unable to load saved looks: $error'),
    );
  }

  @override
  void onClose() {
    SafetyService.instance.blockedIds.removeListener(_onBlockedChanged);
    unawaited(_followingSub?.cancel());
    unawaited(_savedPostsSub?.cancel());
    unawaited(_visiblePostsSub?.cancel());
    _feedRequests.removeListener(_handleFeedRequest);
    feeds.dispose();
    super.onClose();
  }

  void _onBlockedChanged() {
    if (!isClosed) _rankingTick.value++;
  }

  /// Returns a pending request and clears it, so it is applied only once.
  HomeFeed? _takeFeedRequest() {
    final feed = _feedRequests.value;
    _feedRequests.value = null;
    return feed;
  }

  void _handleFeedRequest() {
    if (isClosed) return;
    if (_takeFeedRequest() case final feed?) {
      feeds.animateTo(feed.index);
    }
  }

  /// Folds the Makeover button while a feed scrolls down, so it covers less
  /// of the looks, and unfolds it on the way back up or at the top.
  bool foldFabOnScroll(UserScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    fabExtended.value = makeoverFabExtendedAfter(
      notification.direction,
      wasExtended: fabExtended.value,
      offset: notification.metrics.pixels,
    );
    return false;
  }

  /// A newly picked feed shows the full button again.
  void _unfoldFab() => fabExtended.value = true;

  // ── where the viewer is ────────────────────────────────────────────────

  Future<void> _loadViewerCity(String userId) async {
    final city = await _authorCities.cityOf(userId);
    if (!isClosed) viewerCity.value = city;
  }

  Future<void> _loadViewerArea(String userId) async {
    final record = await _area.load(userId);
    final cell = record != null && record.enabled ? record.cell : null;
    if (!isClosed) viewerCell.value = cell;
  }

  /// "Use my location": explain, ask the phone, and say what happened.
  Future<void> useLocation() async {
    final userId = AppAuth.instance.currentUser?.uid;
    final context = Get.context;
    if (userId == null || context == null) return;
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
      AppToast.say(message);
    }
  }

  /// Opens Settings to add a city, then picks up the answer.
  Future<void> addCity() async {
    await Get.toNamed<void>(AppRoutes.settings);
    final userId = AppAuth.instance.currentUser?.uid;
    if (userId != null && !isClosed) await _loadViewerCity(userId);
  }

  // ── what each feed shows ───────────────────────────────────────────────

  /// Whether the Community feed is limited to people near the viewer.
  bool get nearOnly => nearMe.value && hasPlace;

  /// The ranked posts for the My Fashion Makeover or Community [feed].
  /// Reads the Rx fields, so call it inside an `Obx`.
  List<Post> rankedPostsFor(HomeFeed feed, List<Post> visible) {
    final _ = _rankingTick.value; // re-rank when blocks or author cities change
    // Only posts this user may see arrive here (the rules enforce it).
    // Daily dress-ups live in My Daily Dress Up, not the makeover feeds.
    // My Fashion Makeover shows yours and everyone else's (H-5); Community
    // shows only other people's.
    final currentUserId = AppAuth.instance.currentUser?.uid ?? '';
    final isMyMakeover = feed == HomeFeed.myMakeover;
    final candidates = visible.where(
      (post) =>
          !post.isDressUp &&
          (isMyMakeover || post.authorId != currentUserId) &&
          // Blocked people vanish at once; the database also hides them.
          !SafetyService.instance.isBlocked(post.authorId) &&
          !SafetyService.instance.isBlocked(post.repostOfAuthorId),
    );
    // People I follow first, then people in my city, then everyone (A-5).
    final ranked = ranking.rankPosts(
      candidates,
      viewerId: currentUserId,
      following: following.value,
      cityOf: _authorCities.known,
      viewerCity: viewerCity.value,
      viewerCell: viewerCell.value,
      cellOf: _authorCities.knownCells,
      now: DateTime.now(),
    );
    if (isMyMakeover || !nearOnly) return ranked;
    return ranking.nearMe(
      ranked,
      viewerId: currentUserId,
      following: following.value,
      cityOf: _authorCities.known,
      viewerCity: viewerCity.value,
      viewerCell: viewerCell.value,
      cellOf: _authorCities.knownCells,
    );
  }

  /// The cached profile of a post's author (or of whoever was reposted).
  Future<PostAuthor> authorOf(String authorId) =>
      _authorProfiles.putIfAbsent(authorId, () => _loadPostAuthor(authorId));

  /// Friends and community posts use the same visual card as My Daily Dress Up.
  Future<PostAuthor> _loadPostAuthor(String authorId) async {
    if (authorId.isEmpty) return PostAuthor.fallback(authorId);

    try {
      final data = await _profiles.get(authorId);
      if (data.isEmpty) return PostAuthor.fallback(authorId);

      final styles = data['stylePreferences'];
      final displayName = (data['displayName'] ?? '').toString();
      return PostAuthor(
        displayName: displayName.isEmpty ? 'User' : displayName,
        // Body photos are private; never used to stand in for an avatar.
        fullBodyImageUrl: '',
        profileImageUrl: (data['profileImageUrl'] ?? '').toString(),
        stylePreference: styles is List && styles.isNotEmpty
            ? styles.first.toString()
            : '',
      );
    } catch (error) {
      debugPrint('Unable to load post author $authorId: $error');
      return PostAuthor.fallback(authorId);
    }
  }

  // ── what a look's menu can do ──────────────────────────────────────────

  Future<void> openAffirmations(
    Post post, {
    required bool isOwner,
    required String ownerName,
  }) async {
    final context = Get.context;
    if (context == null) return;
    if (isOwner) {
      await showReceivedAffirmations(
        context,
        targetType: AffirmationTargetType.post,
        targetId: post.id,
      );
      return;
    }
    if (AppAuth.instance.currentUser == null) {
      AppToast.say('Sign in to affirm looks.');
      return;
    }
    final sent = await showAffirmationComposer(
      context,
      targetType: AffirmationTargetType.post,
      targetId: post.id,
      targetOwnerId: post.authorId,
      recipientName: ownerName,
    );
    if (!sent || isClosed) return;
    AppToast.say('Affirmation sent.');
  }

  /// Shows where the look went and files it under the chosen category.
  Future<void> _fileSavedLook(String userId, String postId) async {
    var categories = const <String>[];
    try {
      categories = await _outfitService.savedLookCategories(userId);
    } on PostgrestException catch (error) {
      // Still show the sheet, with the starter categories.
      debugPrint('Unable to load look categories: ${error.message}');
    }
    final context = Get.context;
    if (isClosed || context == null) return;
    final category = await showSavedToWardrobeSheet(
      context,
      existingCategories: categories,
      onOpenWardrobe: () => Get.to<void>(
        () => const WardrobePage(initialTab: WardrobeTab.savedLooks),
      ),
    );
    if (category == null || category.isEmpty) return;
    try {
      await _outfitService.setSavedLookCategory(
        userId: userId,
        postId: postId,
        category: category,
      );
    } on PostgrestException catch (error) {
      if (isClosed) return;
      AppToast.say('Unable to add to $category: ${error.message}');
    }
  }

  void showAlreadySaved() {
    AppToast.say(
      'Already in your Smart Wardrobe. Remove it from the Wardrobe page.',
    );
  }

  Future<void> saveToWardrobe(
    Post post,
    String imageUrl,
    String caption,
  ) async {
    final userId = AppAuth.instance.currentUser?.uid;
    if (userId == null) {
      AppToast.say('Sign in to save looks.');
      return;
    }
    if (imageUrl.isEmpty) {
      AppToast.say('This look has no picture to save.');
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
      if (isClosed) return;
      savedPostIds.value = {...savedPostIds.value, post.id};
      await _fileSavedLook(userId, post.id);
    } catch (error) {
      if (isClosed) return;
      AppToast.say('Unable to save look: $error');
    }
  }

  /// Opens the Makeover on a saved look so it can be changed and saved back.
  Future<void> editPost(Post post, String imageUrl) async {
    if (imageUrl.isEmpty) {
      AppToast.say('This look has no picture to edit.');
      return;
    }
    await Get.to<void>(
      () => MakeoverPage(initialPhotoUrl: imageUrl, editingPostId: post.id),
    );
  }

  /// Reposts or quotes [post], sharing it first when it is private.
  Future<void> passOn(
    Post post,
    Future<void> Function(BuildContext, Post, {PostService? posts}) action,
  ) async {
    final context = Get.context;
    if (context == null) return;
    final shared = await ensureLookShared(
      context,
      post,
      share: (audience) => _shareToAudience(post, audience),
    );
    final after = Get.context;
    if (!shared || isClosed || after == null) return;
    await action(after, post, posts: _postService);
  }

  Future<void> sharePost(Post post) async {
    final context = Get.context;
    if (context == null) return;
    final audience = await showShareAudienceSheet(context);
    if (audience == null || isClosed) return;
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
      if (isClosed) return;
      AppToast.say(switch (audience) {
        PostVisibility.friends => 'Post shared with friends.',
        PostVisibility.followers => 'Post shared with your followers.',
        PostVisibility.public => 'Post is now public.',
        PostVisibility.private => 'Post is now private.',
      });
    } catch (error) {
      if (isClosed) return;
      AppToast.say('Unable to share post: $error');
    }
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required IconData icon,
    required String action,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Get.back<bool>(result: true),
            icon: Icon(icon),
            label: Text(action),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> makePrivate(Post post) async {
    final confirmed = await _confirm(
      title: 'Make this post private?',
      body:
          'This look will be removed from friends and community feeds. Affirmations and replies stay saved if you share it again later.',
      icon: Icons.lock_outline,
      action: 'Make Private',
    );
    if (!confirmed) return;

    try {
      await _postService.makePostPrivate(post.id);
      if (isClosed) return;
      AppToast.say('Post is now private.');
    } catch (error) {
      if (isClosed) return;
      AppToast.say('Unable to make post private: $error');
    }
  }

  Future<void> deletePost(Post post) async {
    final confirmed = await _confirm(
      title: 'Delete this look?',
      body:
          'This removes the look from your timeline and deletes its affirmations and replies. This cannot be undone.',
      icon: Icons.delete_outline,
      action: 'Delete',
    );
    if (!confirmed) return;

    try {
      await _postService.deletePost(post.id);
      if (isClosed) return;
      AppToast.say('Look deleted.');
    } catch (error) {
      if (isClosed) return;
      AppToast.say('Unable to delete look: $error');
    }
  }

  Future<void> tryOnPost(Post post) async {
    final context = Get.context;
    if (AppAuth.instance.currentUser == null) {
      AppToast.say('Please sign in first.');
      return;
    }
    if (context == null) return;

    var loadingVisible = true;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      final products = await _postService.getPostOutfitProducts(post);
      if (isClosed) return;
      Navigator.of(context, rootNavigator: true).pop();
      loadingVisible = false;

      // Looks made with the photo-first makeover have no products: copy the
      // look itself onto the user as their style twin instead.
      if (products.isEmpty && post.imageURL.isNotEmpty) {
        await _postService.notifyPostTryOn(post);
        if (isClosed) return;
        await Get.to<void>(() => MakeoverPage(initialTwinUrl: post.imageURL));
        return;
      }

      if (products.isEmpty) {
        AppToast.say(
          'This older post has no saved product details. Choose products to recreate the look.',
        );
      }

      final selectedProducts = await showTryOnProductPicker(
        context,
        initialProducts: products,
        outfitLabel: post.authorId == AppAuth.instance.currentUser?.uid
            ? 'This Look'
            : "Friend's Look",
      );
      if (isClosed || selectedProducts == null || selectedProducts.isEmpty) {
        return;
      }

      await _postService.notifyPostTryOn(post);
      if (isClosed) return;

      await Get.toNamed<void>(
        AppRoutes.avatarTryOn,
        arguments: {
          'products': selectedProducts,
          'category':
              (selectedProducts.first['category'] ??
                      tryOnGroup(selectedProducts.first))
                  .toString(),
          'sourcePostId': post.id,
          'sourceOutfitId': post.outfitId,
        },
      );
    } catch (error) {
      if (isClosed) return;
      if (loadingVisible) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      AppToast.say('Unable to load outfit: $error');
    }
  }
}
