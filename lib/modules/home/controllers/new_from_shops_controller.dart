// "New from shops you follow": today's matches and the ones dismissed.
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/home/services/feed_matches_service.dart';
import 'package:banigoba/modules/shop/views/product_detail_page.dart';

class NewFromShopsController extends GetxController {
  NewFromShopsController({required this.userId, FeedSource? service})
    : _service = service ?? FeedMatchesService();

  final String userId;
  final FeedSource _service;

  late final Future<List<FeedItem>> items = _service.loadToday(userId);
  final RxSet<String> dismissed = <String>{}.obs;

  void open(FeedItem item) => Get.to<void>(
    () => ProductDetailPage(
      productId: item.match.productId,
      productData: item.product,
    ),
  );

  Future<void> dismiss(FeedItem item) async {
    dismissed.add(item.match.productId);
    try {
      await _service.dismiss(userId, item.match.productId);
    } on Exception catch (error) {
      // It is hidden for this visit either way; only the memory failed.
      debugPrint('Could not remember "not for me": $error');
    }
  }
}
