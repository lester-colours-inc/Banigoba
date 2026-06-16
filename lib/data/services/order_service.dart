import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';
import 'shop_chat_service.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ShopChatService _chatService = ShopChatService();
  final NotificationService _notifications = NotificationService();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSellerOrders(
    String sellerId,
  ) {
    return _db
        .collection('orders')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots();
  }

  Future<String> placeCollectionOrder({required String customerId}) async {
    final cartSnapshot = await _db
        .collection('users')
        .doc(customerId)
        .collection('cart')
        .get();
    if (cartSnapshot.docs.isEmpty) {
      throw Exception('Your bag is empty.');
    }

    final firstItem = cartSnapshot.docs.first.data();
    final sellerId = _sellerIdFor(firstItem);
    if (sellerId.isEmpty) {
      throw Exception('This bag is missing boutique details.');
    }

    final customerSnapshot = await _db
        .collection('users')
        .doc(customerId)
        .get();
    final customerData = customerSnapshot.data() ?? const <String, dynamic>{};
    final sellerSnapshot = await _db.collection('users').doc(sellerId).get();
    final sellerData = sellerSnapshot.data() ?? const <String, dynamic>{};
    final shop = Map<String, dynamic>.from(
      sellerData['shop'] as Map? ?? const {},
    );
    final shopName = (shop['name'] ?? _shopNameFor(firstItem)).toString();
    final customerName =
        (customerData['displayName'] ??
                _auth.currentUser?.displayName ??
                _auth.currentUser?.email?.split('@').first ??
                'Customer')
            .toString();
    final customerEmail =
        (customerData['email'] ?? _auth.currentUser?.email ?? '').toString();
    final address = Map<String, dynamic>.from(
      customerData['address'] as Map? ?? const {},
    );

    final itemRecords = await Future.wait(
      cartSnapshot.docs.map((doc) async {
        final data = doc.data();
        final productId = (data['productId'] ?? doc.id).toString();
        final productRef = _db.collection('products').doc(productId);
        final productSnapshot = await productRef.get();
        final productData = productSnapshot.data() ?? const <String, dynamic>{};
        final mergedData = {...data, ...productData};
        final quantity = _intValue(data['quantity'], fallback: 1);
        final price = _moneyValue(mergedData['price']);
        return _OrderItemRecord(
          cartRef: doc.reference,
          productRef: productSnapshot.exists ? productRef : null,
          orderItem: {
            'productId': productId,
            'name': (mergedData['name'] ?? 'Product').toString(),
            'quantity': quantity,
            'price': price,
            'lineTotal': price * quantity,
            'imageUrl':
                (mergedData['rawImageUrl'] ??
                        mergedData['imageUrl'] ??
                        mergedData['imageURL'] ??
                        '')
                    .toString(),
          },
        );
      }),
    );
    final items = itemRecords.map((record) => record.orderItem).toList();
    final total = items.fold<double>(
      0,
      (runningTotal, item) =>
          runningTotal + ((item['lineTotal'] as num?)?.toDouble() ?? 0),
    );
    final itemCount = items.fold<int>(
      0,
      (runningTotal, item) =>
          runningTotal + ((item['quantity'] as num?)?.toInt() ?? 1),
    );

    final chatId = await _chatService.ensureConversation(
      sellerId: sellerId,
      customerId: customerId,
      shopName: shopName,
    );
    final orderRef = _db.collection('orders').doc();
    final orderNumber = orderRef.id.substring(0, 6).toUpperCase();

    await _db.runTransaction((transaction) async {
      for (final record in itemRecords) {
        final productRef = record.productRef;
        if (productRef == null) continue;
        final productSnapshot = await transaction.get(productRef);
        final productData = productSnapshot.data();
        if (productData == null || !productData.containsKey('stock')) {
          continue;
        }
        final quantity = _intValue(record.orderItem['quantity'], fallback: 1);
        final currentStock = _intValue(productData['stock']);
        if (currentStock < quantity) {
          throw Exception(
            '${record.orderItem['name']} only has $currentStock in stock.',
          );
        }
        transaction.update(productRef, {
          'stock': currentStock - quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.set(orderRef, {
        'orderId': orderRef.id,
        'orderNumber': orderNumber,
        'sellerId': sellerId,
        'shopName': shopName,
        'customerId': customerId,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerAddress': address,
        'items': items,
        'itemCount': itemCount,
        'total': total,
        'paymentMethod': 'pay_upon_collection',
        'paymentLabel': 'Pay upon collection',
        'status': 'submitted',
        'statusLabel': orderStatusLabel('submitted'),
        'chatId': chatId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'statusHistory': [
          {
            'status': 'submitted',
            'label': orderStatusLabel('submitted'),
            'updatedBy': customerId,
            'updatedAt': Timestamp.now(),
          },
        ],
      });

      for (final record in itemRecords) {
        transaction.delete(record.cartRef);
      }
    });

    final message =
        'Order #$orderNumber confirmed for $shopName. Payment method: pay upon collection. Total: \$${total.toStringAsFixed(2)}.';
    await _chatService.addSystemMessage(
      chatId: chatId,
      text: message,
      unreadForSeller: true,
      unreadForCustomer: true,
      orderId: orderRef.id,
    );
    await _notifications.addNotification(
      receiverId: sellerId,
      title: 'New order',
      body: 'placed order #$orderNumber.',
      type: 'order_update',
      extraData: {
        'orderId': orderRef.id,
        'chatId': chatId,
        'fromName': customerName,
        'shopName': shopName,
        'sellerId': sellerId,
        'customerId': customerId,
      },
    );
    return orderRef.id;
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final sellerId = _auth.currentUser?.uid ?? '';
    if (sellerId.isEmpty) return;
    final orderRef = _db.collection('orders').doc(orderId);
    final orderSnapshot = await orderRef.get();
    final order = orderSnapshot.data();
    if (order == null) throw Exception('Order not found.');
    if ((order['sellerId'] ?? '').toString() != sellerId) {
      throw Exception('You can only update your own boutique orders.');
    }

    final label = orderStatusLabel(status);
    await orderRef.update({
      'status': status,
      'statusLabel': label,
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([
        {
          'status': status,
          'label': label,
          'updatedBy': sellerId,
          'updatedAt': Timestamp.now(),
        },
      ]),
    });

    final chatId = (order['chatId'] ?? '').toString();
    final orderNumber = (order['orderNumber'] ?? orderId.substring(0, 6))
        .toString();
    final shopName = (order['shopName'] ?? 'Boutique').toString();
    final customerId = (order['customerId'] ?? '').toString();
    final text = 'Order #$orderNumber status updated: $label.';
    if (chatId.isNotEmpty) {
      await _chatService.addSystemMessage(
        chatId: chatId,
        text: text,
        unreadForCustomer: true,
        orderId: orderId,
      );
    }
    if (customerId.isNotEmpty) {
      await _notifications.addNotification(
        receiverId: customerId,
        title: shopName,
        body: 'updated your order #$orderNumber: $label.',
        type: 'order_update',
        extraData: {
          'orderId': orderId,
          'chatId': chatId,
          'fromName': shopName,
          'shopName': shopName,
          'sellerId': sellerId,
          'customerId': customerId,
        },
      );
    }
  }

  String orderStatusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Accepted by boutique';
      case 'ready_for_collection':
        return 'Ready for collection';
      case 'collected':
        return 'Collected';
      case 'cancelled':
        return 'Cancelled';
      case 'submitted':
      default:
        return 'Submitted';
    }
  }

  String _sellerIdFor(Map<String, dynamic> data) {
    return (data['shopId'] ?? data['uploaderId'] ?? data['sellerId'] ?? '')
        .toString();
  }

  String _shopNameFor(Map<String, dynamic> data) {
    return (data['shopName'] ?? data['boutiqueName'] ?? 'Boutique').toString();
  }

  double _moneyValue(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0;
    return 0;
  }

  int _intValue(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
  }
}

class _OrderItemRecord {
  const _OrderItemRecord({
    required this.cartRef,
    required this.productRef,
    required this.orderItem,
  });

  final DocumentReference<Map<String, dynamic>> cartRef;
  final DocumentReference<Map<String, dynamic>>? productRef;
  final Map<String, dynamic> orderItem;
}
