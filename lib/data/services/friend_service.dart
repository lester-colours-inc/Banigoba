// Manages follows, follow requests, and related social notifications.
//
// A follow is one row in `follows` (follower → followee); friends are people
// who follow each other. A request waits in `follow_requests` until the other
// person accepts it, which the database does in one step.
import 'package:flutter/foundation.dart';

import '../../core/supabase/app_auth.dart';
import '../../core/supabase/supabase_config.dart';
import 'notification_service.dart';

class FriendService {
  final NotificationService _notificationService = NotificationService();

  String get currentUserId => AppAuth.instance.currentUser?.uid ?? '';

  Future<String> _nameOf(String userId, String fallback) async {
    final row = await supabase
        .from('profiles')
        .select('display_name')
        .eq('id', userId)
        .maybeSingle();
    final name = (row?['display_name'] ?? '').toString();
    if (name.isNotEmpty) return name;
    return AppAuth.instance.currentUser?.email?.split('@')[0] ?? fallback;
  }

  // --- Follow Request Actions ---

  Future<void> sendFollowRequest(String targetUserId) async {
    if (currentUserId.isEmpty) return;
    await supabase.from('follow_requests').upsert({
      'requester_id': currentUserId,
      'target_id': targetUserId,
    });

    final senderName = await _nameOf(currentUserId, 'Someone');
    await _notificationService.addNotification(
      receiverId: targetUserId,
      title: 'New Follow Request',
      body: '$senderName wants to follow you.',
      type: 'follow_request',
      extraData: {'fromId': currentUserId, 'fromName': senderName},
    );
  }

  Future<void> cancelFollowRequest(String targetUserId) async {
    if (currentUserId.isEmpty) return;
    await supabase
        .from('follow_requests')
        .delete()
        .eq('requester_id', currentUserId)
        .eq('target_id', targetUserId);
  }

  Future<void> acceptFollowRequest(String requesterId) async {
    if (currentUserId.isEmpty) return;
    await supabase.rpc(
      'accept_follow_request',
      params: {'requester': requesterId},
    );

    final myName = await _nameOf(currentUserId, 'Your friend');
    await _notificationService.addNotification(
      receiverId: requesterId,
      title: 'Follow Request Accepted',
      body: '$myName accepted your follow request.',
      type: 'follow_accepted',
      extraData: {'fromId': currentUserId, 'fromName': myName},
    );
  }

  Future<void> declineFollowRequest(String requesterId) async {
    if (currentUserId.isEmpty) return;
    await supabase
        .from('follow_requests')
        .delete()
        .eq('requester_id', requesterId)
        .eq('target_id', currentUserId);
  }

  // --- Follow/Unfollow Actions (Already Following) ---

  Future<void> unfollowUser(String targetUserId) async {
    if (currentUserId.isEmpty) return;
    await supabase
        .from('follows')
        .delete()
        .eq('follower_id', currentUserId)
        .eq('followee_id', targetUserId);
  }

  // --- Streams ---

  Stream<bool> isFollowing(String targetUserId) {
    if (currentUserId.isEmpty) return Stream.value(false);
    return supabase
        .from('follows')
        .stream(primaryKey: ['follower_id', 'followee_id'])
        .eq('follower_id', currentUserId)
        .map((rows) => rows.any((r) => r['followee_id'] == targetUserId));
  }

  Stream<bool> hasPendingRequest(String targetUserId) {
    if (currentUserId.isEmpty) return Stream.value(false);
    return supabase
        .from('follow_requests')
        .stream(primaryKey: ['requester_id', 'target_id'])
        .eq('requester_id', currentUserId)
        .map((rows) => rows.any((r) => r['target_id'] == targetUserId));
  }

  /// The people waiting for the current user to accept them, newest first.
  Stream<List<String>> getIncomingRequests() {
    if (currentUserId.isEmpty) return Stream.value(const []);
    return supabase
        .from('follow_requests')
        .stream(primaryKey: ['requester_id', 'target_id'])
        .eq('target_id', currentUserId)
        .order('created_at', ascending: false)
        .map((rows) => [for (final r in rows) r['requester_id'].toString()]);
  }

  Stream<int> getFollowersCount(String userId) {
    return supabase
        .from('follows')
        .stream(primaryKey: ['follower_id', 'followee_id'])
        .eq('followee_id', userId)
        .map((rows) => rows.length);
  }

  Stream<int> getFollowingCount(String userId) {
    return supabase
        .from('follows')
        .stream(primaryKey: ['follower_id', 'followee_id'])
        .eq('follower_id', userId)
        .map((rows) => rows.length);
  }

  /// The people who follow [userId] ('followers') or whom [userId] follows
  /// ('following').
  Stream<List<String>> listUserIds(String userId, String type) {
    final followers = type == 'followers';
    return supabase
        .from('follows')
        .stream(primaryKey: ['follower_id', 'followee_id'])
        .eq(followers ? 'followee_id' : 'follower_id', userId)
        .map(
          (rows) => [
            for (final r in rows)
              r[followers ? 'follower_id' : 'followee_id'].toString(),
          ],
        );
  }

  Stream<int> getRequestsCount() => getIncomingRequests().map((r) => r.length);

  /// Everyone the current user follows, mutual or not.
  Stream<List<String>> getFollowingIds() {
    if (currentUserId.isEmpty) return Stream.value([]);
    return supabase
        .from('follows')
        .stream(primaryKey: ['follower_id', 'followee_id'])
        .eq('follower_id', currentUserId)
        .map((rows) => [for (final r in rows) r['followee_id'].toString()]);
  }

  /// People the current user follows who follow them back.
  Stream<List<String>> getMutualFriendsIds() {
    if (currentUserId.isEmpty) return Stream.value([]);
    return getFollowingIds().asyncMap((following) async {
      if (following.isEmpty) return <String>[];
      try {
        final back = await supabase
            .from('follows')
            .select('follower_id')
            .eq('followee_id', currentUserId)
            .inFilter('follower_id', following);
        return [for (final r in back) r['follower_id'].toString()];
      } on Exception catch (error) {
        debugPrint('Unable to read friends: $error');
        return <String>[];
      }
    });
  }
}
