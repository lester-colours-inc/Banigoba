// Likes on looks: the signed-in person's heart and the look's like count.
// Who liked stays private; the count is kept on the post by the database.
// See supabase/migrations/20261111000001_post_likes.sql and
// 20261111000003_post_like_count.sql.
import 'package:flutter/foundation.dart';

import 'package:banigoba/core/supabase/supabase_config.dart';

/// Thrown when someone who is not signed in taps a heart.
class LikeSignInRequiredException implements Exception {
  const LikeSignInRequiredException();

  String get message => 'Sign in to like looks.';

  @override
  String toString() => message;
}

class LikeService {
  LikeService._();
  static final LikeService instance = LikeService._();

  /// Looks the signed-in person has liked. Screens read it straight away and
  /// it changes the moment a heart is tapped.
  final ValueNotifier<Set<String>> likedPostIds = ValueNotifier(const {});

  /// Taps not yet reflected in the count the feed loaded: the count seen at
  /// the first tap, and the change since.
  final Map<String, ({int base, int delta})> _pending = {};

  String? get _me => supabase.auth.currentUser?.id;

  /// The count to show for [postId], given the [serverCount] the feed loaded.
  /// Includes taps made since, until the feed's count catches up.
  int displayCount(String postId, int serverCount) {
    final pending = _pending[postId];
    if (pending == null || pending.base != serverCount) return serverCount;
    final shown = pending.base + pending.delta;
    return shown < 0 ? 0 : shown;
  }

  bool isLiked(String postId) => likedPostIds.value.contains(postId);

  Future<void> loadLiked() async {
    final me = _me;
    if (me == null) return;
    final rows = await supabase
        .from('post_likes')
        .select('post_id')
        .eq('user_id', me);
    likedPostIds.value = {for (final row in rows) row['post_id'].toString()};
  }

  /// Likes or unlikes [postId]. The heart flips at once and flips back if the
  /// database refuses, rethrowing so the screen can say so.
  ///
  /// [serverCount] is the count the feed shows for the look, so the number
  /// moves with the heart.
  Future<void> toggle(String postId, {int serverCount = 0}) async {
    final me = _me;
    if (me == null) throw const LikeSignInRequiredException();
    final wasLiked = isLiked(postId);
    final before = likedPostIds.value;
    final pendingBefore = _pending[postId];
    _pending[postId] = _nextPending(pendingBefore, serverCount, wasLiked);
    likedPostIds.value = wasLiked
        ? ({...before}..remove(postId))
        : {...before, postId};
    try {
      if (wasLiked) {
        await supabase
            .from('post_likes')
            .delete()
            .eq('user_id', me)
            .eq('post_id', postId);
      } else {
        await supabase.from('post_likes').upsert({
          'user_id': me,
          'post_id': postId,
        });
      }
    } catch (_) {
      _restorePending(postId, pendingBefore);
      likedPostIds.value = before;
      rethrow;
    }
  }

  ({int base, int delta}) _nextPending(
    ({int base, int delta})? pending,
    int serverCount,
    bool wasLiked,
  ) {
    final step = wasLiked ? -1 : 1;
    if (pending == null || pending.base != serverCount) {
      return (base: serverCount, delta: step);
    }
    return (base: pending.base, delta: pending.delta + step);
  }

  void _restorePending(String postId, ({int base, int delta})? pending) {
    if (pending == null) {
      _pending.remove(postId);
    } else {
      _pending[postId] = pending;
    }
  }
}
