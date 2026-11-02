// "Share my stock" (review item K-9): a shop or designer shares a link, or the
// QR code for it, to all their stock, one category or pieces they pick. Anyone
// who opens it sees the pieces and can try them on (eFitting) and buy them.
// In Banigoba it can also go to the shop's friends, followers or the public;
// outside, through WhatsApp (the person picks the groups in WhatsApp itself,
// since apps cannot post to groups) or any other app.
import 'package:flutter/foundation.dart';

/// Where shared links open: the Banigoba web app, which hands over to the
/// installed app on a phone. Set SHARE_HOST in dart_defines.json to change it
/// (for example to a custom domain).
const String kShareHost = String.fromEnvironment(
  'SHARE_HOST',
  defaultValue: 'https://banigoba.vercel.app',
);

/// The most pieces one picked link can hold.
const int kMaxSharedPieces = 60;

const int kMaxLinkTitle = 80;
const int kMaxLinkNote = 300;

/// What a link holds.
enum ShareScope {
  all('all'),
  category('category'),
  items('items');

  const ShareScope(this.value);

  final String value;

  static ShareScope fromValue(Object? value) => ShareScope.values.firstWhere(
    (scope) => scope.value == value,
    orElse: () => ShareScope.all,
  );
}

/// Who in Banigoba is told about it. The link itself works for anyone.
enum ShareAudience {
  linkOnly('link', 'Just the link', 'Only people you send it to'),
  friends('friends', 'Friends', 'Your friends get a notification'),
  followers('followers', 'Followers', 'Everyone who follows you is told'),
  public(
    'public',
    'Public',
    'Your followers are told, and it shows in Community',
  );

  const ShareAudience(this.value, this.label, this.description);

  final String value;
  final String label;
  final String description;

  static ShareAudience fromValue(Object? value) =>
      ShareAudience.values.firstWhere(
        (audience) => audience.value == value,
        orElse: () => ShareAudience.linkOnly,
      );
}

@immutable
class ShopLink {
  const ShopLink({
    required this.id,
    required this.ownerId,
    required this.shopName,
    required this.title,
    required this.scope,
    required this.audience,
    this.note = '',
    this.category = '',
    this.productIds = const [],
    this.coverImageUrl = '',
    this.active = true,
    this.createdAt,
  });

  factory ShopLink.fromMap(String id, Map<String, dynamic> data) => ShopLink(
    id: id,
    ownerId: (data['ownerId'] ?? '').toString(),
    shopName: (data['shopName'] ?? '').toString(),
    title: (data['title'] ?? '').toString(),
    note: (data['note'] ?? '').toString(),
    scope: ShareScope.fromValue(data['scope']),
    category: (data['category'] ?? '').toString(),
    productIds: [
      if (data['productIds'] is Iterable)
        for (final id in data['productIds'] as Iterable) id.toString(),
    ],
    audience: ShareAudience.fromValue(data['audience']),
    coverImageUrl: (data['coverImageUrl'] ?? '').toString(),
    active: data['active'] != false,
    createdAt: data['createdAt'] is DateTime
        ? data['createdAt'] as DateTime
        : null,
  );

  final String id;
  final String ownerId;
  final String shopName;
  final String title;
  final String note;
  final ShareScope scope;

  /// For a category link, the category (lower case, as products store it).
  final String category;

  /// For a picked link, the pieces in it.
  final List<String> productIds;
  final ShareAudience audience;

  /// A picture for previews, from the first piece.
  final String coverImageUrl;

  /// A shop can switch a link off; it then shows nothing.
  final bool active;
  final DateTime? createdAt;

  String get url => shopLinkUrl(id);

  /// "All my stock", "Outerwear", "3 pieces".
  String get scopeLabel => switch (scope) {
    ShareScope.all => 'All my stock',
    ShareScope.category =>
      category.isEmpty
          ? 'A category'
          : '${category[0].toUpperCase()}${category.substring(1)}',
    ShareScope.items =>
      '${productIds.length} ${productIds.length == 1 ? 'piece' : 'pieces'}',
  };

  Map<String, Object?> toMap() => {
    'ownerId': ownerId,
    'shopName': shopName.trim(),
    'title': title.trim(),
    'note': note.trim(),
    'scope': scope.value,
    if (scope == ShareScope.category) 'category': category.trim().toLowerCase(),
    if (scope == ShareScope.items) 'productIds': productIds,
    'audience': audience.value,
    'coverImageUrl': coverImageUrl,
    'active': active,
  };
}

String shopLinkUrl(String id) => '$kShareHost/s?id=$id';

final RegExp _plainId = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

/// The link id in [uri] when it is a shared-stock link: on our web host, or
/// the app route "/s?id=…". Null otherwise.
String? shopLinkIdFrom(Uri uri) {
  final host = Uri.parse(kShareHost).host;
  if (uri.host.isNotEmpty && uri.host != host) return null;
  if (uri.path != '/s') return null;
  final id = uri.queryParameters['id'] ?? '';
  return _plainId.hasMatch(id) ? id : null;
}

/// The message sent with the link, ending with the link so chat apps show a
/// preview.
String shareMessage(ShopLink link) {
  final lines = [
    '${link.title} from ${link.shopName}',
    if (link.note.trim().isNotEmpty) link.note.trim(),
    'See the pieces, try them on and buy on Banigoba:',
    link.url,
  ];
  return lines.join('\n');
}

/// Opens WhatsApp with [text] ready to send. WhatsApp then lets the person
/// choose the chats and groups to send it to.
Uri whatsAppShareUri(String text) => Uri.https('wa.me', '/', {'text': text});

/// A problem with what the shop typed, or null when it can be saved.
String? validateShopLink({
  required String title,
  required ShareScope scope,
  required List<String> productIds,
  String note = '',
  String category = '',
}) {
  if (title.trim().isEmpty) return 'Give your link a title.';
  if (title.trim().length > kMaxLinkTitle) {
    return 'Keep the title under $kMaxLinkTitle characters.';
  }
  if (note.trim().length > kMaxLinkNote) {
    return 'Keep the note under $kMaxLinkNote characters.';
  }
  if (scope == ShareScope.category && category.trim().isEmpty) {
    return 'Choose a category.';
  }
  if (scope == ShareScope.items) {
    if (productIds.isEmpty) return 'Choose at least one piece.';
    if (productIds.length > kMaxSharedPieces) {
      return 'Choose at most $kMaxSharedPieces pieces.';
    }
  }
  return null;
}
