// Opens a shop's shared link (K-9) from a web address, a QR code, a
// notification or the Community strip.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/models/shop_link.dart';
import '../../../data/services/shop_link_service.dart';
import '../makeover/avatar_try_on_page.dart';
import 'product_detail_page.dart';
import 'shared_stock_view.dart';

class SharedStockPage extends StatefulWidget {
  const SharedStockPage({super.key, required this.linkId, this.source});

  final String linkId;
  final ShopLinkSource? source;

  @override
  State<SharedStockPage> createState() => _SharedStockPageState();
}

class _SharedStockPageState extends State<SharedStockPage> {
  late final ShopLinkSource _source = widget.source ?? ShopLinkService();
  late final Future<(ShopLink?, List<Map<String, dynamic>>)> _data = _load();

  Future<(ShopLink?, List<Map<String, dynamic>>)> _load() async {
    final link = await _source.load(widget.linkId);
    if (link == null || !link.active) return (link, <Map<String, dynamic>>[]);
    return (link, await _source.pieces(link));
  }

  bool get _signedIn {
    try {
      return FirebaseAuth.instance.currentUser != null;
    } on Object {
      return false;
    }
  }

  void _tryOn(Map<String, dynamic> piece) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => AvatarTryOnPage(
        garmentImageUrl:
            (piece['rawImageUrl'] ?? piece['imageUrl'] ?? piece['imageURL'])
                ?.toString(),
        garmentName: (piece['name'] ?? '').toString(),
        category: (piece['category'] ?? '').toString(),
      ),
    ),
  );

  void _buy(Map<String, dynamic> piece) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ProductDetailPage(
        productId: (piece['id'] ?? '').toString(),
        productData: piece,
      ),
    ),
  );

  /// Back to the start, where signing in happens. The link can be opened
  /// again afterwards.
  void _signIn() =>
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: FutureBuilder<(ShopLink?, List<Map<String, dynamic>>)>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('This link could not be opened.'));
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return SharedStockView(
            link: data.$1,
            pieces: data.$2,
            signedIn: _signedIn,
            onTryOn: _tryOn,
            onBuy: _buy,
            onSignIn: _signIn,
          );
        },
      ),
    );
  }
}
