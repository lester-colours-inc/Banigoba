// Creates and reads user-facing notifications stored in Cloud Firestore.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  Future<void> addNotification({
    required String receiverId,
    required String title,
    required String body,
    required String type, // 'follow_request', 'follow_accepted', 'new_post'
    Map<String, dynamic>? extraData,
  }) async {
    if (receiverId == currentUserId && type != 'new_post') return; // Don't notify self unless it's a post logic helper

    await _db.collection('users').doc(receiverId).collection('notifications').add({
      'title': title,
      'body': body,
      'type': type,
      'senderId': currentUserId,
      'extraData': extraData,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getNotifications({String category = 'all'}) {
    // We always order by timestamp
    Query query = _db.collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .orderBy('timestamp', descending: true);

    // If 'all', return the full stream
    if (category == 'all') {
      return query.snapshots();
    }

    // For specific categories, we filter by 'type'
    // Note: 'whereIn' combined with 'orderBy' on a different field requires a composite index.
    // To ensure the UI isn't empty due to a missing index, we can filter client-side or 
    // simply define the allowed types.
    List<String> allowedTypes = [];
    if (category == 'friends') {
      allowedTypes = ['follow_request', 'follow_accepted', 'new_post', 'like', 'comment'];
    } else if (category == 'shops') {
      allowedTypes = ['order_update', 'shop_promo', 'shop_new_item'];
    } else if (category == 'designers') {
      allowedTypes = ['designer_update', 'designer_collection'];
    }

    // Return the stream, and the UI will filter the documents if needed
    // or we can use the Firestore where clause if the index exists.
    // For now, let's use the where clause but add a check.
    if (allowedTypes.isNotEmpty) {
      return _db.collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .where('type', whereIn: allowedTypes)
          .orderBy('timestamp', descending: true)
          .snapshots();
    }

    return query.snapshots();
  }

  Stream<int> getUnreadCount() {
    return _db.collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markAsRead(String notificationId) async {
    await _db.collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead() async {
    final unread = await _db.collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    
    final batch = _db.batch();
    for (var doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> updateNotification({
    required String notificationId,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .doc(notificationId)
        .update(data);
  }

  // Helper to notify all followers about a new post
  Future<void> notifyFollowersNewPost(String itemName) async {
    final followers = await _db.collection('users').doc(currentUserId).collection('followers').get();
    
    // Fetch current user's name from Firestore
    final userDoc = await _db.collection('users').doc(currentUserId).get();
    final userData = userDoc.data() as Map<String, dynamic>?;
    final userName = userData?['displayName'] ?? _auth.currentUser?.email?.split('@')[0] ?? 'Your friend';
    
    for (var doc in followers.docs) {
      await addNotification(
        receiverId: doc.id,
        title: 'New Post!',
        body: '$userName just added a new item: $itemName',
        type: 'new_post',
        extraData: {
          'userId': currentUserId,
          'fromName': userName,
        },
      );
    }
  }
}
