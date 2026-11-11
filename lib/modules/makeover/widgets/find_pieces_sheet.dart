// "Find pieces": from a look to where its items can be bought or done.
//
// Each changed item links to the place that sells or does it: boutiques for
// clothes, shoes and accessories, hair agents for hair, and designers to have
// the whole look made. For clothes, shoes and accessories the sheet first
// checks the person's wardrobe and offers verified-shop pieces in their size
// ("Get this look", K-4); when that cannot load it falls back to these links.
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:flutter/material.dart';

import 'package:banigoba/app/routes/app_routes.dart';
import 'package:banigoba/modules/shop/models/look_purchase.dart';
import 'package:banigoba/modules/provider/models/look_request.dart';
import 'package:banigoba/modules/shop/services/cart_service.dart';
import 'package:banigoba/modules/shop/services/look_purchase_service.dart';
import 'package:banigoba/modules/shop/views/shops_page.dart';
import 'package:banigoba/modules/makeover/widgets/get_this_look_sheet.dart';

enum PieceDestination { boutiques, hairdressers, designers }

/// One row of the sheet.
@immutable
class PieceLink {
  const PieceLink({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.destination,
    this.query = '',
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final PieceDestination destination;

  /// Boutique search text, matched against product names and categories.
  final String query;
}

/// The items a look is assumed to have when it is not known what changed,
/// such as someone else's post.
const List<LookPart> kWholeLookParts = [
  LookPart.hair,
  LookPart.outfit,
  LookPart.shoes,
  LookPart.accessories,
];

/// Rows for [parts], followed by "Have it made".
List<PieceLink> pieceLinksFor(List<LookPart> parts) => [
  for (final part in parts.isEmpty ? kWholeLookParts : parts) _linkFor(part),
  const PieceLink(
    title: 'Have it made',
    subtitle: 'Ask a designer to make this look for you',
    icon: Icons.design_services_outlined,
    destination: PieceDestination.designers,
  ),
];

PieceLink _linkFor(LookPart part) => switch (part) {
  LookPart.hair => const PieceLink(
    title: 'Hair',
    subtitle: 'Find a hairdresser who can do it',
    icon: Icons.content_cut,
    destination: PieceDestination.hairdressers,
  ),
  LookPart.outfit => const PieceLink(
    title: 'Clothes',
    subtitle: 'Shop boutiques for these clothes',
    icon: Icons.checkroom_outlined,
    destination: PieceDestination.boutiques,
  ),
  LookPart.top => const PieceLink(
    title: 'Top',
    subtitle: 'Shop tops, shirts and jackets',
    icon: Icons.checkroom_outlined,
    destination: PieceDestination.boutiques,
    query: 'tops',
  ),
  LookPart.bottom => const PieceLink(
    title: 'Bottom',
    subtitle: 'Shop trousers, skirts and shorts',
    icon: Icons.checkroom_outlined,
    destination: PieceDestination.boutiques,
    query: 'bottoms',
  ),
  LookPart.shoes => const PieceLink(
    title: 'Shoes',
    subtitle: 'Shop shoes and sneakers',
    icon: Icons.directions_walk,
    destination: PieceDestination.boutiques,
    query: 'shoe',
  ),
  LookPart.accessories => const PieceLink(
    title: 'Accessories',
    subtitle: 'Shop glasses, hats and jewellery',
    icon: Icons.diamond_outlined,
    destination: PieceDestination.boutiques,
    query: 'accessories',
  ),
};

String? _signedInUserId() {
  try {
    return AppAuth.instance.currentUser?.uid;
  } on Object {
    return null;
  }
}

/// Adds a pick to the bag; returns a message when it could not.
Future<String?> _addToBag(String userId, ShopPick pick) async {
  try {
    await CartService().addToCart(
      userId: userId,
      productId: (pick.product['id'] ?? '').toString(),
      productData: pick.product,
      selectedSize: pick.size.isEmpty ? null : pick.size,
    );
    return null;
  } on CartShopConflictException catch (error) {
    return 'Your bag has items from ${error.currentShopName}. Finish or '
        'clear that bag first.';
  } on Exception catch (error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

/// Shows where the pieces of a look can be found, then opens the choice.
///
/// [source], [userId] and [addToCart] are for tests; the app uses the real
/// ones.
Future<void> showFindPiecesSheet(
  BuildContext context, {
  List<LookPart> parts = const [],
  LookPurchaseSource? source,
  String? userId,
  AddPickToCart? addToCart,
}) async {
  final shown = parts.isEmpty ? kWholeLookParts : parts;
  final uid = userId ?? _signedInUserId();
  final shoppable = shown.any((part) => part != LookPart.hair);
  final link = await showModalBottomSheet<PieceLink>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => uid == null || !shoppable
        ? FindPiecesSheet(links: pieceLinksFor(parts))
        : _GetThisLookLoader(
            parts: shown,
            userId: uid,
            source: source ?? LookPurchaseService(),
            addToCart: addToCart ?? (pick) => _addToBag(uid, pick),
            fallbackLinks: pieceLinksFor(parts),
          ),
  );
  if (link == null || !context.mounted) return;

  switch (link.destination) {
    case PieceDestination.boutiques:
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ShopsPage(initialTab: 1, initialQuery: link.query),
        ),
      );
    case PieceDestination.hairdressers:
      await Navigator.pushNamed(context, AppRoutes.agents);
    case PieceDestination.designers:
      await Navigator.pushNamed(context, AppRoutes.fashionDesigners);
  }
}

/// Loads the wardrobe check and shop picks, then shows [GetThisLookSheet].
class _GetThisLookLoader extends StatefulWidget {
  const _GetThisLookLoader({
    required this.parts,
    required this.userId,
    required this.source,
    required this.addToCart,
    required this.fallbackLinks,
  });

  final List<LookPart> parts;
  final String userId;
  final LookPurchaseSource source;
  final AddPickToCart addToCart;
  final List<PieceLink> fallbackLinks;

  @override
  State<_GetThisLookLoader> createState() => _GetThisLookLoaderState();
}

class _GetThisLookLoaderState extends State<_GetThisLookLoader> {
  late final Future<List<PieceAdvice>> _advice = widget.source.load(
    widget.userId,
    widget.parts,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PieceAdvice>>(
      future: _advice,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return FindPiecesSheet(links: widget.fallbackLinks);
        }
        if (!snapshot.hasData) {
          return const SafeArea(
            child: SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return GetThisLookSheet(
          advices: snapshot.data!,
          showHair: widget.parts.contains(LookPart.hair),
          onAddToCart: widget.addToCart,
          onBrowse: (part) => Navigator.pop(context, _linkFor(part)),
          onHair: () => Navigator.pop(context, _linkFor(LookPart.hair)),
          onDesigner: () => Navigator.pop(context, widget.fallbackLinks.last),
        );
      },
    );
  }
}

class FindPiecesSheet extends StatelessWidget {
  const FindPiecesSheet({super.key, required this.links});

  final List<PieceLink> links;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                'Find these pieces',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Shop each item, or have the whole look made.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
            for (final link in links)
              ListTile(
                key: ValueKey('find_piece_${link.title}'),
                leading: CircleAvatar(
                  backgroundColor: colors.surfaceContainerHigh,
                  foregroundColor: colors.onSurface,
                  child: Icon(link.icon, size: 20),
                ),
                title: Text(
                  link.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(link.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, link),
              ),
          ],
        ),
      ),
    );
  }
}
