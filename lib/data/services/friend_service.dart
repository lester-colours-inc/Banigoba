// Manages follows, follow requests, and related social notifications in Firestore.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  String get currentUserId => _auth.currentUser?.uid ?? '';

  // --- Follow Request Actions ---

  Future<void> sendFollowRequest(String targetUserId) async {
    if (currentUserId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('follow_requests')
        .doc(currentUserId)
        .set({
      'from': currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    // Fetch current user's name from Firestore for the notification
    final userDoc = await _firestore.collection('users').doc(currentUserId).get();
    final userData = userDoc.data() as Map<String, dynamic>?;
    final senderName = userData?['displayName'] ?? _auth.currentUser?.email?.split('@')[0] ?? 'Someone';

    await _notificationService.addNotification(
      receiverId: targetUserId,
      title: 'New Follow Request',
      body: '$senderName wants to follow you.',
      type: 'follow_request',
      extraData: {
        'fromId': currentUserId,
        'fromName': senderName,
      },
    );
  }

  Future<void> cancelFollowRequest(String targetUserId) async {
    if (currentUserId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('follow_requests')
        .doc(currentUserId)
        .delete();
  }

  Future<void> acceptFollowRequest(String requesterId) async {
    if (currentUserId.isEmpty) return;

    final batch = _firestore.batch();

    // 1. Add to requester's following
    final followingRef = _firestore
        .collection('users')
        .doc(requesterId)
        .collection('following')
        .doc(currentUserId);
    batch.set(followingRef, {'timestamp': FieldValue.serverTimestamp()});

    // 2. Add to my followers
    final followerRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('followers')
        .doc(requesterId);
    batch.set(followerRef, {'timestamp': FieldValue.serverTimestamp()});

    // 3. Delete the request
    final requestRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('follow_requests')
        .doc(requesterId);
    batch.delete(requestRef);

    await batch.commit();

    // Fetch current user's name from Firestore for the notification
    final userDoc = await _firestore.collection('users').doc(currentUserId).get();
    final userData = userDoc.data() as Map<String, dynamic>?;
    final myName = userData?['displayName'] ?? _auth.currentUser?.email?.split('@')[0] ?? 'Your friend';

    await _notificationService.addNotification(
      receiverId: requesterId,
      title: 'Follow Request Accepted',
      body: '$myName accepted your follow request.',
      type: 'follow_accepted',
      extraData: {
        'fromId': currentUserId,
        'fromName': myName,
      },
    );
  }

  Future<void> declineFollowRequest(String requesterId) async {
    if (currentUserId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('follow_requests')
        .doc(requesterId)
        .delete();
  }

  // --- Follow/Unfollow Actions (Already Following) ---

  Future<void> unfollowUser(String targetUserId) async {
    if (currentUserId.isEmpty) return;

    final batch = _firestore.batch();

    final followingRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId);
    batch.delete(followingRef);

    final followerRef = _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId);
    batch.delete(followerRef);

    await batch.commit();
  }

  // --- Streams ---

  Stream<bool> isFollowing(String targetUserId) {
    if (currentUserId.isEmpty) return Stream.value(false);
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Stream<bool> hasPendingRequest(String targetUserId) {
    if (currentUserId.isEmpty) return Stream.value(false);
    return _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('follow_requests')
        .doc(currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Stream<QuerySnapshot> getIncomingRequests() {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('follow_requests')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getAllUsers() {
    return _firestore
        .collection('users')
        .where('uid', isNotEqualTo: currentUserId)
        .snapshots();
  }

  Stream<int> getFollowersCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('followers')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getFollowingCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getRequestsCount() {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('follow_requests')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<String>> getMutualFriendsIds() {
    if (currentUserId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .snapshots()
        .asyncMap((followingSnap) async {
      final followingIds = followingSnap.docs.map((doc) => doc.id).toList();
      if (followingIds.isEmpty) return [];

      // Check each followed user to see if they follow current user back
      final mutualIds = <String>[];
      for (final id in followingIds) {
        final doc = await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('followers')
            .doc(id)
            .get();
        if (doc.exists) {
          mutualIds.add(id);
        }
      }
      return mutualIds;
    });
  }
}
