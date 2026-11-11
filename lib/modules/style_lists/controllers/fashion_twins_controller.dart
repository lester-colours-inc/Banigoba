// My Fashion Twins: the twins list, the people search and adding a twin.
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/social/services/friend_service.dart';
import 'package:banigoba/modules/social/views/profile_page.dart';
import 'package:banigoba/modules/style_lists/services/style_lists_service.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class FashionTwinsController extends GetxController {
  FashionTwinsController({StyleListsService? lists, FriendService? friends})
    : lists = lists ?? StyleListsService(),
      _friends = friends ?? FriendService();

  final StyleListsService lists;
  final FriendService _friends;
  final String userId = AppAuth.instance.currentUser?.uid ?? '';
  late final Stream<List<StyleListEntry>> twins = lists.watch(
    userId,
    StyleList.twins,
  );

  /// The trimmed, lower-case search text.
  final RxString query = ''.obs;

  void onSearchChanged(String value) =>
      query.value = value.trim().toLowerCase();

  void removeTwin(String id) => lists.remove(userId, StyleList.twins, id);

  void openProfile(String uid) => Get.to<void>(() => ProfilePage(userId: uid));

  Future<void> addTwin(String uid, Map<String, dynamic> data) async {
    final name = (data['displayName'] ?? data['name'] ?? 'User').toString();
    try {
      await lists.add(
        userId,
        StyleList.twins,
        StyleListEntry(
          id: uid,
          name: name,
          username: (data['username'] ?? '').toString(),
          imageUrl: (data['profileImageUrl'] ?? '').toString(),
        ),
      );
      // Twins' looks reach your feeds through following them.
      final following = await _friends.isFollowing(uid).first;
      if (!following) await _friends.sendFollowRequest(uid);
      AppToast.say(
        following
            ? '$name is now one of your Fashion Twins.'
            : '$name is now one of your Fashion Twins. We asked to '
                  'follow them so their looks reach your feed.',
      );
    } on PostgrestException catch (error) {
      AppToast.say('Could not add $name: ${error.message}');
    }
  }
}
