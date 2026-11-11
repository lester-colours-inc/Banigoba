// Defines social post and comment data read from the database.
//
// Posts intentionally expose no reaction count. Qualitative affirmations are a
// separate object (see models/affirmation.dart) and are never aggregated onto
// the post, so nothing here can be rendered as a popularity total.
import 'package:banigoba/core/supabase/rows.dart';

/// Who can see a post beyond its owner, narrowest first.
///
/// Friends are mutual follows; followers are everyone who follows the author
/// (friends included). Friends and followers shares appear in those people's
/// Community feed; a public share appears for everyone and on the author's
/// public profile grid.
enum PostVisibility {
  private('private', 'Only me'),
  friends('friends', 'Friends'),
  followers('followers', 'Followers'),
  public('public', 'Public');

  const PostVisibility(this.value, this.label);

  final String value;
  final String label;

  static PostVisibility fromValue(
    Object? value, {
    required bool legacyIsPublic,
  }) {
    for (final visibility in PostVisibility.values) {
      if (visibility.value == value) return visibility;
    }
    // Older documents only ever wrote the boolean.
    return legacyIsPublic ? PostVisibility.public : PostVisibility.private;
  }
}

/// What a post is. A daily dress-up is someone sharing what they are
/// wearing today; it shows in My Daily Dress Up, not in the makeover feeds
/// (October 2026 review, D-2).
enum PostKind {
  look('look'),
  dressUp('dressUp');

  const PostKind(this.value);

  final String value;

  static PostKind fromValue(Object? value) => PostKind.values.firstWhere(
    (kind) => kind.value == value,
    orElse: () => PostKind.look,
  );
}

class Post {
  final String id;
  final String authorId;
  final String caption;
  final int commentCount;

  /// How many people liked the look, kept by the database (post_likes).
  final int likeCount;
  final DateTime createdAt;
  final String imageURL;
  final String outfitId;
  final List<String> productIds;
  final List<Map<String, dynamic>> products;
  final PostVisibility visibility;
  final PostKind kind;

  /// Set when this post is a repost or quote of another post.
  final String repostOfId;
  final String repostOfAuthorId;

  /// The reposter's own words on a quote. Empty on a plain repost.
  final String quoteText;

  Post({
    required this.id,
    required this.authorId,
    required this.caption,
    required this.commentCount,
    this.likeCount = 0,
    required this.createdAt,
    required this.imageURL,
    this.outfitId = '',
    this.productIds = const [],
    this.products = const [],
    this.visibility = PostVisibility.private,
    this.kind = PostKind.look,
    this.repostOfId = '',
    this.repostOfAuthorId = '',
    this.quoteText = '',
  });

  bool get isRepost => repostOfId.isNotEmpty;
  bool get isQuote => isRepost && quoteText.trim().isNotEmpty;

  /// Visible to everyone: Community tab, and the author's public profile.
  bool get isPublic => visibility == PostVisibility.public;

  /// Visible to someone other than the owner at all (friends or everyone).
  /// Gates comments and quick replies, which make no sense on a post nobody
  /// else can see.
  bool get isShared => visibility != PostVisibility.private;

  bool get isDressUp => kind == PostKind.dressUp;

  /// Whether [viewerId] may see this post, given who they follow and who
  /// their friends (mutual follows) are. Owners always see their own posts.
  bool isVisibleTo(
    String viewerId, {
    required Set<String> following,
    required Set<String> friends,
  }) {
    if (authorId == viewerId) return true;
    return switch (visibility) {
      PostVisibility.public => true,
      PostVisibility.followers => following.contains(authorId),
      PostVisibility.friends => friends.contains(authorId),
      PostVisibility.private => false,
    };
  }

  /// Builds a post from a `posts` row (snake_case columns).
  factory Post.fromRow(Map<String, dynamic> row) {
    final data = camelizeRow(row);
    final rawProductIds = data['productIds'];
    final rawProducts = data['products'];

    return Post(
      id: (data['id'] ?? '').toString(),
      authorId: (data['authorId'] ?? '').toString(),
      caption: (data['caption'] ?? '').toString(),
      commentCount: _asInt(data['commentCount']),
      likeCount: _asInt(data['likeCount']),
      createdAt: asDateTime(data['createdAt']) ?? DateTime.now(),
      imageURL: (data['imageUrl'] ?? '').toString(),
      outfitId: (data['outfitId'] ?? '').toString(),
      productIds: rawProductIds is Iterable
          ? rawProductIds
                .map((value) => value.toString())
                .where((value) => value.isNotEmpty)
                .toList()
          : const [],
      products: rawProducts is Iterable
          ? rawProducts
                .whereType<Map>()
                .map((value) => Map<String, dynamic>.from(value))
                .toList()
          : const [],
      visibility: PostVisibility.fromValue(
        data['visibility'],
        legacyIsPublic: false,
      ),
      kind: PostKind.fromValue(data['kind']),
      repostOfId: (data['repostOfId'] ?? '').toString(),
      repostOfAuthorId: (data['repostOfAuthorId'] ?? '').toString(),
      quoteText: (data['quoteText'] ?? '').toString(),
    );
  }

  /// The columns to write for this post (snake_case, empty values left out).
  Map<String, dynamic> toRow() {
    return {
      'author_id': authorId,
      'caption': caption,
      'image_url': imageURL,
      if (outfitId.isNotEmpty) 'outfit_id': outfitId,
      if (productIds.isNotEmpty) 'product_ids': productIds,
      if (products.isNotEmpty) 'products': products,
      'visibility': visibility.value,
      if (isDressUp) 'kind': kind.value,
      if (isRepost) ...{
        'repost_of_id': repostOfId,
        'repost_of_author_id': repostOfAuthorId,
      },
      if (quoteText.isNotEmpty) 'quote_text': quoteText,
    };
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    return value is num ? value.toInt() : fallback;
  }
}

class PostComment {
  final String id;
  final String authorId;
  final DateTime createdAt;
  final String profileImageURL;
  final String text;
  final String username;

  PostComment({
    required this.id,
    required this.authorId,
    required this.createdAt,
    required this.profileImageURL,
    required this.text,
    required this.username,
  });

  /// Builds a comment from a `comments` row (snake_case columns).
  factory PostComment.fromRow(Map<String, dynamic> row) {
    final data = camelizeRow(row);
    return PostComment(
      id: (data['id'] ?? '').toString(),
      authorId: (data['authorId'] ?? '').toString(),
      createdAt: asDateTime(data['createdAt']) ?? DateTime.now(),
      profileImageURL: (data['authorImageUrl'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      username: (data['authorName'] ?? '').toString(),
    );
  }
}
