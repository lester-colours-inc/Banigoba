// Handles creation and retrieval of social posts, affirmations, and comments.
//
// Posts carry no like or reaction counter. Qualitative affirmations are stored
// separately by AffirmationService so no aggregate lands on the post document
// and no public total can be derived from it.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/affirmation.dart';
import '../models/post.dart';
import 'affirmation_service.dart';
import 'notification_service.dart';

/// Thrown when a post is created without a signed-in user.
class SignInRequiredException implements Exception {
  const SignInRequiredException();

  String get message => 'Sign in to save your look.';

  @override
  String toString() => message;
}

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AffirmationService _affirmations = AffirmationService();

  String get _currentUserId => _auth.currentUser?.uid ?? '';

  /// Creates a new post, private unless [visibility] says otherwise.
  ///
  /// Throws [SignInRequiredException] when nobody is signed in, so callers can
  /// tell the user rather than silently losing the look.
  Future<String> createPost({
    required String caption,
    required String imageURL,
    String? outfitId,
    List<Map<String, dynamic>> products = const [],
    PostVisibility visibility = PostVisibility.private,
    PostKind kind = PostKind.look,
  }) async {
    if (_currentUserId.isEmpty) {
      throw const SignInRequiredException();
    }

    final ref = await _db.collection('posts').add({
      'authorID': _currentUserId,
      'authorId': _currentUserId,
      'caption': caption,
      'commentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'imageURL': imageURL,
      'isPublic': visibility == PostVisibility.public,
      'visibility': visibility.value,
      if (kind == PostKind.dressUp) 'kind': kind.value,
      if (visibility != PostVisibility.private)
        'publishedAt': FieldValue.serverTimestamp(),
      if (outfitId?.isNotEmpty == true) 'outfitId': outfitId,
      if (products.isNotEmpty) ...{
        'products': products,
        'productIds': products
            .map((product) => (product['id'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toList(),
      },
    });
    return ref.id;
  }

  /// Replaces the picture of one of the user's own posts with an edited
  /// version of the look.
  Future<void> updatePostImage(String postId, String imageURL) async {
    if (_currentUserId.isEmpty) {
      throw const SignInRequiredException();
    }
    final ref = _db.collection('posts').doc(postId);
    final snapshot = await ref.get();
    final data = snapshot.data();
    if (!snapshot.exists ||
        (data?['authorId'] ?? data?['authorID']) != _currentUserId) {
      throw Exception('You can only edit your own look.');
    }
    await ref.update({
      'imageURL': imageURL,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> makePostPublic(String postId) =>
      _setVisibility(postId, PostVisibility.public, action: 'share');

  /// Shares a private post with friends only: it never appears in Community
  /// or on the author's public profile grid.
  Future<void> shareWithFriends(String postId) =>
      _setVisibility(postId, PostVisibility.friends, action: 'share');

  /// Shares one of the user's own posts with [audience].
  Future<void> sharePost(String postId, PostVisibility audience) {
    if (audience == PostVisibility.private) return makePostPrivate(postId);
    return _setVisibility(postId, audience, action: 'share');
  }

  /// Reposts [original] to [audience] as a new post by the current user.
  ///
  /// With [quote] it is a quote: the user's words above the original look.
  /// A repost of a repost points at the first post, so chains stay flat.
  Future<String> repost(
    Post original, {
    String quote = '',
    PostVisibility audience = PostVisibility.public,
  }) async {
    if (_currentUserId.isEmpty) throw const SignInRequiredException();
    final sourceId = original.isRepost ? original.repostOfId : original.id;
    final sourceAuthorId = original.isRepost
        ? original.repostOfAuthorId
        : original.authorId;
    final ref = await _db.collection('posts').add({
      'authorID': _currentUserId,
      'authorId': _currentUserId,
      'caption': original.caption,
      'commentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'publishedAt': FieldValue.serverTimestamp(),
      'imageURL': original.imageURL,
      'isPublic': audience == PostVisibility.public,
      'visibility': audience.value,
      'repostOfId': sourceId,
      'repostOfAuthorId': sourceAuthorId,
      if (quote.trim().isNotEmpty) 'quoteText': quote.trim(),
      if (original.products.isNotEmpty) 'products': original.products,
      if (original.productIds.isNotEmpty) 'productIds': original.productIds,
    });
    await _notifyPostAuthor(
      postData: {'authorId': sourceAuthorId},
      postId: sourceId,
      type: quote.trim().isEmpty ? 'repost' : 'quote',
      body: quote.trim().isEmpty
          ? 'reposted your look.'
          : 'quoted your look: "${quote.trim()}"',
    );
    return ref.id;
  }

  Future<void> makePostPrivate(String postId) async {
    if (_currentUserId.isEmpty) return;
    final ref = _db.collection('posts').doc(postId);
    final snapshot = await ref.get();
    if (!snapshot.exists ||
        (snapshot.data()?['authorId'] ?? snapshot.data()?['authorID']) !=
            _currentUserId) {
      throw Exception('You can only private your own post.');
    }
    await ref.update({
      'isPublic': false,
      'visibility': PostVisibility.private.value,
      'privatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _setVisibility(
    String postId,
    PostVisibility visibility, {
    required String action,
  }) async {
    if (_currentUserId.isEmpty) return;
    final ref = _db.collection('posts').doc(postId);
    final snapshot = await ref.get();
    if (!snapshot.exists ||
        (snapshot.data()?['authorId'] ?? snapshot.data()?['authorID']) !=
            _currentUserId) {
      throw Exception('You can only $action your own post.');
    }
    await ref.update({
      'isPublic': visibility == PostVisibility.public,
      'visibility': visibility.value,
      'publishedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost(String postId) async {
    if (_currentUserId.isEmpty) return;
    final postRef = _db.collection('posts').doc(postId);
    final snapshot = await postRef.get();
    final data = snapshot.data();
    if (!snapshot.exists ||
        (data?['authorId'] ?? data?['authorID']) != _currentUserId) {
      throw Exception('You can only delete your own post.');
    }

    final comments = await postRef.collection('comments').get();
    // Legacy subcollection from the removed like implementation. Still cleaned
    // up on delete so old documents do not leave orphans behind.
    final legacyLikes = await postRef.collection('likes').get();
    final outfitId = (data?['outfitId'] ?? '').toString();
    final outfitRef = outfitId.isEmpty
        ? null
        : _db
              .collection('users')
              .doc(_currentUserId)
              .collection('outfits')
              .doc(outfitId);
    final outfitSnapshot = outfitRef == null ? null : await outfitRef.get();

    final batch = _db.batch();
    for (final comment in comments.docs) {
      batch.delete(comment.reference);
    }
    for (final like in legacyLikes.docs) {
      batch.delete(like.reference);
    }
    if (outfitRef != null && outfitSnapshot?.exists == true) {
      batch.update(outfitRef, {
        'dailyDressUpPostId': FieldValue.delete(),
        'deletedDailyDressUpPostId': postId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    batch.delete(postRef);
    await batch.commit();

    // Affirmations must not outlive the look they were about.
    await _affirmations.deleteAllForTarget(
      targetType: AffirmationTargetType.post,
      targetId: postId,
    );
  }

  /// Resolves the garments used by a Daily Dress Up post.
  Future<List<Map<String, dynamic>>> getPostOutfitProducts(Post post) async {
    if (post.products.isNotEmpty) return post.products;

    if (post.outfitId.isNotEmpty && post.authorId.isNotEmpty) {
      final outfit = await _db
          .collection('users')
          .doc(post.authorId)
          .collection('outfits')
          .doc(post.outfitId)
          .get();
      final products = _embeddedProducts(outfit.data()?['products']);
      if (products.isNotEmpty) return products;
    }

    if (post.productIds.isNotEmpty) {
      final products = <Map<String, dynamic>>[];
      for (final productId in post.productIds) {
        final product = await _db.collection('products').doc(productId).get();
        if (product.exists && product.data() != null) {
          products.add({...product.data()!, 'id': product.id});
        }
      }
      if (products.isNotEmpty) return products;
    }

    if (post.authorId.isNotEmpty && post.imageURL.isNotEmpty) {
      final outfits = await _db
          .collection('users')
          .doc(post.authorId)
          .collection('outfits')
          .where('imageUrl', isEqualTo: post.imageURL)
          .limit(1)
          .get();
      if (outfits.docs.isNotEmpty) {
        return _embeddedProducts(outfits.docs.first.data()['products']);
      }
    }

    return const [];
  }

  List<Map<String, dynamic>> _embeddedProducts(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map>()
        .map((product) => Map<String, dynamic>.from(product))
        .toList();
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
      final post = await transaction.get(postRef);
      if (post.data()?['isPublic'] != true) {
        throw Exception('Private posts cannot be commented on.');
      }
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

    final post = await postRef.get();
    await _notifyPostAuthor(
      postData: post.data(),
      postId: postId,
      type: 'comment',
      body: 'commented on your Daily Dress Up.',
    );
  }

  Future<void> notifyPostTryOn(Post post) async {
    if (_currentUserId.isEmpty || post.authorId == _currentUserId) return;

    await _notifyPostAuthor(
      postData: {'authorId': post.authorId},
      postId: post.id,
      type: 'try_on',
      body: 'tried on your Daily Dress Up.',
    );
  }

  Future<void> _notifyPostAuthor({
    required Map<String, dynamic>? postData,
    required String postId,
    required String type,
    required String body,
  }) async {
    final authorId = (postData?['authorId'] ?? postData?['authorID'] ?? '')
        .toString();
    if (authorId.isEmpty || authorId == _currentUserId) return;

    try {
      final user = await _db.collection('users').doc(_currentUserId).get();
      final userData = user.data();
      final senderName =
          (userData?['displayName'] ??
                  _auth.currentUser?.displayName ??
                  _auth.currentUser?.email?.split('@').first ??
                  'Someone')
              .toString();

      await NotificationService().addNotification(
        receiverId: authorId,
        title: switch (type) {
          'comment' => 'New Comment',
          'try_on' => 'Look Tried On',
          'repost' => 'Look Reposted',
          'quote' => 'Look Quoted',
          _ => 'Daily Dress Up',
        },
        body: '$senderName $body',
        type: type,
        extraData: {
          'fromId': _currentUserId,
          'fromName': senderName,
          'postId': postId,
        },
      );
    } catch (error) {
      debugPrint('Unable to create $type notification: $error');
    }
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
