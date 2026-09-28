// "Find pieces": from a look to where its items can be bought or done.
//
// Each changed item links to the place that sells or does it: boutiques for
// clothes, shoes and accessories, hair agents for hair, and designers to have
// the whole look made. This is the first step of "Get this look" (Phase 5);
// wardrobe matching and supplier matching come later.
import 'package:flutter/material.dart';

import '../../core/app_routes.dart';
import '../../data/models/look_request.dart';
import '../screens/shop/shops_page.dart';

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

/// Shows where the pieces of a look can be found, then opens the choice.
Future<void> showFindPiecesSheet(
  BuildContext context, {
  List<LookPart> parts = const [],
}) async {
  final link = await showModalBottomSheet<PieceLink>(
    context: context,
    showDragHandle: true,
    builder: (_) => FindPiecesSheet(links: pieceLinksFor(parts)),
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
