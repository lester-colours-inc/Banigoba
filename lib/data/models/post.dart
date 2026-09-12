// Defines social post and comment data read from Cloud Firestore.
//
// Posts intentionally expose no reaction count. Qualitative affirmations are a
// separate object (see models/affirmation.dart) and are never aggregated onto
// the post, so nothing here can be rendered as a popularity total.
import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String authorId;
  final String caption;
  final int commentCount;
  final DateTime createdAt;
  final String imageURL;
  final String outfitId;
  final List<String> productIds;
  final List<Map<String, dynamic>> products;
  final bool isPublic;

  Post({
    required this.id,
    required this.authorId,
    required this.caption,
    required this.commentCount,
    required this.createdAt,
    required this.imageURL,
    this.outfitId = '',
    this.productIds = const [],
    this.products = const [],
    this.isPublic = false,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? const {};
    final rawCreatedAt = data['createdAt'];
    final rawProductIds = data['productIds'];
    final rawProducts = data['products'] ?? data['outfitProducts'];

    return Post(
      id: doc.id,
      authorId: (data['authorID'] ?? data['authorId'] ?? '').toString(),
      caption: (data['caption'] ?? '').toString(),
      commentCount: _asInt(data['commentCount']),
      createdAt: rawCreatedAt is Timestamp
          ? rawCreatedAt.toDate()
          : rawCreatedAt is DateTime
          ? rawCreatedAt
          : DateTime.now(),
      imageURL: (data['imageURL'] ?? data['imageUrl'] ?? '').toString(),
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
      isPublic: data['isPublic'] == true || data['visibility'] == 'public',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'authorID': authorId,
      'caption': caption,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageURL': imageURL,
      if (outfitId.isNotEmpty) 'outfitId': outfitId,
      if (productIds.isNotEmpty) 'productIds': productIds,
      if (products.isNotEmpty) 'products': products,
      'isPublic': isPublic,
      'visibility': isPublic ? 'public' : 'private',
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

  factory PostComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostComment(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      profileImageURL: data['profileImageURL'] ?? '',
      text: data['text'] ?? '',
      username: data['username'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'profileImageURL': profileImageURL,
      'text': text,
      'username': username,
    };
  }
}
