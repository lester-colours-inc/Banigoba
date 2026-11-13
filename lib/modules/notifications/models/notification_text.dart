// What a notification says and who it is from: pure text helpers.

/// The notification types each category tab shows (All shows everything).
const Map<int, List<String>> notificationTabTypes = {
  1: ['follow_request', 'follow_accepted', 'new_post', 'comment'],
  2: [
    'order_update',
    'shop_promo',
    'shop_new_item',
    'shop_message',
    'shop_approval',
  ],
  3: [
    'designer_update',
    'designer_collection',
    'designer_message',
    'designer_request_status',
  ],
};

/// Whether a notification of [type] belongs on tab [tab].
bool notificationInTab(int tab, String type) {
  if (tab == 0) return true;
  return notificationTabTypes[tab]?.contains(type) ?? false;
}

/// Who a notification is from: a person, a shop, or nobody.
String notificationSenderName({
  required String type,
  required Map<String, dynamic>? extraData,
  required String currentUserId,
  required String? title,
  required String? body,
}) {
  final defaultName = (extraData?['fromName'] ?? 'Someone').toString();
  final shopName = (extraData?['shopName'] ?? '').toString();
  final sellerId = (extraData?['sellerId'] ?? '').toString();

  if (type == 'order_update') {
    if (shopName.isNotEmpty && sellerId != currentUserId) return shopName;
    final titleName = (title ?? '').trim();
    if (titleName.isNotEmpty &&
        titleName != 'Order update' &&
        titleName != 'New order') {
      return titleName;
    }
    final bodyName = nameFromNotificationBody(body);
    if (bodyName.isNotEmpty) return bodyName;
    if (defaultName == 'Someone' && body?.trim().isNotEmpty == true) {
      return '';
    }
  }

  if (type == 'shop_message' &&
      shopName.isNotEmpty &&
      usesShopIdentity(
        type: type,
        extraData: extraData,
        currentUserId: currentUserId,
      )) {
    return shopName;
  }
  return defaultName;
}

bool usesShopIdentity({
  required String type,
  required Map<String, dynamic>? extraData,
  required String currentUserId,
}) {
  final shopName = (extraData?['shopName'] ?? '').toString();
  final sellerId = (extraData?['sellerId'] ?? '').toString();
  final fromId = (extraData?['fromId'] ?? '').toString();

  if (shopName.isEmpty) return false;
  if (type == 'order_update') return sellerId != currentUserId;
  if (type == 'shop_message') {
    return sellerId.isNotEmpty &&
        sellerId != currentUserId &&
        (fromId.isEmpty || fromId == sellerId);
  }
  return false;
}

String notificationActionText(
  String type,
  String? defaultBody, {
  String actorName = '',
}) {
  switch (type) {
    case 'comment':
      return 'commented on your Daily Dress Up.';
    case 'try_on':
      return 'tried on your Daily Dress Up.';
    case 'shop_message':
      return 'sent you a shop message.';
    case 'shop_approval':
      return stripActorName(defaultBody, actorName) ??
          'approved your boutique.';
    case 'designer_request_status':
      return stripActorName(defaultBody, actorName) ??
          'updated your design request.';
    case 'order_update':
      return stripActorName(defaultBody, actorName) ?? 'updated your order.';
    case 'follow_request':
      return 'wants to follow you.';
    case 'follow_accepted':
      return 'accepted your follow request.';
    case 'new_post':
      return 'just added a new item.';
    case 'challenge':
      return 'New contest alert!';
    default:
      return defaultBody ?? '';
  }
}

String nameFromNotificationBody(String? body) {
  final text = body?.trim() ?? '';
  if (text.isEmpty) return '';

  for (final marker in [' updated your order', ' placed order']) {
    final index = text.toLowerCase().indexOf(marker);
    if (index > 0) return text.substring(0, index).trim();
  }
  return '';
}

String? stripActorName(String? body, String actorName) {
  final text = body?.trim();
  if (text == null || text.isEmpty) return null;
  final actor = actorName.trim();
  if (actor.isNotEmpty && text.toLowerCase().startsWith(actor.toLowerCase())) {
    return text.substring(actor.length).trim();
  }
  return text;
}

/// Formats the timestamp into a relative string (e.g., 4h ago, 13d ago)
String formatNotificationTimestamp(DateTime? timestamp) {
  if (timestamp == null) return "now";
  final dt = timestamp;
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
  if (diff.inHours < 24) return "${diff.inHours}h ago";
  return "${diff.inDays}d ago";
}
