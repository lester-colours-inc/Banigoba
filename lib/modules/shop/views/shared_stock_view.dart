// What someone sees when they open a shop's shared link (K-9): the shop, what
// it shared, and each piece with "Try on" (eFitting) and "Buy". People who
// are not signed in can look; trying on and buying ask them to sign in.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/shop/models/shop_link.dart';
import 'package:banigoba/core/utils/stock_status.dart';
import 'package:banigoba/modules/shop/widgets/safe_product_image.dart';

class SharedStockView extends StatelessWidget {
  const SharedStockView({
    super.key,
    required this.link,
    required this.pieces,
    required this.signedIn,
    required this.onTryOn,
    required this.onBuy,
    required this.onSignIn,
  });

  /// Null when the link does not exist.
  final ShopLink? link;
  final List<Map<String, dynamic>> pieces;
  final bool signedIn;
  final ValueChanged<Map<String, dynamic>> onTryOn;
  final ValueChanged<Map<String, dynamic>> onBuy;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shared = link;
    if (shared == null || !shared.active) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'This link is no longer available. The shop may have switched '
            'it off.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shared.shopName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shared.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (shared.note.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          shared.note,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (pieces.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Nothing here right now. Check back soon.',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.52,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _PieceCard(
                        piece: pieces[index],
                        signedIn: signedIn,
                        onTryOn: onTryOn,
                        onBuy: onBuy,
                        onSignIn: onSignIn,
                      ),
                      childCount: pieces.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (!signedIn)
          SafeArea(
            top: false,
            child: Container(
              key: const ValueKey('sign_in_banner'),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              color: colors.surfaceContainerHigh,
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Sign in to try pieces on and buy.'),
                  ),
                  FilledButton(
                    key: const ValueKey('sign_in_button'),
                    onPressed: onSignIn,
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PieceCard extends StatelessWidget {
  const _PieceCard({
    required this.piece,
    required this.signedIn,
    required this.onTryOn,
    required this.onBuy,
    required this.onSignIn,
  });

  final Map<String, dynamic> piece;
  final bool signedIn;
  final ValueChanged<Map<String, dynamic>> onTryOn;
  final ValueChanged<Map<String, dynamic>> onBuy;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final id = (piece['id'] ?? '').toString();
    final price = piece['price'];
    final soldOut = stockLevelOf(piece) == StockLevel.soldOut;
    final image =
        (piece['rawImageUrl'] ?? piece['imageUrl'] ?? piece['imageURL'] ?? '')
            .toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                SafeProductImage(imageUrl: image, fit: BoxFit.cover),
                if (soldOut)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Sold out',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          (piece['name'] ?? 'Piece').toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (price is num)
          Text(
            '\$${price.toStringAsFixed(2)}',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          key: ValueKey('try_on_$id'),
          onPressed: signedIn ? () => onTryOn(piece) : onSignIn,
          icon: const Icon(Icons.checkroom_outlined, size: 18),
          label: const Text('Try on'),
        ),
        const SizedBox(height: 4),
        FilledButton(
          key: ValueKey('buy_$id'),
          onPressed: soldOut
              ? null
              : (signedIn ? () => onBuy(piece) : onSignIn),
          child: const Text('Buy'),
        ),
      ],
    );
  }
}
