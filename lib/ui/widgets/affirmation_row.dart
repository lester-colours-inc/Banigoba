// Feed affirmation row — the replacement for the like button.
//
// Renders WHICH expressions a look received, never HOW MANY. There is no
// numeral on this widget by design: a count here is a popularity score, which
// BNG SRS 001 prohibits on consumer surfaces (AFF-003, SRS-DEC-010).
//
// The owner of a look can tap through to their own private affirmation list,
// where per-expression counts are permitted as a private signal.
import 'package:flutter/material.dart';

import '../../data/models/affirmation.dart';
import '../../data/services/affirmation_service.dart';
import 'affirmation_composer_sheet.dart';

class AffirmationRow extends StatelessWidget {
  const AffirmationRow({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.targetOwnerId,
    required this.currentUserId,
    required this.ownerName,
    this.service,
    this.maxFacets = 4,
    this.onOpenReceived,
  });

  final AffirmationTargetType targetType;
  final String targetId;
  final String targetOwnerId;
  final String currentUserId;
  final String ownerName;
  final AffirmationService? service;

  /// How many distinct expressions to render before collapsing the rest.
  final int maxFacets;

  /// Invoked when the owner taps their own affirmations.
  final VoidCallback? onOpenReceived;

  bool get _isOwner =>
      currentUserId.isNotEmpty && currentUserId == targetOwnerId;

  @override
  Widget build(BuildContext context) {
    final affirmations = service ?? AffirmationService();
    final theme = Theme.of(context);

    return StreamBuilder<List<AffirmationFacet>>(
      stream: affirmations.watchFacetsForTarget(
        targetType: targetType,
        targetId: targetId,
      ),
      builder: (context, snapshot) {
        final facets = snapshot.data ?? const <AffirmationFacet>[];

        return Row(
          children: [
            Expanded(
              child: facets.isEmpty
                  ? Text(
                      _isOwner
                          ? 'No affirmations yet.'
                          : 'Be the first to affirm this look.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : _buildFacets(context, facets),
            ),
            const SizedBox(width: 8),
            if (_isOwner)
              TextButton.icon(
                onPressed: facets.isEmpty ? null : onOpenReceived,
                icon: const Icon(Icons.favorite_outline, size: 18),
                label: const Text('Received'),
              )
            else
              TextButton.icon(
                onPressed: currentUserId.isEmpty
                    ? null
                    : () => _openComposer(context, affirmations),
                icon: const Icon(Icons.add_reaction_outlined, size: 18),
                label: const Text('Affirm'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFacets(BuildContext context, List<AffirmationFacet> facets) {
    final theme = Theme.of(context);
    final visible = facets.take(maxFacets).toList();
    final hasMore = facets.length > visible.length;

    return Semantics(
      label:
          'Affirmed as ${visible.map((f) => f.shortLabel).join(', ')}'
          '${hasMore ? ' and more' : ''}',
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final facet in visible)
            _FacetChip(emoji: facet.emoji, label: facet.shortLabel),
          // Overflow is intentionally non-numeric.
          if (hasMore)
            Text(
              'and more',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openComposer(
    BuildContext context,
    AffirmationService affirmations,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final sent = await showAffirmationComposer(
      context,
      targetType: targetType,
      targetId: targetId,
      targetOwnerId: targetOwnerId,
      recipientName: ownerName,
      service: affirmations,
    );
    if (!sent) return;
    messenger.showSnackBar(const SnackBar(content: Text('Affirmation sent.')));
  }
}

class _FacetChip extends StatelessWidget {
  const _FacetChip({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji.isNotEmpty) ...[
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The owner's private view of affirmations they received on one look.
///
/// Per-expression counts are permitted here: this surface is visible only to
/// the recipient and is not a public ranking.
Future<void> showReceivedAffirmations(
  BuildContext context, {
  required AffirmationTargetType targetType,
  required String targetId,
  AffirmationService? service,
}) {
  final affirmations = service ?? AffirmationService();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);

      return Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<List<Affirmation>>(
          stream: affirmations.watchForTarget(
            targetType: targetType,
            targetId: targetId,
          ),
          builder: (context, snapshot) {
            final received = snapshot.data ?? const <Affirmation>[];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Affirmations you received',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Only you can see this.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (received.isEmpty)
                  Text('Nothing yet.', style: theme.textTheme.bodyMedium)
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: received.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final affirmation = received[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Text(
                            affirmation.emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                          title: Text(affirmation.shortLabel),
                          subtitle: Text(
                            [
                              affirmation.senderName,
                              if (affirmation.personalMessage.isNotEmpty)
                                affirmation.personalMessage,
                              if (affirmation.meaning.isNotEmpty)
                                affirmation.meaning,
                            ].join(' · '),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      );
    },
  );
}
