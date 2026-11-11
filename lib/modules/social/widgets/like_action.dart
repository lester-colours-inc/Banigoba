// The heart on a look card, with how many people liked the look.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/social/services/like_service.dart';
import 'package:banigoba/modules/social/widgets/dress_up_post_card.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

/// Rebuilds [builder] whenever the signed-in person's likes change, so every
/// card's heart stays in step.
class LikesBuilder extends StatelessWidget {
  const LikesBuilder({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Set<String>>(
    valueListenable: LikeService.instance.likedPostIds,
    builder: (context, _, _) => builder(context),
  );
}

/// The like action for the look [postId]: an outlined heart, filled once
/// liked, with the like count beside it. [likeCount] is the count the feed
/// loaded; taps since are added in.
DressUpCardAction likeCardAction(
  BuildContext context,
  String postId, {
  int likeCount = 0,
}) {
  final likes = LikeService.instance;
  final isLiked = likes.isLiked(postId);
  final count = likes.displayCount(postId, likeCount);
  return DressUpCardAction(
    icon: Icons.favorite_border,
    activeIcon: Icons.favorite,
    isActive: isLiked,
    label: '${isLiked ? 'Unlike' : 'Like'} · ${likeCountLabel(count)}',
    countLabel: count > 0 ? compactCount(count) : null,
    onTap: () => _toggle(context, postId, likeCount),
  );
}

/// "1 like", "12 likes".
String likeCountLabel(int count) => count == 1 ? '1 like' : '$count likes';

/// A short number for the action row: 999, 1.2K, 3.4M.
String compactCount(int count) {
  if (count < 1000) return '$count';
  if (count < 1000000) return _short(count / 1000, 'K');
  return _short(count / 1000000, 'M');
}

String _short(double value, String unit) {
  // Rounded down, so a look never shows more likes than it has.
  if (value >= 10) return '${value.floor()}$unit';
  final tenths = (value * 10).floor();
  final text = tenths % 10 == 0 ? '${tenths ~/ 10}' : '${tenths / 10}';
  return '$text$unit';
}

Future<void> _toggle(BuildContext context, String postId, int likeCount) async {
  try {
    await LikeService.instance.toggle(postId, serverCount: likeCount);
  } on LikeSignInRequiredException catch (error) {
    AppToast.say(error.message);
  } on Exception catch (error) {
    debugPrint('Unable to like look $postId: $error');
    AppToast.say('Unable to like this look. Try again.');
  }
}
