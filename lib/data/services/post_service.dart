// Handles creation and retrieval of social posts, likes, and comments in Firestore.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post.dart';

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? '';

  /// Creates a new post
  Future<void> createPost({
    required String caption,
    required String imageURL,
  }) async {
    if (_currentUserId.isEmpty) return;

    await _db.collection('posts').add({
      'authorID': _currentUserId,
      'authorId': _currentUserId,
      'caption': caption,
      'commentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'imageURL': imageURL,
      'likeCount': 0,
      'likedBy': [],
      'likes': [],
    });
  }

  /// Gets a stream of posts
  Stream<List<Post>> getPosts() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList(),
        );
  }

  /// Likes or unlikes a post
  Future<void> toggleLike(String postId, List<String> currentLikes) async {
    if (_currentUserId.isEmpty) return;

    final postRef = _db.collection('posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(_currentUserId);

    if (currentLikes.contains(_currentUserId)) {
      // Unlike
      await postRef.update({
        'likedBy': FieldValue.arrayRemove([_currentUserId]),
        'likes': FieldValue.arrayRemove([_currentUserId]),
        'likeCount': FieldValue.increment(-1),
      });
      await likeRef.delete();
    } else {
      // Like
      await postRef.update({
        'likedBy': FieldValue.arrayUnion([_currentUserId]),
        'likes': FieldValue.arrayUnion([_currentUserId]),
        'likeCount': FieldValue.increment(1),
      });
      await likeRef.set({'userId': _currentUserId});
    }
  }

  /// Adds a comment to a post
  Future<void> addComment({
    required String postId,
    required String text,
    required String username,
    required String profileImageURL,
  }) async {
    if (_currentUserId.isEmpty) return;

    final postRef = _db.collection('posts').doc(postId);

    await _db.runTransaction((transaction) async {
      // Add comment to subcollection
      final commentRef = postRef.collection('comments').doc();
      transaction.set(commentRef, {
        'authorId': _currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'profileImageURL': profileImageURL,
        'text': text,
        'username': username,
      });

      // Update comment count on post
      transaction.update(postRef, {'commentCount': FieldValue.increment(1)});
    });
  }

  /// Gets a stream of comments for a specific post
  Stream<List<PostComment>> getComments(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PostComment.fromFirestore(doc))
              .toList(),
        );
  }
}
