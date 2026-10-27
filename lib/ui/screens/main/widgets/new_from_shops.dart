// "New from shops you follow": up to three pieces a day from the shops and
// designers the person follows, in their size and suiting their style (review
// items D-4 and A-6). Shows nothing at all when nothing matches, so the feed
// never fills with filler.
import 'package:flutter/material.dart';

import '../../../../data/services/feed_matches_service.dart';
import '../../../widgets/shop_match_card.dart';
import '../../shop/product_detail_page.dart';

class NewFromShops extends StatefulWidget {
  const NewFromShops({super.key, required this.userId, this.service});

  final String userId;

  /// Injected in tests.
  final FeedSource? service;

  @override
  State<NewFromShops> createState() => _NewFromShopsState();
}

class _NewFromShopsState extends State<NewFromShops> {
  late final FeedSource _service = widget.service ?? FeedMatchesService();
  late final Future<List<FeedItem>> _items = _service.loadToday(widget.userId);
  final Set<String> _dismissed = {};

  void _open(FeedItem item) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ProductDetailPage(
        productId: item.match.productId,
        productData: item.product,
      ),
    ),
  );

  Future<void> _dismiss(FeedItem item) async {
    setState(() => _dismissed.add(item.match.productId));
    try {
      await _service.dismiss(widget.userId, item.match.productId);
    } on Exception catch (error) {
      // It is hidden for this visit either way; only the memory failed.
      debugPrint('Could not remember "not for me": $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FeedItem>>(
      future: _items,
      builder: (context, snapshot) {
        final items = [
          for (final item in snapshot.data ?? const <FeedItem>[])
            if (!_dismissed.contains(item.match.productId)) item,
        ];
        if (items.isEmpty) return const SizedBox.shrink();
        final colors = Theme.of(context).colorScheme;
        return Padding(
          key: const ValueKey('new_from_shops'),
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New from shops you follow',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              Text(
                'In your size, picked for your style.',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 330,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => ShopMatchCard(
                    product: items[index].product,
                    match: items[index].match,
                    onOpen: () => _open(items[index]),
                    onDismiss: () => _dismiss(items[index]),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
