// Handles creation and retrieval of social posts, affirmations, and comments.
//
// Posts carry a like count (kept by the database from post_likes) but no
// affirmation total: affirmations are stored separately by AffirmationService
// so no affirmation aggregate lands on the post and none can be derived.
import 'package:flutter/foundation.dart';
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/core/supabase/supabase_config.dart';
import 'package:banigoba/modules/social/models/affirmation.dart';
import 'package:banigoba/modules/social/models/post.dart';
import 'package:banigoba/core/utils/text_moderation.dart';
import 'package:banigoba/core/supabase/rows.dart';
import 'package:banigoba/modules/social/services/affirmation_service.dart';
import 'package:banigoba/modules/notifications/services/notification_service.dart';

/// Thrown when a post is created without a signed-in user.
class SignInRequiredException implements Exception {
  const SignInRequiredException();

  String get message => 'Sign in to save your look.';

  @override
  String toString() => message;
}

class PostService {
  final AffirmationService _affirmations = AffirmationService();

  String get _currentUserId => AppAuth.instance.currentUser?.uid ?? '';

  /// One post, or null if it does not exist or the viewer may not see it.
  Future<Post?> getPost(String postId) async {
    final row = await supabase
        .from('posts')
        .select()
        .eq('id', postId)
        .maybeSingle();
    return row == null ? null : Post.fromRow(row);
  }

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

    final row = await supabase
        .from('posts')
        .insert({
          'author_id': _currentUserId,
          'caption': caption,
          'image_url': imageURL,
          'visibility': visibility.value,
          'kind': kind.value,
          if (visibility != PostVisibility.private)
            'published_at': DateTime.now().toUtc().toIso8601String(),
          if (outfitId?.isNotEmpty == true) 'outfit_id': outfitId,
          if (products.isNotEmpty) ...{
            'products': products,
            'product_ids': products
                .map((product) => (product['id'] ?? '').toString())
                .where((id) => id.isNotEmpty)
                .toList(),
          },
        })
        .select('id')
        .single();
    return row['id'].toString();
  }

  /// Replaces the picture of one of the user's own posts with an edited
  /// version of the look.
  Future<void> updatePostImage(String postId, String imageURL) async {
    if (_currentUserId.isEmpty) {
      throw const SignInRequiredException();
    }
    final updated = await supabase
        .from('posts')
        .update({'image_url': imageURL})
        .eq('id', postId)
        .eq('author_id', _currentUserId)
        .select('id');
    if (updated.isEmpty) throw Exception('You can only edit your own look.');
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
    final row = await supabase
        .from('posts')
        .insert({
          'author_id': _currentUserId,
          'caption': original.caption,
          'image_url': original.imageURL,
          'visibility': audience.value,
          'published_at': DateTime.now().toUtc().toIso8601String(),
          'repost_of_id': sourceId,
          'repost_of_author_id': sourceAuthorId,
          'quote_text': quote.trim(),
          if (original.products.isNotEmpty) 'products': original.products,
          if (original.productIds.isNotEmpty)
            'product_ids': original.productIds,
        })
        .select('id')
        .single();
    await _notifyPostAuthor(
      authorId: sourceAuthorId,
      postId: sourceId,
      type: quote.trim().isEmpty ? 'repost' : 'quote',
      body: quote.trim().isEmpty
          ? 'reposted your look.'
          : 'quoted your look: "${quote.trim()}"',
    );
    return row['id'].toString();
  }

  Future<void> makePostPrivate(String postId) async {
    if (_currentUserId.isEmpty) return;
    final updated = await supabase
        .from('posts')
        .update({'visibility': PostVisibility.private.value})
        .eq('id', postId)
        .eq('author_id', _currentUserId)
        .select('id');
    if (updated.isEmpty) throw Exception('You can only private your own post.');
  }

  Future<void> _setVisibility(
    String postId,
    PostVisibility visibility, {
    required String action,
  }) async {
    if (_currentUserId.isEmpty) return;
    final updated = await supabase
        .from('posts')
        .update({
          'visibility': visibility.value,
          'published_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', postId)
        .eq('author_id', _currentUserId)
        .select('id');
    if (updated.isEmpty) throw Exception('You can only $action your own post.');
  }

  Future<void> deletePost(String postId) async {
    if (_currentUserId.isEmpty) return;
    final post = await supabase
        .from('posts')
        .select('author_id, outfit_id')
        .eq('id', postId)
        .maybeSingle();
    if (post == null || post['author_id'] != _currentUserId) {
      throw Exception('You can only delete your own post.');
    }

    final outfitId = (post['outfit_id'] ?? '').toString();
    if (outfitId.isNotEmpty) {
      await _unlinkOutfit(outfitId, postId);
    }
    await supabase
        .from('comments')
        .delete()
        .eq('target_type', 'post')
        .eq('target_id', postId);
    await supabase.from('posts').delete().eq('id', postId);

    // Affirmations must not outlive the look they were about.
    await _affirmations.deleteAllForTarget(
      targetType: AffirmationTargetType.post,
      targetId: postId,
    );
  }

  /// The saved look no longer points at a post that is gone.
  Future<void> _unlinkOutfit(String outfitId, String postId) async {
    final outfit = await supabase
        .from('outfits')
        .select('data')
        .eq('id', outfitId)
        .eq('user_id', _currentUserId)
        .maybeSingle();
    if (outfit == null) return;
    final data = Map<String, dynamic>.from(outfit['data'] as Map? ?? {})
      ..remove('dailyDressUpPostId')
      ..['deletedDailyDressUpPostId'] = postId;
    await supabase
        .from('outfits')
        .update({'data': data})
        .eq('id', outfitId)
        .eq('user_id', _currentUserId);
  }

  /// Resolves the garments used by a Daily Dress Up post.
  Future<List<Map<String, dynamic>>> getPostOutfitProducts(Post post) async {
    if (post.products.isNotEmpty) return post.products;

    if (post.outfitId.isNotEmpty && post.authorId.isNotEmpty) {
      final outfit = await supabase
          .from('outfits')
          .select('products')
          .eq('id', post.outfitId)
          .maybeSingle();
      final products = _embeddedProducts(outfit?['products']);
      if (products.isNotEmpty) return products;
    }

    if (post.productIds.isNotEmpty) {
      final rows = await supabase
          .from('products')
          .select()
          .inFilter('id', post.productIds);
      final products = [for (final row in rows) camelizeRow(row)];
      if (products.isNotEmpty) return products;
    }

    if (post.authorId.isNotEmpty && post.imageURL.isNotEmpty) {
      final outfits = await supabase
          .from('outfits')
          .select('products')
          .eq('user_id', post.authorId)
          .eq('image_url', post.imageURL)
          .limit(1);
      if (outfits.isNotEmpty) {
        return _embeddedProducts(outfits.first['products']);
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

  /// Adds a comment to a post. Comments need a post someone else can see.
  Future<void> addComment({
    required String postId,
    required String text,
    required String username,
    required String profileImageURL,
  }) async {
    if (_currentUserId.isEmpty) return;

    // Kind words only: harassment, body shaming and spam stop here.
    final moderated = moderateText(text);
    if (!moderated.isAllowed) throw ModerationException(moderated.reason!);
    text = moderated.text;

    final post = await getPost(postId);
    if (post == null || !post.isShared) {
      throw Exception('Private posts cannot be commented on.');
    }
    await supabase.from('comments').insert({
      'target_type': 'post',
      'target_id': postId,
      'author_id': _currentUserId,
      'author_name': username,
      'author_image_url': profileImageURL,
      'text': text,
    });

    await _notifyPostAuthor(
      authorId: post.authorId,
      postId: postId,
      type: 'comment',
      body: 'commented on your Daily Dress Up.',
    );
  }

  Future<void> notifyPostTryOn(Post post) async {
    if (_currentUserId.isEmpty || post.authorId == _currentUserId) return;

    await _notifyPostAuthor(
      authorId: post.authorId,
      postId: post.id,
      type: 'try_on',
      body: 'tried on your Daily Dress Up.',
    );
  }

  Future<void> _notifyPostAuthor({
    required String authorId,
    required String postId,
    required String type,
    required String body,
  }) async {
    if (authorId.isEmpty || authorId == _currentUserId) return;

    try {
      final me = await supabase
          .from('profiles')
          .select('display_name')
          .eq('id', _currentUserId)
          .maybeSingle();
      final senderName = (me?['display_name'] ?? '').toString().isNotEmpty
          ? me!['display_name'].toString()
          : (AppAuth.instance.currentUser?.displayName ??
                AppAuth.instance.currentUser?.email?.split('@').first ??
                'Someone');

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
    } on Exception catch (error) {
      debugPrint('Unable to create $type notification: $error');
    }
  }

  /// Removes a comment: its author, or the owner of the look, may.
  Future<void> deleteComment(String commentId) async {
    await supabase.from('comments').delete().eq('id', commentId);
  }

  /// Reports a comment as unkind. Three different people reporting it hides
  /// it from everyone but its author, the look's owner and curators.
  Future<void> reportComment(String commentId, {String reason = ''}) async {
    if (_currentUserId.isEmpty) throw const SignInRequiredException();
    await supabase.from('comment_reports').upsert({
      'comment_id': commentId,
      'reporter_id': _currentUserId,
      'reason': reason,
    });
  }

  /// Gets a stream of comments for a specific post, newest first.
  Stream<List<PostComment>> getComments(String postId) {
    return supabase
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('target_id', postId)
        .order('created_at', ascending: false)
        .map(
          (rows) => [
            for (final row in rows)
              if (row['target_type'] == 'post') PostComment.fromRow(row),
          ],
        );
  }
}
