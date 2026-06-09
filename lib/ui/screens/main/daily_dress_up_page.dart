// Shows daily outfit inspiration using local weather and wardrobe actions.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../data/models/post.dart';
import '../../../data/services/weather_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/post_service.dart';
import '../../../data/services/friend_service.dart';
import '../../../data/models/weather.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/app_routes.dart';
import '../wardrobe/wardrobe_calendar_page.dart';

/// Page displaying daily dress up recommendations and user posts
class DailyDressUpPage extends StatefulWidget {
  const DailyDressUpPage({super.key});

  @override
  State<DailyDressUpPage> createState() => _DailyDressUpPageState();
}

class _DailyDressUpPageState extends State<DailyDressUpPage> {
  int _selectedTabIndex = 0;
  static const Color primaryColor = Color(0xFF0D0140);

  final WeatherService _weatherService = WeatherService();
  final PostService _postService = PostService();
  final FriendService _friendService = FriendService();
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
      final weather = await _weatherService.fetchWeather(latLong);
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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'My Daily Dress Up',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            _buildAppBarAction(
              Icons.shopping_bag_outlined,
              () => Navigator.pushNamed(context, AppRoutes.cart),
              hasNotification: true,
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: Colors.black,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildTabs(),
            const SizedBox(height: 20),
            _buildStatusHeader(),
            const SizedBox(height: 25),
            _buildPostsFeed(),
            const SizedBox(height: 30),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
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
          return const Center(child: CircularProgressIndicator());
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
                return const Center(child: CircularProgressIndicator());
              }

              final friendIds = friendSnapshot.data!.toSet();
              return _buildPostList(
                posts
                    .where((post) => friendIds.contains(post.authorId))
                    .toList(),
                emptyMessage: 'No posts from your friends yet.',
              );
            },
          );
        }

        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final filteredPosts = _selectedTabIndex == 0
            ? posts.where((post) => post.authorId == currentUserId).toList()
            : posts;

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
              : _buildDressUpItem(posts[index]),
          if (index != posts.length - 1)
            SizedBox(height: useMineLayout ? 16 : 30),
        ],
      ],
    );
  }

  Widget _buildMinePostItem(Post post, int index) {
    const cardColors = [
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
        final isLiked = post.likes.contains(currentUserId);
        final imageUrl = post.imageURL.isNotEmpty
            ? post.imageURL
            : author.fullBodyImageUrl;
        final title = post.caption.trim().isEmpty
            ? 'Daily Outfit'
            : post.caption.trim();
        final subtitle = author.stylePreference.isEmpty
            ? 'Styled for your day'
            : '${_titleCase(author.stylePreference)} style';

        return Container(
          width: double.infinity,
          height: 245,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cardColors[index % cardColors.length],
            borderRadius: BorderRadius.circular(16),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final imageWidth = constraints.maxWidth * 0.38;
              return Stack(
                children: [
                  Positioned.fill(
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              55,
                              imageWidth > 150 ? 6 : 12,
                              88,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: primaryColor,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
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
                            child: _buildMinePostImage(imageUrl),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatPostTime(post.createdAt),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 49,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMineCommand(
                            icon: Icons.shortcut_outlined,
                            label: 'Try On',
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            onTap: imageUrl.isEmpty
                                ? null
                                : () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.camera,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMineCommand(
                            icon: Icons.chat_bubble_outline,
                            label: 'Comment',
                            backgroundColor: const Color(0xFFFF8A2A),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMineCommand(
                            icon: Icons.share_outlined,
                            label: 'Share',
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 42,
                      color: Colors.white.withValues(alpha: 0.82),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildMineReaction(
                              icon: isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              label: '${post.likeCount} likes',
                              color: Colors.red,
                              onTap: currentUserId.isEmpty
                                  ? null
                                  : () => _postService.toggleLike(
                                      post.id,
                                      post.likes,
                                    ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 22,
                            color: Colors.black12,
                          ),
                          Expanded(
                            child: _buildMineReaction(
                              icon: Icons.chat_bubble_outline,
                              label: '${post.commentCount} comments',
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMinePostImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const Align(
        alignment: Alignment.center,
        child: Icon(Icons.checkroom_outlined, size: 72, color: Colors.black26),
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
        return const Align(
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image_outlined,
            size: 54,
            color: Colors.black26,
          ),
        );
      },
    );
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
              const SizedBox(width: 5),
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
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black87,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
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
    return Stack(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.black, size: 28),
          onPressed: onTap,
        ),
        if (hasNotification)
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount == 0) return const SizedBox.shrink();

              return Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
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
          const SizedBox(width: 15),
          _tabButton("My Friends", 1),
          const SizedBox(width: 15),
          _tabButton("Community", 2),
        ],
      ),
    );
  }

  /// Individual tab button with selection state
  Widget _tabButton(String title, int index) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade400,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Header showing current weather and next calendar event
  Widget _buildStatusHeader() {
    if (_isLoadingWeather) {
      return Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFC5CAE9),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const SizedBox(
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFC5CAE9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_outlined, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _currentWeather != null
                  ? "$conditionText | $tempText"
                  : conditionText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              "|",
              style: TextStyle(color: Colors.white54, fontSize: 20),
            ),
          ),
          const Icon(
            Icons.calendar_today_outlined,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          const Text(
            "11 AM Meeting",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// Builds a live Firestore post and resolves its author profile.
  Widget _buildDressUpItem(Post post) {
    return FutureBuilder<_PostAuthor>(
      future: _authorProfiles.putIfAbsent(
        post.authorId,
        () => _loadPostAuthor(post.authorId),
      ),
      builder: (context, authorSnapshot) {
        final author =
            authorSnapshot.data ?? _PostAuthor.fallback(post.authorId);
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
        final isLiked = post.likes.contains(currentUserId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildAuthorAvatar(author),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author.displayName,
                        style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        post.caption.isEmpty ? 'Daily dress-up' : post.caption,
                        style: TextStyle(
                          color: Colors.grey.shade600,
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
            _buildPostContent(post),
            const SizedBox(height: 15),
            Wrap(
              spacing: 20,
              runSpacing: 12,
              children: [
                _buildAction(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  '${post.likeCount}',
                  color: isLiked ? Colors.red : null,
                  onTap: currentUserId.isEmpty
                      ? null
                      : () => _postService.toggleLike(post.id, post.likes),
                ),
                _buildAction(Icons.chat_bubble_outline, '${post.commentCount}'),
                if (post.imageURL.isNotEmpty)
                  _buildAction(
                    Icons.shortcut_outlined,
                    'Try On',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.camera),
                  ),
                _buildAction(Icons.share_outlined, 'Share'),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildAuthorAvatar(_PostAuthor author) {
    final imageUrl = author.profileImageUrl;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: primaryColor,
        backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
        child: imageUrl.isEmpty
            ? Text(
                author.initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildPostContent(Post post) {
    if (post.imageURL.isEmpty) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 150),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF2EEFF),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          post.caption.isEmpty ? 'Daily dress-up post' : post.caption,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 280,
        width: double.infinity,
        child: Image.network(
          post.imageURL,
          fit: BoxFit.cover,
          webHtmlElementStrategy: kIsWeb
              ? WebHtmlElementStrategy.prefer
              : WebHtmlElementStrategy.never,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: Colors.grey.shade100,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Unable to display post ${post.id} image: $error');
            return Container(
              color: Colors.grey.shade100,
              alignment: Alignment.center,
              child: const Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: Colors.grey,
              ),
            );
          },
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
        profileImageUrl:
            (data['profileImageURL'] ??
                    data['profileImageUrl'] ??
                    data['photoURL'] ??
                    '')
                .toString(),
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

  /// Small action button with icon and text below a post
  Widget _buildAction(
    IconData icon,
    String label, {
    Color? color,
    VoidCallback? onTap,
  }) {
    final actionColor = color ?? Colors.grey.shade600;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: actionColor, size: 20),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: actionColor, fontSize: 13)),
        ],
      ),
    );
  }
}

class _PostAuthor {
  final String displayName;
  final String profileImageUrl;
  final String fullBodyImageUrl;
  final String stylePreference;

  const _PostAuthor({
    required this.displayName,
    required this.profileImageUrl,
    required this.fullBodyImageUrl,
    required this.stylePreference,
  });

  factory _PostAuthor.fallback(String authorId) {
    final suffix = authorId.length >= 4
        ? authorId.substring(0, 4).toUpperCase()
        : authorId.toUpperCase();
    return _PostAuthor(
      displayName: suffix.isEmpty ? 'User' : 'User $suffix',
      profileImageUrl: '',
      fullBodyImageUrl: '',
      stylePreference: '',
    );
  }

  String get initial {
    final trimmedName = displayName.trim();
    return trimmedName.isEmpty ? 'U' : trimmedName[0].toUpperCase();
  }
}
