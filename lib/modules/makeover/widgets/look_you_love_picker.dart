// "Use a look you love": pick a look to copy onto yourself, from people you
// follow (shown first), your Fashion Twins, the looks you saved (by
// category), the looks you affirmed, or the whole community, with search
// (October 2026 review, M-10 and P-9).
//
// TODO(content-engine): "Trending" and "Style idols" sources need the
// fashion-content engine (review item E-2).
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:banigoba/modules/social/models/post.dart';
import 'package:banigoba/modules/social/services/affirmation_service.dart';
import 'package:banigoba/modules/social/services/friend_service.dart';
import 'package:banigoba/modules/wardrobe/services/outfit_service.dart';
import 'package:banigoba/modules/style_lists/services/style_lists_service.dart';
import 'package:banigoba/modules/social/services/visible_posts.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

enum LookLoveSource {
  following('Following'),
  twins('Fashion Twins'),
  saved('Saved'),
  affirmed('Affirmed'),
  community('Community');

  const LookLoveSource(this.label);

  final String label;
}

/// One look that can be picked: from a post or a saved look.
@immutable
class PickableLook {
  const PickableLook({
    required this.id,
    required this.imageUrl,
    this.caption = '',
    this.authorId = '',
    this.category = '',
  });

  final String id;
  final String imageUrl;
  final String caption;
  final String authorId;

  /// Saved looks only: the category the user filed it under.
  final String category;
}

/// Everything the picker filters from, gathered from the live sources.
@immutable
class LookLoveData {
  const LookLoveData({
    this.posts = const [],
    this.saved = const [],
    this.following = const {},
    this.twins = const {},
    this.affirmed = const {},
  });

  final List<Post> posts;
  final List<PickableLook> saved;
  final Set<String> following;
  final Set<String> twins;
  final Set<String> affirmed;
}

PickableLook _fromPost(Post post) => PickableLook(
  id: post.id,
  imageUrl: post.imageURL,
  caption: post.caption,
  authorId: post.authorId,
);

/// The looks for [source], narrowed by [category] (Saved only) and by
/// [query] against caption, category and the author's name or @username
/// ([authorNames] maps author ids to "name @username").
List<PickableLook> looksFor(
  LookLoveSource source,
  LookLoveData data, {
  required String viewerId,
  String category = '',
  String query = '',
  Map<String, String> authorNames = const {},
}) {
  final others = data.posts.where(
    (post) =>
        post.imageURL.isNotEmpty &&
        post.authorId != viewerId &&
        !post.isDressUp,
  );
  final looks = switch (source) {
    LookLoveSource.following =>
      others.where((p) => data.following.contains(p.authorId)).map(_fromPost),
    LookLoveSource.twins =>
      others.where((p) => data.twins.contains(p.authorId)).map(_fromPost),
    LookLoveSource.affirmed =>
      others.where((p) => data.affirmed.contains(p.id)).map(_fromPost),
    LookLoveSource.community => others.where((p) => p.isPublic).map(_fromPost),
    LookLoveSource.saved => data.saved.where(
      (look) =>
          look.imageUrl.isNotEmpty &&
          (category.isEmpty || look.category == category),
    ),
  };
  final needle = query.trim().toLowerCase().replaceFirst('@', '');
  if (needle.isEmpty) return List.unmodifiable(looks);
  return List.unmodifiable(
    looks.where(
      (look) => [
        look.caption,
        look.category,
        authorNames[look.authorId] ?? '',
      ].any((text) => text.toLowerCase().contains(needle)),
    ),
  );
}

/// The saved-look categories, A to Z.
List<String> savedCategories(Iterable<PickableLook> saved) => List.unmodifiable(
  {
    for (final look in saved)
      if (look.category.isNotEmpty) look.category,
  }.toList()..sort(),
);

/// Returns the image URL of the chosen look, or null when cancelled.
Future<String?> showLookYouLovePicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) =>
          _LookYouLovePicker(controller: controller),
    ),
  );
}

class _LookYouLovePicker extends StatefulWidget {
  const _LookYouLovePicker({required this.controller});

  final ScrollController controller;

  @override
  State<_LookYouLovePicker> createState() => _LookYouLovePickerState();
}

class _LookYouLovePickerState extends State<_LookYouLovePicker> {
  final String _userId = AppAuth.instance.currentUser?.uid ?? '';
  final FriendService _friends = FriendService();
  late final Stream<List<Post>> _posts = watchVisiblePosts(
    viewerId: _userId,
    following: _friends.getFollowingIds(),
    friends: _friends.getMutualFriendsIds(),
  );
  late final Stream<List<String>> _following = _friends.getFollowingIds();
  late final Stream<List<StyleListEntry>> _twins = StyleListsService().watch(
    _userId,
    StyleList.twins,
  );
  late final Stream<List<Map<String, dynamic>>> _saved = OutfitService()
      .watchSavedOutfits(_userId);
  late final Stream<Set<String>> _affirmed = AffirmationService()
      .watchAffirmedPostIds();

  LookLoveSource _source = LookLoveSource.following;
  String _category = '';
  String _query = '';
  final Map<String, String> _authorNames = {};
  final Set<String> _requestedNames = {};

  /// Loads "name @username" for authors, so search can match them.
  void _loadNames(Iterable<String> authorIds) {
    for (final id in authorIds) {
      if (id.isEmpty || !_requestedNames.add(id)) continue;
      ProfileService().get(id).then((data) {
        final name = (data['displayName'] ?? '').toString();
        final username = (data['username'] ?? '').toString();
        if (!mounted) return;
        setState(
          () => _authorNames[id] = username.isEmpty ? name : '$name @$username',
        );
      }, onError: (Object error) => debugPrint('Name lookup failed: $error'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return StreamBuilder<List<Post>>(
      stream: _posts,
      builder: (context, posts) => StreamBuilder<List<String>>(
        stream: _following,
        builder: (context, following) => StreamBuilder<List<StyleListEntry>>(
          stream: _twins,
          builder: (context, twins) =>
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _saved,
                builder: (context, saved) => StreamBuilder<Set<String>>(
                  stream: _affirmed,
                  builder: (context, affirmed) {
                    final data = LookLoveData(
                      posts: posts.data ?? const [],
                      following: (following.data ?? const []).toSet(),
                      twins: {for (final t in twins.data ?? const []) t.id},
                      affirmed: affirmed.data ?? const {},
                      saved: [
                        for (final look in saved.data ?? const [])
                          PickableLook(
                            id: look['id'].toString(),
                            imageUrl: (look['imageUrl'] ?? '').toString(),
                            caption: (look['name'] ?? '').toString(),
                            category: (look['category'] ?? '').toString(),
                          ),
                      ],
                    );
                    final looks = looksFor(
                      _source,
                      data,
                      viewerId: _userId,
                      category: _category,
                      query: _query,
                      authorNames: _authorNames,
                    );
                    if (_query.isNotEmpty) {
                      _loadNames(data.posts.map((post) => post.authorId));
                    }
                    return _buildBody(
                      colors,
                      looks,
                      savedCategories(data.saved),
                      isLoading: !posts.hasData,
                    );
                  },
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildBody(
    ColorScheme colors,
    List<PickableLook> looks,
    List<String> categories, {
    required bool isLoading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Text(
            'Find a look you love',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: TextField(
            key: const ValueKey('look_love_search'),
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Search by words, category, name or @username',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (final source in LookLoveSource.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    key: ValueKey('look_love_${source.name}'),
                    label: Text(source.label),
                    selected: source == _source,
                    onSelected: (_) => setState(() {
                      _source = source;
                      _category = '';
                    }),
                  ),
                ),
            ],
          ),
        ),
        if (_source == LookLoveSource.saved && categories.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                for (final category in ['', ...categories])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(category.isEmpty ? 'All saved' : category),
                      selected: category == _category,
                      onSelected: (_) => setState(() => _category = category),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: isLoading && _source != LookLoveSource.saved
              ? const Center(child: CircularProgressIndicator())
              : looks.isEmpty
              ? _EmptyMessage(source: _source, searching: _query.isNotEmpty)
              : GridView.builder(
                  controller: widget.controller,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 3 / 4,
                  ),
                  itemCount: looks.length,
                  itemBuilder: (context, index) {
                    final look = looks[index];
                    return InkWell(
                      key: ValueKey('look_love_pick_${look.id}'),
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(context, look.imageUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AppNetworkImage(
                          look.imageUrl,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          fallback: ColoredBox(
                            color: colors.surfaceContainerHigh,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.source, required this.searching});

  final LookLoveSource source;
  final bool searching;

  @override
  Widget build(BuildContext context) {
    final text = searching
        ? 'Nothing matches that search here. Try another word or source.'
        : switch (source) {
            LookLoveSource.following =>
              'No looks yet from people you follow. Try Community.',
            LookLoveSource.twins =>
              'Add Fashion Twins from the menu to see their looks here.',
            LookLoveSource.saved =>
              'Looks you save to your Smart Wardrobe appear here.',
            LookLoveSource.affirmed => 'Looks you affirm appear here.',
            LookLoveSource.community => 'No community looks yet.',
          };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
