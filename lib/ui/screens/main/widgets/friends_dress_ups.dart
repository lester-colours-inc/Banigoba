// "From your friends today": daily dress-ups that friends and people you
// follow chose to share, shown at the top of My Daily Dress Up so the feed
// is not only your own things (October 2026 review, D-2).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/post.dart';
import '../../../../data/services/friend_service.dart';
import '../../../../data/services/visible_posts.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/look_viewer_page.dart';

/// How far back a shared dress-up still counts as "today".
const Duration kDressUpWindow = Duration(hours: 36);

/// Friends' dress-ups the viewer may see, newest first, within the window.
List<Post> friendsDressUps(
  Iterable<Post> posts, {
  required String viewerId,
  required Set<String> following,
  required Set<String> friends,
  required DateTime now,
}) {
  return posts
      .where(
        (post) =>
            post.isDressUp &&
            post.authorId != viewerId &&
            now.difference(post.createdAt) <= kDressUpWindow &&
            post.isVisibleTo(viewerId, following: following, friends: friends),
      )
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

class FriendsDressUps extends StatefulWidget {
  const FriendsDressUps({super.key, required this.viewerId});

  final String viewerId;

  @override
  State<FriendsDressUps> createState() => _FriendsDressUpsState();
}

class _FriendsDressUpsState extends State<FriendsDressUps> {
  final FriendService _friendService = FriendService();
  // Only posts this viewer may see (the rules enforce it).
  late final Stream<List<Post>> _posts = watchVisiblePosts(
    viewerId: widget.viewerId,
    following: _friendService.getFollowingIds(),
    friends: _friendService.getMutualFriendsIds(),
  );
  late final Stream<List<String>> _following = _friendService.getFollowingIds();
  late final Stream<List<String>> _friends = _friendService
      .getMutualFriendsIds();
  final Map<String, Future<String>> _names = {};

  Future<String> _nameOf(String userId) => _names.putIfAbsent(userId, () async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    final name = (doc.data()?['displayName'] ?? '').toString().trim();
    return name.isEmpty ? 'A friend' : name;
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Post>>(
      stream: _posts,
      builder: (context, posts) => StreamBuilder<List<String>>(
        stream: _following,
        builder: (context, following) => StreamBuilder<List<String>>(
          stream: _friends,
          builder: (context, friends) {
            if (!posts.hasData || !following.hasData || !friends.hasData) {
              return const SizedBox.shrink();
            }
            final shared = friendsDressUps(
              posts.data!,
              viewerId: widget.viewerId,
              following: following.data!.toSet(),
              friends: friends.data!.toSet(),
              now: DateTime.now(),
            );
            if (shared.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'From your friends today',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 190,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: shared.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) =>
                          _buildTile(shared[index]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTile(Post post) {
    final colors = Theme.of(context).colorScheme;
    return FutureBuilder<String>(
      future: _nameOf(post.authorId),
      builder: (context, name) {
        final author = name.data ?? '';
        return GestureDetector(
          key: ValueKey('friend_dress_up_${post.id}'),
          onTap: () => openLookViewer(
            context,
            imageUrl: post.imageURL,
            title: author,
            caption: post.caption,
          ),
          child: SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ColoredBox(
                      color: colors.surfaceContainerHigh,
                      child: AppNetworkImage(
                        post.imageURL,
                        width: 120,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
