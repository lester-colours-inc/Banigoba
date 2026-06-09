// Defines social post and comment data read from Cloud Firestore.
import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String authorId;
  final String caption;
  final int commentCount;
  final DateTime createdAt;
  final String imageURL;
  final int likeCount;
  final List<String> likes;

  Post({
    required this.id,
    required this.authorId,
    required this.caption,
    required this.commentCount,
    required this.createdAt,
    required this.imageURL,
    required this.likeCount,
    required this.likes,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? const {};
    final rawLikes = data['likedBy'] ?? data['likes'] ?? const [];
    final likes = rawLikes is Iterable
        ? rawLikes
              .map((value) => value.toString())
              .where((value) => value.isNotEmpty)
              .toList()
        : <String>[];
    final rawCreatedAt = data['createdAt'];

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
      likeCount: _asInt(data['likeCount'], fallback: likes.length),
      likes: likes,
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
      'likeCount': likeCount,
      'likes': likes,
      'likedBy': likes,
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
