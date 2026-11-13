// "Use a look you love": pick a look to copy onto yourself, from people you
// follow (shown first), your Fashion Twins, the looks you saved (by
// category), the looks you affirmed, the whole community, or the web, with
// search (October 2026 review, M-10 and P-9).
//
// TODO(content-engine): "Trending" and "Style idols" sources need the
// fashion-content engine (review item E-2).
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/makeover/controllers/look_love_controller.dart';
import 'package:banigoba/modules/makeover/widgets/web_look_results.dart';
import 'package:banigoba/modules/social/models/post.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

enum LookLoveSource {
  following('Following'),
  twins('Fashion Twins'),
  saved('Saved'),
  affirmed('Affirmed'),
  community('Community'),
  web('Web');

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
    // Web looks come from a search, not from these sources.
    LookLoveSource.web => const <PickableLook>[],
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

class _LookYouLovePicker extends StatelessWidget {
  const _LookYouLovePicker({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    // Scoped to the sheet: built here, disposed when it closes.
    return GetBuilder<LookLoveController>(
      init: LookLoveController(),
      global: false,
      builder: (love) => _buildBody(context, love),
    );
  }

  Widget _buildBody(BuildContext context, LookLoveController love) {
    final colors = Theme.of(context).colorScheme;
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
            onChanged: love.search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search by words, category, name or @username',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              // Same words, but on the internet.
              suffixIcon: Obx(
                () => love.source.value == LookLoveSource.web
                    ? const SizedBox.shrink()
                    : IconButton(
                        key: const ValueKey('look_love_search_web'),
                        tooltip: 'Search the web',
                        icon: const Icon(Icons.travel_explore),
                        onPressed: () => love.selectSource(LookLoveSource.web),
                      ),
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Obx(
            () => Row(
              children: [
                for (final source in LookLoveSource.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      key: ValueKey('look_love_${source.name}'),
                      avatar: source == LookLoveSource.web
                          ? const Icon(Icons.travel_explore, size: 18)
                          : null,
                      label: Text(source.label),
                      selected: source == love.source.value,
                      onSelected: (_) => love.selectSource(source),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Obx(() {
          final categories = love.categories;
          if (love.source.value != LookLoveSource.saved || categories.isEmpty) {
            return const SizedBox.shrink();
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                for (final category in ['', ...categories])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(category.isEmpty ? 'All saved' : category),
                      selected: category == love.category.value,
                      onSelected: (_) => love.category.value = category,
                    ),
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Expanded(
          child: Obx(() {
            final source = love.source.value;
            if (source == LookLoveSource.web) {
              return WebLookResults(
                state: love.web,
                controller: controller,
                onKept: (url) => Navigator.pop(context, url),
              );
            }
            final looks = love.looks;
            final isLoading = !love.postsLoaded.value;
            return isLoading && source != LookLoveSource.saved
                ? const Center(child: CircularProgressIndicator())
                : looks.isEmpty
                ? _EmptyMessage(
                    source: source,
                    searching: love.query.value.isNotEmpty,
                  )
                : GridView.builder(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                  );
          }),
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
              'No looks yet from people you follow. Try Community or Web.',
            LookLoveSource.twins =>
              'Add Fashion Twins from the menu to see their looks here.',
            LookLoveSource.saved =>
              'Looks you save to your Smart Wardrobe appear here.',
            LookLoveSource.affirmed => 'Looks you affirm appear here.',
            LookLoveSource.community => 'No community looks yet.',
            LookLoveSource.web => 'Type something to search the web.',
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
