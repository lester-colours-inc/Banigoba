import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  Future<void> followUser(String targetUserId) async {
    if (currentUserId.isEmpty) return;
    
    final batch = _firestore.batch();
    
    // Add to my following
    final followingRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId);
    batch.set(followingRef, {'timestamp': FieldValue.serverTimestamp()});
    
    // Add to target's followers
    final followerRef = _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId);
    batch.set(followerRef, {'timestamp': FieldValue.serverTimestamp()});
    
    await batch.commit();
  }

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
}
