// "Follow back": whether the viewer follows or has asked, and sending the ask.
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/social/services/friend_service.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class FollowBackController extends GetxController {
  FollowBackController({required this.userId, FriendService? friends})
    : _friends = friends ?? FriendService();

  final String userId;
  final FriendService _friends;

  late final Stream<bool> isFollowing = _friends.isFollowing(userId);
  late final Stream<bool> isRequested = _friends.hasPendingRequest(userId);
  final RxBool sending = false.obs;

  Future<void> followBack() async {
    sending.value = true;
    try {
      await _friends.sendFollowRequest(userId);
    } on Exception catch (error) {
      debugPrint('Unable to follow back $userId: $error');
      if (!isClosed) {
        AppToast.say('Unable to follow back. Try again.');
      }
    } finally {
      if (!isClosed) sending.value = false;
    }
  }
}
