// A person's profile: their details, whether the viewer follows them, their
// public looks, and what the viewer can do (follow, affirm, try on).
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/app/routes/app_routes.dart';
import 'package:banigoba/core/main_tab.dart';
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/core/supabase/supabase_config.dart';
import 'package:banigoba/modules/auth/services/auth_service.dart';
import 'package:banigoba/modules/home/controllers/main_controller.dart';
import 'package:banigoba/modules/makeover/widgets/try_on_product_picker.dart';
import 'package:banigoba/modules/social/models/affirmation.dart';
import 'package:banigoba/modules/social/models/post.dart';
import 'package:banigoba/modules/social/services/friend_service.dart';
import 'package:banigoba/modules/social/services/post_service.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/modules/social/widgets/affirmation_composer_sheet.dart';
import 'package:banigoba/modules/social/widgets/affirmation_row.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class ProfileController extends GetxController {
  ProfileController({
    required this.userId,
    FriendService? friends,
    ProfileService? profiles,
    PostService? posts,
  }) : friends = friends ?? FriendService(),
       _profiles = profiles ?? ProfileService(),
       _posts = posts ?? PostService();

  /// Whose profile this is.
  final String userId;
  final FriendService friends;
  final ProfileService _profiles;
  final PostService _posts;

  bool get isMe => userId == AppAuth.instance.currentUser?.uid;

  late final Stream<Map<String, dynamic>> profile = _profiles.watch(userId);
  late final Stream<bool> isFollowing = friends.isFollowing(userId);
  late final Stream<bool> hasPendingRequest = friends.hasPendingRequest(userId);
  late final Stream<int> followersCount = friends.getFollowersCount(userId);
  late final Stream<int> followingCount = friends.getFollowingCount(userId);

  /// The person's public looks, as they change.
  late final Stream<List<Post>> publicPosts = supabase
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

  /// Follow, cancel the request, or unfollow, whichever applies.
  void toggleFollow({required bool following, required bool requested}) {
    if (following) {
      friends.unfollowUser(userId);
    } else if (requested) {
      friends.cancelFollowRequest(userId);
    } else {
      friends.sendFollowRequest(userId);
    }
  }

  Future<void> signOut() => AuthService().signOut();

  void openBodyProfile() => Get.toNamed<void>(AppRoutes.bodyProfile);

  void openSearch() => Get.toNamed<void>(AppRoutes.search);

  /// From the bottom bar of a pushed profile: back to a main tab.
  void openMainTab(int index) {
    MainController.selectTab(MainTab.fromIndex(index));
    Get.until((route) => route.isFirst);
  }

  /// The owner sees what their look received; anyone else affirms it.
  Future<void> openAffirmations(
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
    if (!sent) return;
    AppToast.say('Affirmation sent.');
  }

  Future<void> tryOnPost(BuildContext context, Post post) async {
    if (AppAuth.instance.currentUser == null) {
      AppToast.say('Please sign in first.');
      return;
    }

    var loadingVisible = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final products = await _posts.getPostOutfitProducts(post);
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

      await _posts.notifyPostTryOn(post);
      if (!context.mounted) return;

      await Get.toNamed<void>(
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
      AppToast.say('Unable to load outfit: $error');
    }
  }
}
