// "Get this look" (K-4, A-7): for each piece of a look, whether the person
// already owns something like it, and verified-shop pieces in their size they
// can add to the bag in one tap.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/shop/models/look_purchase.dart';
import 'package:banigoba/modules/provider/models/look_request.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

/// Adds a pick to the bag. Returns a message when it could not, or null.
typedef AddPickToCart = Future<String?> Function(ShopPick pick);

class GetThisLookSheet extends StatelessWidget {
  const GetThisLookSheet({
    super.key,
    required this.advices,
    required this.onAddToCart,
    required this.onBrowse,
    required this.onHair,
    required this.onDesigner,
    this.showHair = false,
  });

  final List<PieceAdvice> advices;
  final AddPickToCart onAddToCart;
  final ValueChanged<LookPart> onBrowse;
  final VoidCallback onHair;
  final VoidCallback onDesigner;

  /// The look includes hair, so offer a hairdresser.
  final bool showHair;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get this look',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'What you already own, and pieces in your size from verified '
              'shops.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            for (final advice in advices) ...[
              _PartSection(
                advice: advice,
                onAddToCart: onAddToCart,
                onBrowse: () => onBrowse(advice.part),
              ),
              const SizedBox(height: 14),
            ],
            if (showHair)
              ListTile(
                key: const ValueKey('get_look_hair'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.content_cut),
                title: const Text(
                  'Hair',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Find a hairdresser who can do it'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onHair,
              ),
            ListTile(
              key: const ValueKey('get_look_designer'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.design_services_outlined),
              title: const Text(
                'Have it made',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Ask a designer to make this look for you'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onDesigner,
            ),
          ],
        ),
      ),
    );
  }
}

class _PartSection extends StatelessWidget {
  const _PartSection({
    required this.advice,
    required this.onAddToCart,
    required this.onBrowse,
  });

  final PieceAdvice advice;
  final AddPickToCart onAddToCart;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final owned = advice.owned.length;
    return Column(
      key: ValueKey('part_${advice.part.name}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                advice.part.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              key: ValueKey('owned_${advice.part.name}'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: advice.hasIt
                    ? const Color(0xFF2E8B57).withValues(alpha: 0.15)
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                advice.hasIt
                    ? 'You have $owned in your wardrobe'
                    : 'None in your wardrobe',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: advice.hasIt
                      ? const Color(0xFF1E6B41)
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (advice.picks.isEmpty)
          Text(
            'No pieces in your size from verified shops right now.',
            key: ValueKey('no_picks_${advice.part.name}'),
            style: TextStyle(color: colors.onSurfaceVariant),
          )
        else
          for (final pick in advice.picks)
            _PickTile(pick: pick, onAddToCart: onAddToCart),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: ValueKey('browse_${advice.part.name}'),
            onPressed: onBrowse,
            child: Text('Browse all ${advice.part.label.toLowerCase()}'),
          ),
        ),
      ],
    );
  }
}

class _PickTile extends StatefulWidget {
  const _PickTile({required this.pick, required this.onAddToCart});

  final ShopPick pick;
  final AddPickToCart onAddToCart;

  @override
  State<_PickTile> createState() => _PickTileState();
}

enum _Bag { idle, adding, added }

class _PickTileState extends State<_PickTile> {
  _Bag _state = _Bag.idle;
  String? _message;

  Future<void> _add() async {
    setState(() {
      _state = _Bag.adding;
      _message = null;
    });
    final problem = await widget.onAddToCart(widget.pick);
    if (!mounted) return;
    setState(() {
      _state = problem == null ? _Bag.added : _Bag.idle;
      _message = problem;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final product = widget.pick.product;
    final image = (product['imageUrl'] ?? product['imageURL'] ?? '').toString();
    final price = product['price'];
    final id = (product['id'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 80,
              child: image.isEmpty
                  ? ColoredBox(color: colors.surfaceContainerHighest)
                  : AppNetworkImage(image, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (product['name'] ?? 'Piece').toString(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (price is num)
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                Text(
                  widget.pick.reasons.join(' · '),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _message!,
                      key: ValueKey('pick_message_$id'),
                      style: TextStyle(fontSize: 12, color: colors.error),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            key: ValueKey('add_pick_$id'),
            onPressed: _state == _Bag.idle ? _add : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0D0140),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(switch (_state) {
              _Bag.idle => 'Add to bag',
              _Bag.adding => 'Adding...',
              _Bag.added => 'Added',
            }),
          ),
        ],
      ),
    );
  }
}
