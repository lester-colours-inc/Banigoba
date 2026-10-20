// Displays user profiles, public dress-up posts, and follow controls.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/app_routes.dart';
import '../../../core/main_tab.dart';
import '../../../data/models/affirmation.dart';
import '../../../data/models/post.dart';
import '../../../data/services/friend_service.dart';
import '../../../data/services/post_service.dart';
import '../../widgets/affirmation_row.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/post_comments_sheet.dart';
import '../../widgets/profile_photo_changer.dart';
import '../../widgets/try_on_product_picker.dart';
import '../main/main_screen.dart';
import '../../widgets/app_network_image.dart';

/// Screen displaying user profile details and public Daily Dress Up posts.
class ProfilePage extends StatelessWidget {
  final String? userId; // If null, displays the current user's profile
  // False when embedded as a MainScreen tab, which already supplies its own
  // bottom navigation bar around this page's IndexedStack.
  final bool showBottomNav;
  const ProfilePage({super.key, this.userId, this.showBottomNav = true});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final targetUserId = userId ?? currentUserId;
    final FriendService friendService = FriendService();

    if (targetUserId == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    final bool isMe = targetUserId == currentUserId;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text("User not found")));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final userName = userData['displayName'] ?? 'User';
        final userEmail = userData['email'] ?? '';
        final profileImageUrl =
            (userData['profileImageURL'] ?? userData['profileImageUrl'] ?? '')
                .toString();

        return StreamBuilder<bool>(
          stream: friendService.isFollowing(targetUserId),
          builder: (context, followingSnapshot) {
            final isFollowing = followingSnapshot.data ?? false;
            final bool canSeeContent = isMe || isFollowing;
            final avatar = CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF0D0140),
              backgroundImage: profileImageUrl.isEmpty
                  ? null
                  : CachedNetworkImageProvider(profileImageUrl),
              child: profileImageUrl.isEmpty
                  ? Text(
                      userName.toString().isEmpty
                          ? 'U'
                          : userName.toString().substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 40, color: Colors.white),
                    )
                  : null,
            );

            return Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              appBar: AppBar(
                title: Text(isMe ? "My Profile" : userName),
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Colors.black,
                elevation: 0,
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
                      onPressed: () => FirebaseAuth.instance.signOut(),
                    ),
                  ],
                ],
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Profile Avatar: your own can be changed by tapping it.
                    if (isMe)
                      Semantics(
                        button: true,
                        label: 'Change profile photo',
                        child: GestureDetector(
                          key: const ValueKey('profile_change_photo'),
                          onTap: () => changeProfilePhoto(context),
                          child: Stack(
                            children: [
                              avatar,
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      avatar,
                    const SizedBox(height: 10),
                    // User Name and Email
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Your email is shown to you only, never to others.
                    if (isMe)
                      Text(userEmail, style: TextStyle(color: Colors.grey)),
                    // Follow/Unfollow Button (if not viewing own profile)
                    if (!isMe) ...[
                      const SizedBox(height: 20),
                      StreamBuilder<bool>(
                        stream: friendService.hasPendingRequest(targetUserId),
                        builder: (context, requestSnapshot) {
                          final hasRequest = requestSnapshot.data ?? false;
                          return ElevatedButton(
                            onPressed: () {
                              if (isFollowing) {
                                friendService.unfollowUser(targetUserId);
                              } else if (hasRequest) {
                                friendService.cancelFollowRequest(targetUserId);
                              } else {
                                friendService.sendFollowRequest(targetUserId);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowing
                                  ? Colors.grey
                                  : (hasRequest
                                        ? Colors.orange
                                        : const Color(0xFF0D0140)),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              isFollowing
                                  ? 'Unfollow'
                                  : (hasRequest ? 'Requested' : 'Follow'),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 30),
                    // Followers/Following stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn(
                          context,
                          'Followers',
                          friendService.getFollowersCount(targetUserId),
                          targetUserId,
                          'followers',
                          canSeeContent,
                        ),
                        _buildStatColumn(
                          context,
                          'Following',
                          friendService.getFollowingCount(targetUserId),
                          targetUserId,
                          'following',
                          canSeeContent,
                        ),
                      ],
                    ),
                    // Follow starts with finding people (U-3).
                    if (isMe) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        key: const ValueKey('profile_find_people'),
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.search),
                        icon: const Icon(Icons.person_search_outlined),
                        label: const Text('Find people to follow'),
                      ),
                    ],
                    const SizedBox(height: 30),
                    const Divider(),
                    _buildPublicDailyDressUps(
                      context,
                      targetUserId,
                      userName.toString(),
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

  Widget _buildPublicDailyDressUps(
    BuildContext context,
    String userId,
    String userName,
    String profileImageUrl,
  ) {
    final stream = FirebaseFirestore.instance
        .collection('posts')
        .where('authorId', isEqualTo: userId)
        .where('isPublic', isEqualTo: true)
        .snapshots();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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

              final posts =
                  snapshot.data?.docs.map(Post.fromFirestore).toList() ??
                  <Post>[];
              posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

              if (posts.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 44,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.checkroom_outlined,
                        size: 42,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No public Daily Dress Ups yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  for (var index = 0; index < posts.length; index++) ...[
                    _buildPublicDailyDressUpCard(
                      context,
                      posts[index],
                      userName,
                      profileImageUrl,
                    ),
                    if (index != posts.length - 1) const SizedBox(height: 30),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPublicDailyDressUpCard(
    BuildContext context,
    Post post,
    String userName,
    String profileImageUrl,
  ) {
    final colors = Theme.of(context).colorScheme;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final initial = userName.trim().isEmpty
        ? 'U'
        : userName.trim()[0].toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF0D0140),
                backgroundImage: profileImageUrl.isEmpty
                    ? null
                    : CachedNetworkImageProvider(profileImageUrl),
                child: profileImageUrl.isEmpty
                    ? Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Color(0xFF0D0140),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    post.caption.isEmpty ? 'Daily dress-up' : post.caption,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatPostTime(post.createdAt),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _buildPublicPostPreview(context, post),
        const SizedBox(height: 15),
        AffirmationRow(
          targetType: AffirmationTargetType.post,
          targetId: post.id,
          targetOwnerId: post.authorId,
          currentUserId: currentUserId,
          ownerName: userName,
          onOpenReceived: () => showReceivedAffirmations(
            context,
            targetType: AffirmationTargetType.post,
            targetId: post.id,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 20,
          runSpacing: 12,
          children: [
            _buildPostAction(
              context,
              Icons.chat_bubble_outline,
              '${post.commentCount}',
              onTap: () => showPostCommentsSheet(context, post),
            ),
            _buildPostAction(
              context,
              Icons.shortcut_outlined,
              'Try On',
              onTap: () => _tryOnPost(context, post),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPublicPostPreview(BuildContext context, Post post) {
    final colors = Theme.of(context).colorScheme;
    final products = post.products
        .where((product) => _productImageUrl(product).isNotEmpty)
        .take(3)
        .toList();

    if (products.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 280,
          width: double.infinity,
          child: _buildNetworkImage(
            post.imageURL,
            colors,
            fit: BoxFit.cover,
            fallbackIcon: Icons.checkroom_outlined,
          ),
        ),
      );
    }

    return Container(
      height: 310,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildNetworkImage(
                post.imageURL,
                colors,
                fit: BoxFit.contain,
                fallbackIcon: Icons.person_outline,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                for (var index = 0; index < products.length; index++) ...[
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: _buildNetworkImage(
                        _productImageUrl(products[index]),
                        colors,
                        fit: BoxFit.contain,
                        fallbackIcon: Icons.checkroom_outlined,
                      ),
                    ),
                  ),
                  if (index != products.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkImage(
    String imageUrl,
    ColorScheme colors, {
    required BoxFit fit,
    required IconData fallbackIcon,
  }) {
    if (imageUrl.isEmpty) {
      return Container(
        color: colors.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(fallbackIcon, color: colors.outline, size: 38),
      );
    }

    return AppNetworkImage(
      imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: fit,
      fallback: Container(
        color: colors.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_outlined, color: colors.outline),
      ),
    );
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

  Widget _buildPostAction(
    BuildContext context,
    IconData icon,
    String label, {
    Color? color,
    VoidCallback? onTap,
  }) {
    final actionColor = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: actionColor, size: 20),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: actionColor, fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _tryOnPost(BuildContext context, Post post) async {
    if (FirebaseAuth.instance.currentUser == null) {
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
    bool canSee,
  ) {
    return GestureDetector(
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
      child: StreamBuilder<int>(
        stream: stream,
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(label, style: TextStyle(color: Colors.grey)),
            ],
          );
        },
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
      body: StreamBuilder<QuerySnapshot>(
        stream: friendService.getIncomingRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No pending requests"));
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final requesterId = requests[index].id;
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(requesterId)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection(type)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No $title yet"));
          }

          final userIds = snapshot.data!.docs.map((doc) => doc.id).toList();

          return ListView.builder(
            itemCount: userIds.length,
            itemBuilder: (context, index) {
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userIds[index])
                    .snapshots(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
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
