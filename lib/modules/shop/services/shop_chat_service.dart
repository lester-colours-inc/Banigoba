// Conversations between customers and shops, designers and hair salons.
//
// A conversation is a row in `shop_chats` and its messages are rows in
// `shop_chat_messages`. All writes go through database functions
// (ensure_chat, send_chat_message, post_system_message, mark_chat_read) so
// unread counts stay right and nobody can pose as the system. Screens read
// chats and messages as maps with camelCase fields and an `id`.
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/core/supabase/supabase_config.dart';
import 'package:banigoba/core/supabase/rows.dart';
import 'package:banigoba/modules/notifications/services/notification_service.dart';

/// A `shop_chats` row as the screens read it.
Map<String, dynamic> chatMap(Map<String, dynamic> row) {
  final flat = flattenRow(row);
  final kind = (row['kind'] ?? 'shop').toString();
  return {
    ...flat,
    'conversationType': kind,
    'participantIds': [row['seller_id'], row['customer_id']],
    'designerName': (flat['designerName'] ?? '').toString().isNotEmpty
        ? flat['designerName']
        : flat['shopName'],
  };
}

/// A `shop_chat_messages` row as the screens read it.
Map<String, dynamic> messageMap(Map<String, dynamic> row) {
  final flat = flattenRow(row);
  return {
    ...flat,
    'senderId': row['is_system'] == true ? 'system' : row['sender_id'],
    'senderType': row['sender_type'] == 'text' ? null : row['sender_type'],
  };
}

class ShopChatService {
  final NotificationService _notifications = NotificationService();

  String get _userId => AppAuth.instance.currentUser?.uid ?? '';

  /// One conversation, or null if it does not exist or is not the caller's.
  Future<Map<String, dynamic>?> getChat(String chatId) async {
    final row = await supabase
        .from('shop_chats')
        .select()
        .eq('id', chatId)
        .maybeSingle();
    return row == null ? null : chatMap(row);
  }

  /// One conversation, live (null while it cannot be read).
  Stream<Map<String, dynamic>?> watchChat(String chatId) {
    return supabase
        .from('shop_chats')
        .stream(primaryKey: ['id'])
        .eq('id', chatId)
        .map((rows) => rows.isEmpty ? null : chatMap(rows.first));
  }

  Stream<List<Map<String, dynamic>>> watchConversations(String userId) {
    return supabase
        .from('shop_chats')
        .stream(primaryKey: ['id'])
        .map(
          (rows) => [
            for (final row in rows)
              if (row['seller_id'] == userId || row['customer_id'] == userId)
                chatMap(row),
          ],
        );
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String chatId) {
    return supabase
        .from('shop_chat_messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: false)
        .map((rows) => [for (final row in rows) messageMap(row)]);
  }

  Future<String> _ensure(
    String kind,
    String providerId,
    String name, [
    Map<String, dynamic> context = const {},
  ]) async {
    final id = await supabase.rpc(
      'ensure_chat',
      params: {
        'p_kind': kind,
        'p_provider': providerId,
        'p_provider_name': name,
        'p_context': context,
      },
    );
    return id.toString();
  }

  Future<String> ensureConversation({
    required String sellerId,
    required String customerId,
    required String shopName,
    String? productId,
    String? productName,
    String? productImageUrl,
    double? productPrice,
  }) {
    return _ensure('shop', sellerId, shopName, {
      if (productId?.isNotEmpty == true) 'productId': productId,
      if (productName?.isNotEmpty == true) 'productName': productName,
      if (productImageUrl?.isNotEmpty == true)
        'productImageUrl': productImageUrl,
      'productPrice': ?productPrice,
    });
  }

  Future<String> ensureDesignerConversation({
    required String designerId,
    required String customerId,
    required String designerName,
  }) => _ensure('designer', designerId, designerName);

  /// A conversation with a hair salon (a verified hair agent). The salon sits
  /// in the seller slot, so the inbox and unread counters work as-is.
  Future<String> ensureSalonConversation({
    required String salonId,
    required String customerId,
    required String salonName,
  }) => _ensure('salon', salonId, salonName);

  Future<void> _send(
    String chatId,
    String text,
    String senderType, {
    Map<String, dynamic> data = const {},
    Map<String, dynamic> chatContext = const {},
  }) async {
    await supabase.rpc(
      'send_chat_message',
      params: {
        'p_chat': chatId,
        'p_text': text,
        'p_sender_type': senderType,
        'p_data': data,
        'p_chat_context': chatContext,
      },
    );
  }

  Future<String> _senderName() async {
    final profile = await supabase
        .from('profiles')
        .select('display_name')
        .eq('id', _userId)
        .maybeSingle();
    final name = (profile?['display_name'] ?? '').toString();
    return name.isNotEmpty
        ? name
        : (AppAuth.instance.currentUser?.displayName ?? 'Someone');
  }

  /// Sends a forwarded look (its picture and caption) into a conversation and
  /// lets the other side know.
  Future<void> addLookReference({
    required String chatId,
    required String imageUrl,
    String caption = '',
  }) async {
    if (_userId.isEmpty) throw Exception('Sign in to forward looks.');
    if (imageUrl.trim().isEmpty) throw Exception('This look has no picture.');

    final chat = await getChat(chatId);
    if (chat == null)
      throw Exception('You do not have access to this conversation.');
    final text = caption.trim().isEmpty
        ? 'Forwarded a look'
        : 'Forwarded a look: ${caption.trim()}';
    await _send(
      chatId,
      text,
      'look_reference',
      data: {'lookImageUrl': imageUrl.trim()},
    );
    await _notifyOtherSide(chat, 'forwarded you a look.');
  }

  Future<void> addProductReference({
    required String chatId,
    required String productId,
    required String productName,
    String? productImageUrl,
    double? productPrice,
  }) async {
    if (productId.trim().isEmpty && productName.trim().isEmpty) return;
    if (_userId.isEmpty) return;

    final title = productName.trim().isEmpty ? 'this product' : productName;
    final details = {
      'productId': productId.trim(),
      'productName': title,
      if (productImageUrl?.isNotEmpty == true)
        'productImageUrl': productImageUrl,
      'productPrice': ?productPrice,
    };
    await _send(
      chatId,
      'Asked about $title',
      'product_reference',
      data: details,
      chatContext: details,
    );
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
    if (_userId.isEmpty) return;

    final title = occasion.trim().isEmpty ? 'Custom design' : occasion.trim();
    await _send(
      chatId,
      'Asked about $title',
      'design_request_reference',
      data: {
        'requestId': requestId.trim(),
        'occasion': title,
        if (budget?.trim().isNotEmpty == true) 'budget': budget!.trim(),
        if (deadline?.trim().isNotEmpty == true) 'deadline': deadline!.trim(),
        if (status?.trim().isNotEmpty == true) 'status': status!.trim(),
      },
      chatContext: {'requestId': requestId.trim(), 'requestOccasion': title},
    );
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    if (_userId.isEmpty || text.trim().isEmpty) return;

    final chat = await getChat(chatId);
    if (chat == null)
      throw Exception('You do not have access to this conversation.');
    await _send(chatId, text.trim(), 'text');
    await _notifyOtherSide(chat, 'sent you a message.');
  }

  Future<void> _notifyOtherSide(
    Map<String, dynamic> chat,
    String action,
  ) async {
    final sellerId = (chat['sellerId'] ?? '').toString();
    final customerId = (chat['customerId'] ?? '').toString();
    final conversationType = (chat['conversationType'] ?? 'shop').toString();
    final shopName = (chat['shopName'] ?? 'Boutique').toString();
    final designerName = (chat['designerName'] ?? shopName).toString();
    final receiverId = _userId == sellerId ? customerId : sellerId;
    final senderName = await _senderName();
    await _notifications.addNotification(
      receiverId: receiverId,
      title: 'New Message',
      body: '$senderName $action',
      type: conversationType == 'designer'
          ? 'designer_message'
          : 'shop_message',
      extraData: {
        'fromId': _userId,
        'fromName': _userId == sellerId
            ? (conversationType == 'designer' ? designerName : shopName)
            : senderName,
        'conversationType': conversationType,
        'shopName': shopName,
        'designerName': designerName,
        'sellerId': sellerId,
        if (conversationType == 'designer') 'designerId': sellerId,
        'customerId': customerId,
        'chatId': chat['id'],
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
    await supabase.rpc(
      'post_system_message',
      params: {
        'p_chat': chatId,
        'p_text': text.trim(),
        'p_order': orderId?.isNotEmpty == true ? orderId : null,
        'p_unread_seller': unreadForSeller,
        'p_unread_customer': unreadForCustomer,
      },
    );
  }

  Future<void> markRead({
    required String chatId,
    required bool asSeller,
  }) async {
    await supabase.rpc(
      'mark_chat_read',
      params: {'p_chat': chatId, 'p_as_seller': asSeller},
    );
  }
}
