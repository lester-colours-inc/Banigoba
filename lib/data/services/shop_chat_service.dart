import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';

class ShopChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notifications = NotificationService();

  String conversationId({
    required String sellerId,
    required String customerId,
  }) {
    return '${sellerId}_$customerId';
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchConversations(
    String userId,
  ) {
    return _db
        .collection('shop_chats')
        .where('participantIds', arrayContains: userId)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(String chatId) {
    return _db
        .collection('shop_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<String> ensureConversation({
    required String sellerId,
    required String customerId,
    required String shopName,
    String? productId,
    String? productName,
  }) async {
    final chatId = conversationId(sellerId: sellerId, customerId: customerId);
    final customer = await _db.collection('users').doc(customerId).get();
    final customerData = customer.data() ?? const <String, dynamic>{};
    final customerName =
        (customerData['displayName'] ??
                _auth.currentUser?.displayName ??
                _auth.currentUser?.email?.split('@').first ??
                'Customer')
            .toString();
    final customerImage =
        (customerData['profileImageURL'] ??
                customerData['profileImageUrl'] ??
                _auth.currentUser?.photoURL ??
                '')
            .toString();

    await _db.collection('shop_chats').doc(chatId).set({
      'sellerId': sellerId,
      'customerId': customerId,
      'participantIds': [sellerId, customerId],
      'shopName': shopName,
      'customerName': customerName,
      'customerImageUrl': customerImage,
      if (productId?.isNotEmpty == true) 'productId': productId,
      if (productName?.isNotEmpty == true) 'productName': productName,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return chatId;
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    final senderId = _auth.currentUser?.uid ?? '';
    if (senderId.isEmpty || text.trim().isEmpty) return;

    final chatRef = _db.collection('shop_chats').doc(chatId);
    final chat = await chatRef.get();
    final data = chat.data();
    if (data == null ||
        !(List<String>.from(data['participantIds'] ?? []).contains(senderId))) {
      throw Exception('You do not have access to this conversation.');
    }

    final sellerId = (data['sellerId'] ?? '').toString();
    final customerId = (data['customerId'] ?? '').toString();
    final receiverId = senderId == sellerId ? customerId : sellerId;
    final messageRef = chatRef.collection('messages').doc();
    final batch = _db.batch();
    batch.set(messageRef, {
      'senderId': senderId,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(chatRef, {
      'lastMessage': text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      senderId == sellerId ? 'unreadByCustomer' : 'unreadBySeller':
          FieldValue.increment(1),
    });
    await batch.commit();

    final sender = await _db.collection('users').doc(senderId).get();
    final senderName =
        (sender.data()?['displayName'] ??
                _auth.currentUser?.displayName ??
                'Someone')
            .toString();
    await _notifications.addNotification(
      receiverId: receiverId,
      title: 'New Shop Message',
      body: '$senderName sent you a message.',
      type: 'shop_message',
      extraData: {'fromId': senderId, 'fromName': senderName, 'chatId': chatId},
    );
  }

  Future<void> markRead({
    required String chatId,
    required bool asSeller,
  }) async {
    await _db.collection('shop_chats').doc(chatId).set({
      asSeller ? 'unreadBySeller' : 'unreadByCustomer': 0,
    }, SetOptions(merge: true));
  }
}
