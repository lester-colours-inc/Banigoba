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

  String designerConversationId({
    required String designerId,
    required String customerId,
  }) {
    return 'designer_${designerId}_$customerId';
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
    String? productImageUrl,
    double? productPrice,
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

    final chatData = <String, dynamic>{
      'sellerId': sellerId,
      'customerId': customerId,
      'participantIds': [sellerId, customerId],
      'conversationType': 'shop',
      'shopName': shopName,
      'customerName': customerName,
      'customerImageUrl': customerImage,
      if (productId?.isNotEmpty == true) 'productId': productId,
      if (productName?.isNotEmpty == true) 'productName': productName,
      if (productImageUrl?.isNotEmpty == true)
        'productImageUrl': productImageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (productPrice != null) {
      chatData['productPrice'] = productPrice;
    }

    await _db
        .collection('shop_chats')
        .doc(chatId)
        .set(chatData, SetOptions(merge: true));
    return chatId;
  }

  Future<String> ensureDesignerConversation({
    required String designerId,
    required String customerId,
    required String designerName,
  }) async {
    final chatId = designerConversationId(
      designerId: designerId,
      customerId: customerId,
    );
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
      'sellerId': designerId,
      'designerId': designerId,
      'customerId': customerId,
      'participantIds': [designerId, customerId],
      'conversationType': 'designer',
      'designerName': designerName,
      'shopName': designerName,
      'customerName': customerName,
      'customerImageUrl': customerImage,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return chatId;
  }

  Future<void> addProductReference({
    required String chatId,
    required String productId,
    required String productName,
    String? productImageUrl,
    double? productPrice,
  }) async {
    if (productId.trim().isEmpty && productName.trim().isEmpty) return;

    final senderId = _auth.currentUser?.uid ?? '';
    if (senderId.isEmpty) return;

    final chatRef = _db.collection('shop_chats').doc(chatId);
    final chat = await chatRef.get();
    final data = chat.data();
    if (data == null ||
        !(List<String>.from(data['participantIds'] ?? []).contains(senderId))) {
      throw Exception('You do not have access to this conversation.');
    }

    final sellerId = (data['sellerId'] ?? '').toString();
    final messageRef = chatRef.collection('messages').doc();
    final title = productName.trim().isEmpty ? 'this product' : productName;
    final batch = _db.batch();
    final messageData = <String, dynamic>{
      'senderId': senderId,
      'senderType': 'product_reference',
      'text': 'Asked about $title',
      'productId': productId.trim(),
      'productName': title,
      if (productImageUrl?.isNotEmpty == true)
        'productImageUrl': productImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (productPrice != null) {
      messageData['productPrice'] = productPrice;
    }

    final chatUpdate = <String, dynamic>{
      'productId': productId.trim(),
      'productName': title,
      if (productImageUrl?.isNotEmpty == true)
        'productImageUrl': productImageUrl,
      'lastMessage': 'Asked about $title',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      senderId == sellerId ? 'unreadByCustomer' : 'unreadBySeller':
          FieldValue.increment(1),
    };
    if (productPrice != null) {
      chatUpdate['productPrice'] = productPrice;
    }

    batch.set(messageRef, messageData);
    batch.set(chatRef, chatUpdate, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> addDesignRequestReference({
    required String chatId,
    required String requestId,
    required String occasion,
    String? budget,
    String? deadline,
    String? status,
  }) async {
    if (requestId.trim().isEmpty) return;

    final senderId = _auth.currentUser?.uid ?? '';
    if (senderId.isEmpty) return;

    final chatRef = _db.collection('shop_chats').doc(chatId);
    final chat = await chatRef.get();
    final data = chat.data();
    if (data == null ||
        !(List<String>.from(data['participantIds'] ?? []).contains(senderId))) {
      throw Exception('You do not have access to this conversation.');
    }

    final sellerId = (data['sellerId'] ?? '').toString();
    final title = occasion.trim().isEmpty ? 'Custom design' : occasion.trim();
    final batch = _db.batch();
    final messageRef = chatRef.collection('messages').doc();
    batch.set(messageRef, {
      'senderId': senderId,
      'senderType': 'design_request_reference',
      'text': 'Asked about $title',
      'requestId': requestId.trim(),
      'occasion': title,
      if (budget?.trim().isNotEmpty == true) 'budget': budget!.trim(),
      if (deadline?.trim().isNotEmpty == true) 'deadline': deadline!.trim(),
      if (status?.trim().isNotEmpty == true) 'status': status!.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(chatRef, {
      'requestId': requestId.trim(),
      'requestOccasion': title,
      'lastMessage': 'Asked about $title',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      senderId == sellerId ? 'unreadByCustomer' : 'unreadBySeller':
          FieldValue.increment(1),
    }, SetOptions(merge: true));
    await batch.commit();
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
    final conversationType = (data['conversationType'] ?? 'shop').toString();
    final shopName = (data['shopName'] ?? 'Boutique').toString();
    final designerName = (data['designerName'] ?? shopName).toString();
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
      title: 'New Message',
      body: '$senderName sent you a message.',
      type: conversationType == 'designer'
          ? 'designer_message'
          : 'shop_message',
      extraData: {
        'fromId': senderId,
        'fromName': senderId == sellerId
            ? (conversationType == 'designer' ? designerName : shopName)
            : senderName,
        'conversationType': conversationType,
        'shopName': shopName,
        'designerName': designerName,
        'sellerId': sellerId,
        if (conversationType == 'designer') 'designerId': sellerId,
        'customerId': customerId,
        'chatId': chatId,
      },
    );
  }

  Future<void> addSystemMessage({
    required String chatId,
    required String text,
    bool unreadForSeller = false,
    bool unreadForCustomer = false,
    String? orderId,
  }) async {
    if (text.trim().isEmpty) return;

    final chatRef = _db.collection('shop_chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();
    final update = <String, dynamic>{
      'lastMessage': text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (unreadForSeller) {
      update['unreadBySeller'] = FieldValue.increment(1);
    }
    if (unreadForCustomer) {
      update['unreadByCustomer'] = FieldValue.increment(1);
    }

    final batch = _db.batch();
    batch.set(messageRef, {
      'senderId': 'system',
      'senderType': 'system',
      'text': text.trim(),
      if (orderId?.isNotEmpty == true) 'orderId': orderId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(chatRef, update, SetOptions(merge: true));
    await batch.commit();
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
