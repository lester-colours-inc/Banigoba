import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final String senderId;
  final Map<String, dynamic>? extraData;
  final bool isRead;
  final DateTime? timestamp;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.senderId,
    this.extraData,
    this.isRead = false,
    this.timestamp,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? '',
      senderId: data['senderId'] ?? '',
      extraData: data['extraData'],
      isRead: data['isRead'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'senderId': senderId,
      'extraData': extraData,
      'isRead': isRead,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp(),
    };
  }
}
