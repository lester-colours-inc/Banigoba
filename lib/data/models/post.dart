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
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      caption: data['caption'] ?? '',
      commentCount: data['commentCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageURL: data['imageURL'] ?? '',
      likeCount: data['likeCount'] ?? 0,
      likes: List<String>.from(data['likes'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'caption': caption,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageURL': imageURL,
      'likeCount': likeCount,
      'likes': likes,
    };
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
