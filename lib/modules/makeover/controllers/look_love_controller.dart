// "Use a look you love": the live sources, the chosen source, category and
// search, and the looks that result.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/makeover/widgets/look_you_love_picker.dart';
import 'package:banigoba/modules/social/models/post.dart';
import 'package:banigoba/modules/social/services/affirmation_service.dart';
import 'package:banigoba/modules/social/services/friend_service.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/modules/social/services/visible_posts.dart';
import 'package:banigoba/modules/style_lists/services/style_lists_service.dart';
import 'package:banigoba/modules/wardrobe/services/outfit_service.dart';

class LookLoveController extends GetxController {
  final String userId = AppAuth.instance.currentUser?.uid ?? '';

  final RxList<Post> posts = <Post>[].obs;
  final RxBool postsLoaded = false.obs;
  final RxSet<String> following = <String>{}.obs;
  final RxSet<String> twins = <String>{}.obs;
  final RxList<PickableLook> saved = <PickableLook>[].obs;
  final RxSet<String> affirmed = <String>{}.obs;

  final Rx<LookLoveSource> source = LookLoveSource.following.obs;
  final RxString category = ''.obs;
  final RxString query = ''.obs;
  final RxMap<String, String> authorNames = <String, String>{}.obs;
  final Set<String> _requestedNames = {};

  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    final friends = FriendService();
    _subscriptions
      ..add(
        watchVisiblePosts(
          viewerId: userId,
          following: friends.getFollowingIds(),
          friends: friends.getMutualFriendsIds(),
        ).listen((list) {
          posts.assignAll(list);
          postsLoaded.value = true;
        }),
      )
      ..add(friends.getFollowingIds().listen((ids) => following.assignAll(ids)))
      ..add(
        StyleListsService()
            .watch(userId, StyleList.twins)
            .listen(
              (entries) => twins.assignAll({for (final t in entries) t.id}),
            ),
      )
      ..add(
        OutfitService().watchSavedOutfits(userId).listen((looks) {
          saved.assignAll([
            for (final look in looks)
              PickableLook(
                id: look['id'].toString(),
                imageUrl: (look['imageUrl'] ?? '').toString(),
                caption: (look['name'] ?? '').toString(),
                category: (look['category'] ?? '').toString(),
              ),
          ]);
        }),
      )
      ..add(
        AffirmationService().watchAffirmedPostIds().listen(
          (ids) => affirmed.assignAll(ids),
        ),
      );
  }

  @override
  void onClose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.onClose();
  }

  LookLoveData get data => LookLoveData(
    posts: posts.toList(),
    following: following.toSet(),
    twins: twins.toSet(),
    affirmed: affirmed.toSet(),
    saved: saved.toList(),
  );

  List<PickableLook> get looks => looksFor(
    source.value,
    data,
    viewerId: userId,
    category: category.value,
    query: query.value,
    authorNames: Map.of(authorNames),
  );

  List<String> get categories => savedCategories(saved);

  void selectSource(LookLoveSource chosen) {
    source.value = chosen;
    category.value = '';
  }

  void search(String value) {
    query.value = value;
    if (value.isNotEmpty) _loadNames(posts.map((post) => post.authorId));
  }

  /// Loads "name @username" for authors, so search can match them.
  void _loadNames(Iterable<String> authorIds) {
    for (final id in authorIds.toList()) {
      if (id.isEmpty || !_requestedNames.add(id)) continue;
      ProfileService().get(id).then((data) {
        final name = (data['displayName'] ?? '').toString();
        final username = (data['username'] ?? '').toString();
        if (isClosed) return;
        authorNames[id] = username.isEmpty ? name : '$name @$username';
      }, onError: (Object error) => debugPrint('Name lookup failed: $error'));
    }
  }
}
