// Displays user profiles, public looks, and follow controls.
//
// Laid out like the Home feed's lookbook: a cover (pastel banner, photo,
// name), the follow controls, then the person's public looks as the same
// studio-frame cards Home uses.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/app_routes.dart';
import '../../../core/main_tab.dart';
import '../../../data/models/affirmation.dart';
import '../../../data/models/post.dart';
import '../../../core/supabase/app_auth.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/friend_service.dart';
import '../../../data/services/profile_service.dart';
import '../../../data/services/post_service.dart';
import '../../widgets/affirmation_composer_sheet.dart';
import '../../widgets/affirmation_row.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/dress_up_post_card.dart';
import '../../widgets/forward_look_sheet.dart';
import '../../widgets/look_viewer_page.dart';
import '../../widgets/post_comments_sheet.dart';
import '../../widgets/profile_photo_changer.dart';
import '../../widgets/try_on_product_picker.dart';
import '../main/main_screen.dart';
import '../../widgets/app_network_image.dart';
import 'widgets/profile_cover.dart';

/// Screen displaying user profile details and public Daily Dress Up posts.
class ProfilePage extends StatelessWidget {
  final String? userId; // If null, displays the current user's profile
  // False when embedded as a MainScreen tab, which already supplies its own
  // bottom navigation bar around this page's IndexedStack.
  final bool showBottomNav;
  const ProfilePage({super.key, this.userId, this.showBottomNav = true});

  static const Color _primaryColor = Color(0xFF0D0140);
  static const Color _accent = Color(0xFFF2A93B);

  static Color _ink(ColorScheme colors) =>
      colors.brightness == Brightness.dark ? colors.onSurface : _primaryColor;

  @override
  Widget build(BuildContext context) {
    final currentUserId = AppAuth.instance.currentUser?.uid;
    final targetUserId = userId ?? currentUserId;
    final FriendService friendService = FriendService();

    if (targetUserId == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    final bool isMe = targetUserId == currentUserId;

    return StreamBuilder<Map<String, dynamic>>(
      stream: ProfileService().watch(targetUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Scaffold(body: Center(child: Text("User not found")));
        }

        final userData = snapshot.data!;
        final userName = (userData['displayName'] ?? 'User').toString();
        // Your own email, from your sign-in; it is not on the public
        // profile (U-5).
        final userEmail = isMe
            ? (AppAuth.instance.currentUser?.email ?? '')
            : '';
        final username = (userData['username'] ?? '').toString();
        final profileImageUrl = (userData['profileImageUrl'] ?? '').toString();

        return StreamBuilder<bool>(
          stream: friendService.isFollowing(targetUserId),
          builder: (context, followingSnapshot) {
            final isFollowing = followingSnapshot.data ?? false;
            final bool canSeeContent = isMe || isFollowing;
            final colors = Theme.of(context).colorScheme;
            final ink = _ink(colors);

            return Scaffold(
              backgroundColor: colors.surface,
              // The cover's banner runs up behind the app bar, which turns
              // solid once the page scrolls under it.
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                title: Text(
                  isMe ? "My Profile" : userName,
                  style: TextStyle(
                    color: ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                backgroundColor: WidgetStateColor.resolveWith(
                  (states) => states.contains(WidgetState.scrolledUnder)
                      ? colors.surface
                      : Colors.transparent,
                ),
                foregroundColor: ink,
                elevation: 0,
                scrolledUnderElevation: 0,
                // Clock and battery stay readable over the pale banner.
                systemOverlayStyle: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: colors.brightness == Brightness.dark
                      ? Brightness.light
                      : Brightness.dark,
                  statusBarBrightness: colors.brightness,
                ),
                actions: [
                  if (isMe) ...[
                    IconButton(
                      icon: const Icon(Icons.straighten),
                      tooltip: 'My Profile Details',
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.bodyProfile),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      tooltip: 'Sign out',
                      onPressed: () => AuthService().signOut(),
                    ),
                  ],
                ],
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    ProfileCover(
                      name: userName,
                      photoUrl: profileImageUrl,
                      username: username,
                      // Your email is shown to you only, never to others.
                      email: userEmail,
                      onChangePhoto: isMe
                          ? () => changeProfilePhoto(context)
                          : null,
                    ),
                    // Follow/Unfollow Button (if not viewing own profile)
                    if (!isMe) ...[
                      const SizedBox(height: 18),
                      _buildFollowButton(
                        friendService,
                        targetUserId,
                        isFollowing: isFollowing,
                      ),
                    ],
                    const SizedBox(height: 22),
                    // Followers/Following stats
                    _buildStatsCard(
                      context,
                      friendService,
                      targetUserId,
                      canSeeContent: canSeeContent,
                      showTotal: isMe,
                    ),
                    // Follow starts with finding people (U-3).
                    if (isMe) ...[
                      const SizedBox(height: 14),
                      TextButton.icon(
                        key: const ValueKey('profile_find_people'),
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.search),
                        style: TextButton.styleFrom(
                          foregroundColor: ink,
                          backgroundColor: ink.withValues(alpha: 0.06),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          minimumSize: const Size(0, 44),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        icon: const Icon(Icons.person_search_outlined),
                        label: const Text('Find people to follow'),
                      ),
                    ],
                    _buildLookbookHeading(context, isMe: isMe),
                    _buildPublicDailyDressUps(
                      context,
                      targetUserId,
                      userName,
                      profileImageUrl,
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: showBottomNav
                  ? CustomBottomNavigation(
                      currentIndex: -1,
                      onTap: (index) => _openMainTab(context, index),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  void _openMainTab(BuildContext context, int index) {
    MainScreen.selectTab(MainTab.fromIndex(index));
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Follow, Requested (tap to cancel) or Unfollow, as one pill.
  Widget _buildFollowButton(
    FriendService friendService,
    String targetUserId, {
    required bool isFollowing,
  }) {
    return StreamBuilder<bool>(
      stream: friendService.hasPendingRequest(targetUserId),
      builder: (context, requestSnapshot) {
        final hasRequest = requestSnapshot.data ?? false;
        final ink = _ink(Theme.of(context).colorScheme);
        void onPressed() {
          if (isFollowing) {
            friendService.unfollowUser(targetUserId);
          } else if (hasRequest) {
            friendService.cancelFollowRequest(targetUserId);
          } else {
            friendService.sendFollowRequest(targetUserId);
          }
        }

        const shape = StadiumBorder();
        const size = Size(200, 46);
        const textStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w700);
        if (isFollowing) {
          return OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: ink,
              side: BorderSide(color: ink.withValues(alpha: 0.3)),
              shape: shape,
              minimumSize: size,
              textStyle: textStyle,
            ),
            child: const Text('Unfollow'),
          );
        }
        return FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: hasRequest
                ? _accent.withValues(alpha: 0.2)
                : _primaryColor,
            foregroundColor: hasRequest ? ink : Colors.white,
            shape: shape,
            minimumSize: size,
            textStyle: textStyle,
          ),
          icon: Icon(
            hasRequest ? Icons.schedule : Icons.person_add_alt_1,
            size: 20,
          ),
          label: Text(hasRequest ? 'Requested' : 'Follow'),
        );
      },
    );
  }

  /// Followers and Following, side by side on one raised card.
  Widget _buildStatsCard(
    BuildContext context,
    FriendService friendService,
    String targetUserId, {
    required bool canSeeContent,
    required bool showTotal,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = colors.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _ink(colors).withValues(alpha: isDark ? 0.10 : 0.06),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: _primaryColor.withValues(alpha: 0.07),
                    blurRadius: 24,
                    spreadRadius: -6,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _buildStatColumn(
                  context,
                  'Followers',
                  friendService.getFollowersCount(targetUserId),
                  targetUserId,
                  'followers',
                  canSeeContent,
                  showTotal: showTotal,
                ),
              ),
              VerticalDivider(
                width: 1,
                indent: 16,
                endIndent: 16,
                color: colors.outlineVariant,
              ),
              Expanded(
                child: _buildStatColumn(
                  context,
                  'Following',
                  friendService.getFollowingCount(targetUserId),
                  targetUserId,
                  'following',
                  canSeeContent,
                  showTotal: showTotal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLookbookHeading(BuildContext context, {required bool isMe}) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 32, 22, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              isMe ? 'My lookbook' : 'Lookbook',
              style: TextStyle(
                color: _ink(colors),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          Icon(Icons.public, size: 15, color: colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            'Public looks',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicDailyDressUps(
    BuildContext context,
    String userId,
    String userName,
    String profileImageUrl,
  ) {
    final stream = supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('author_id', userId)
        .map(
          (rows) => [
            for (final row in rows)
              if (row['visibility'] == PostVisibility.public.value)
                Post.fromRow(row),
          ],
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
      child: StreamBuilder<List<Post>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Unable to load public Daily Dress Ups.'),
            );
          }

          final posts = [...?snapshot.data];
          posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (posts.isEmpty) return _buildEmptyLookbook(context);

          return Column(
            children: [
              for (var index = 0; index < posts.length; index++) ...[
                _buildPublicDailyDressUpCard(
                  context,
                  posts[index],
                  index,
                  userName,
                  profileImageUrl,
                ),
                if (index != posts.length - 1) const SizedBox(height: 18),
              ],
            ],
          );
        },
      ),
    );
  }

  /// An empty studio: the backdrop and a hanger, waiting for a first look.
  Widget _buildEmptyLookbook(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final backdrop = kLookBackdrops[1];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: RadialGradient(
          radius: 1.2,
          colors: [
            for (final colour in [Colors.white, backdrop])
              isDark ? Color.lerp(colour, Colors.black, 0.7)! : colour,
          ],
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.checkroom_outlined, size: 44, color: _ink(colors)),
          const SizedBox(height: 12),
          Text(
            'No public Daily Dress Ups yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicDailyDressUpCard(
    BuildContext context,
    Post post,
    int index,
    String userName,
    String profileImageUrl,
  ) {
    final currentUserId = AppAuth.instance.currentUser?.uid ?? '';
    final isOwner = currentUserId == post.authorId;
    final caption = post.caption.trim().isEmpty
        ? 'Daily dress-up'
        : post.caption.trim();
    final pieces = post.products
        .map(_productImageUrl)
        .where((url) => url.isNotEmpty)
        .take(4)
        .toList();

    return DressUpPostCard(
      key: ValueKey('profile_post_${post.id}'),
      isMineLayout: true,
      title: userName,
      subtitle: caption,
      avatarUrl: profileImageUrl,
      timeLabel: _formatPostTime(post.createdAt),
      imageBackground: kLookBackdrops[index % kLookBackdrops.length],
      visual: _buildLookImage(context, post.imageURL),
      onImageTap: post.imageURL.isEmpty
          ? null
          : () => openLookViewer(
              context,
              imageUrl: post.imageURL,
              title: userName,
              caption: caption,
            ),
      actions: [
        DressUpCardAction(
          glyph: 'a',
          chipLabel: isOwner ? 'Affirmations' : 'Affirm',
          label: isOwner ? 'Affirmations received' : 'Affirm',
          onTap: () => _openAffirmations(
            context,
            post,
            isOwner: isOwner,
            ownerName: userName,
          ),
        ),
        DressUpCardAction(
          icon: Icons.chat_bubble_outline,
          label: post.commentCount == 1
              ? '1 comment'
              : '${post.commentCount} comments',
          onTap: () => showPostCommentsSheet(context, post),
        ),
        DressUpCardAction(
          icon: Icons.accessibility_new,
          label: 'Try On',
          onTap: () => _tryOnPost(context, post),
        ),
      ],
      trailingAction: DressUpCardAction(
        icon: Icons.share_outlined,
        label: kSendToLabel,
        onTap: () => showForwardLookSheet(
          context,
          imageUrl: post.imageURL,
          caption: post.caption,
        ),
      ),
      // The pieces the look is made of, then which affirmations it got;
      // never how many (BNG SRS 001, AFF-003).
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pieces.isNotEmpty) _buildPieces(context, pieces),
          AffirmationRow(
            targetType: AffirmationTargetType.post,
            targetId: post.id,
            targetOwnerId: post.authorId,
            currentUserId: currentUserId,
            ownerName: isOwner ? 'your look' : userName,
            showAction: false,
            onOpenReceived: () => showReceivedAffirmations(
              context,
              targetType: AffirmationTargetType.post,
              targetId: post.id,
            ),
          ),
        ],
      ),
    );
  }

  /// The whole look, standing on the bottom of the card's studio frame.
  Widget _buildLookImage(BuildContext context, String imageUrl) {
    final fallback = Center(
      child: Icon(
        Icons.checkroom_outlined,
        size: 64,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
    if (imageUrl.isEmpty) return fallback;
    return AppNetworkImage(
      imageUrl,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      fallback: fallback,
    );
  }

  /// "In this look": small swatches of the pieces the outfit is made of.
  Widget _buildPieces(BuildContext context, List<String> imageUrls) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 10),
      child: Row(
        children: [
          Text(
            'In this look',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          for (final url in imageUrls)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: AppNetworkImage(
                  url,
                  fit: BoxFit.contain,
                  fallback: Icon(
                    Icons.checkroom_outlined,
                    size: 20,
                    color: colors.outline,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The owner sees what their look received; anyone else affirms it.
  Future<void> _openAffirmations(
    BuildContext context,
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
    final messenger = ScaffoldMessenger.of(context);
    if (AppAuth.instance.currentUser == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sign in to affirm looks.')),
      );
      return;
    }
    final sent = await showAffirmationComposer(
      context,
      targetType: AffirmationTargetType.post,
      targetId: post.id,
      targetOwnerId: post.authorId,
      recipientName: ownerName,
    );
    if (!sent) return;
    messenger.showSnackBar(const SnackBar(content: Text('Affirmation sent.')));
  }

  String _productImageUrl(Map<String, dynamic> product) {
    const fields = [
      'rawImageUrl',
      'imageUrl',
      'imageURL',
      'processedImageUrl',
      'processed_url',
      'raw_url',
    ];
    for (final field in fields) {
      final value = product[field];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  Future<void> _tryOnPost(BuildContext context, Post post) async {
    if (AppAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in first.')));
      return;
    }

    var loadingVisible = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final products = await PostService().getPostOutfitProducts(post);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      loadingVisible = false;

      final selectedProducts = await showTryOnProductPicker(
        context,
        initialProducts: products,
        outfitLabel: "Friend's Look",
      );
      if (!context.mounted ||
          selectedProducts == null ||
          selectedProducts.isEmpty) {
        return;
      }

      await PostService().notifyPostTryOn(post);
      if (!context.mounted) return;

      await Navigator.pushNamed(
        context,
        AppRoutes.avatarTryOn,
        arguments: {
          'products': selectedProducts,
          'category': (selectedProducts.first['category'] ?? '').toString(),
          'sourcePostId': post.id,
          'sourceOutfitId': post.outfitId,
        },
      );
    } catch (error) {
      if (!context.mounted) return;
      if (loadingVisible) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to load outfit: $error')));
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

  /// Helper for building statistic columns (Followers/Following)
  Widget _buildStatColumn(
    BuildContext context,
    String label,
    Stream<int> stream,
    String userId,
    String type,
    bool canSee, {
    required bool showTotal,
  }) {
    final colors = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(
      color: colors.onSurfaceVariant,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );
    return InkWell(
      onTap: () {
        if (canSee) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  UserListPage(userId: userId, type: type, title: label),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Follow this account to see their list"),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        // Totals are a private signal: only the profile's owner sees their
        // numbers (BNG SRS 001; October 2026 review, U-2). Others get the
        // list, without a number.
        child: showTotal
            ? StreamBuilder<int>(
                stream: stream,
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Column(
                    children: [
                      Text(
                        count.toString(),
                        key: ValueKey('profile_${type}_total'),
                        style: TextStyle(
                          color: _ink(colors),
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(label, style: labelStyle),
                    ],
                  );
                },
              )
            : Column(
                children: [
                  Icon(Icons.people_outline, color: _ink(colors)),
                  const SizedBox(height: 4),
                  Text(label, style: labelStyle),
                ],
              ),
      ),
    );
  }
}

/// Page displaying incoming follow requests
class FollowRequestsPage extends StatelessWidget {
  const FollowRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FriendService friendService = FriendService();

    return Scaffold(
      appBar: AppBar(title: const Text("Follow Requests")),
      body: StreamBuilder<List<String>>(
        stream: friendService.getIncomingRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No pending requests"));
          }

          final requests = snapshot.data!;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final requesterId = requests[index];
              return StreamBuilder<Map<String, dynamic>>(
                stream: ProfileService().watch(requesterId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || userSnapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final userData = userSnapshot.data!;
                  final name = userData['displayName'] ?? 'User';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF0D0140),
                      child: Text(
                        name[0].toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(name),
                    subtitle: const Text("wants to follow you"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton(
                          onPressed: () =>
                              friendService.acceptFollowRequest(requesterId),
                          child: const Text('Accept'),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          onPressed: () =>
                              friendService.declineFollowRequest(requesterId),
                          child: const Text('Decline'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Generic page displaying a list of users (e.g. Followers list)
class UserListPage extends StatelessWidget {
  final String userId;
  final String type; // 'followers' or 'following'
  final String title;

  const UserListPage({
    super.key,
    required this.userId,
    required this.type,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<List<String>>(
        stream: FriendService().listUserIds(userId, type),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No $title yet"));
          }

          final userIds = snapshot.data!;

          return ListView.builder(
            itemCount: userIds.length,
            itemBuilder: (context, index) {
              return StreamBuilder<Map<String, dynamic>>(
                stream: ProfileService().watch(userIds[index]),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || userSnapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final userData = userSnapshot.data!;
                  final name = userData['displayName'] ?? 'User';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF0D0140),
                      child: Text(
                        name[0].toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(name),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProfilePage(userId: userIds[index]),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
