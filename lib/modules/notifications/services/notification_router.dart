// Where a notification leads, for a tap in the notifications list and a tap on
// a push alike. A push carries the notification's type and extra data (all as
// strings, see supabase/functions/send-push), so both paths share this.
import 'package:flutter/material.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/social/models/affirmation.dart';
import 'package:banigoba/modules/social/services/post_service.dart';
import 'package:banigoba/modules/shop/services/shop_chat_service.dart';
import 'package:banigoba/modules/designers/views/fashion_designers_page.dart';
import 'package:banigoba/modules/shop/views/shared_stock_page.dart';
import 'package:banigoba/modules/shop/views/shop_chat_page.dart';
import 'package:banigoba/modules/shop/views/shop_products_page.dart';
import 'package:banigoba/modules/social/views/profile_page.dart';
import 'package:banigoba/modules/makeover/widgets/ai_result_page.dart';
import 'package:banigoba/modules/makeover/widgets/look_viewer_page.dart';
import 'package:banigoba/modules/social/widgets/post_comments_sheet.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

/// Notifications about one of your looks, opened on that look.
const Set<String> _lookTypes = {
  'like',
  'try_on',
  'repost',
  'quote',
  'trending_look',
};

/// Opens what the notification of [type] is about. Returns false when it has
/// nowhere to go, so a push can fall back to the notifications list.
Future<bool> openNotificationTarget(
  BuildContext context,
  String type,
  Map<String, dynamic>? extraData,
) async {
  final data = extraData ?? const <String, dynamic>{};
  String read(String key) => (data[key] ?? '').toString();

  if (type == 'ai_job') return openAiResult(Navigator.of(context), data);

  if (type == 'shop_link') {
    final linkId = read('linkId');
    if (linkId.isEmpty) return false;
    _push(context, SharedStockPage(linkId: linkId));
    return true;
  }

  if (type == 'comment') {
    return _openPost(context, read('postId'), withComments: true);
  }
  if (_lookTypes.contains(type)) return _openPost(context, read('postId'));
  if (type == 'affirmation' &&
      read('targetType') == AffirmationTargetType.post.id) {
    return _openPost(context, read('targetId'));
  }

  if (type == 'shop_message' ||
      type == 'designer_message' ||
      type == 'order_update') {
    return _openChat(context, read('chatId'));
  }

  if (type == 'shop_approval') {
    final sellerId = read('sellerId');
    if (sellerId.isEmpty) return false;
    final shopName = read('shopName');
    _push(
      context,
      ShopProductsPage(
        sellerId: sellerId,
        shopName: shopName.isEmpty ? 'Boutique' : shopName,
      ),
    );
    return true;
  }

  if (type == 'designer_request_status') {
    final designerId = read('designerId');
    if (designerId.isEmpty) return false;
    _push(context, DesignerDetailPage(designerId: designerId));
    return true;
  }

  // Follows, new posts, affirmations elsewhere: the person behind it.
  final userId = [
    read('fromId'),
    read('userId'),
    read('customerId'),
  ].firstWhere((id) => id.isNotEmpty, orElse: () => '');
  if (userId.isEmpty) return false;
  _push(context, ProfilePage(userId: userId));
  return true;
}

void _push(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

Future<bool> _openPost(
  BuildContext context,
  String postId, {
  bool withComments = false,
}) async {
  if (postId.isEmpty) return false;
  final post = await PostService().getPost(postId);
  if (!context.mounted) return true;
  if (post == null || post.imageURL.isEmpty) {
    AppToast.say('This look is no longer available.');
    return true;
  }
  if (withComments) {
    await showPostCommentsSheet(context, post);
    return true;
  }
  await openLookViewer(context, imageUrl: post.imageURL, caption: post.caption);
  return true;
}

Future<bool> _openChat(BuildContext context, String chatId) async {
  if (chatId.isEmpty) return false;
  final chat = await ShopChatService().getChat(chatId);
  if (!context.mounted || chat == null) return chat != null;
  final currentUserId = AppAuth.instance.currentUser?.uid ?? '';
  final asSeller = chat['sellerId'] == currentUserId;
  final conversationType = (chat['conversationType'] ?? 'shop').toString();
  final title = asSeller
      ? (chat['customerName'] ?? 'Customer').toString()
      : conversationType == 'designer'
      ? (chat['designerName'] ?? 'Designer').toString()
      : (chat['shopName'] ?? 'Boutique').toString();
  _push(
    context,
    ShopChatPage(chatId: chatId, title: title, asSeller: asSeller),
  );
  return true;
}
