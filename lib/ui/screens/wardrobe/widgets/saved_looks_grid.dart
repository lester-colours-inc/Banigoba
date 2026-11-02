// Smart Wardrobe › Saved Looks: every look the user saved (from the feed or
// a makeover), grouped by the category they chose when saving. This is where
// a "Save to Smart Wardrobe" goes, so it never feels like a dark hole
// (October 2026 review, P-3 and W-1).
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../data/models/wear_tracking.dart';
import '../../../../data/supabase/rows.dart';
import '../../../../data/services/turn_around_service.dart';
import '../../../../data/services/outfit_service.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/change_look_category_sheet.dart';
import '../../../widgets/look_viewer_page.dart';

/// Shown for looks saved without a category.
const String kUncategorisedLooks = 'Saved looks';

class SavedLooksGrid extends StatefulWidget {
  const SavedLooksGrid({super.key, required this.userId, this.outfits});

  final String userId;
  final OutfitService? outfits;

  @override
  State<SavedLooksGrid> createState() => _SavedLooksGridState();
}

class _SavedLooksGridState extends State<SavedLooksGrid> {
  late final Stream<List<Map<String, dynamic>>> _wear =
      (widget.outfits ?? OutfitService()).watchWearHistory(widget.userId);
  late final Stream<List<Map<String, dynamic>>> _looks =
      (widget.outfits ?? OutfitService()).watchSavedOutfits(widget.userId);

  @override
  Widget build(BuildContext context) {
    if (widget.userId.isEmpty) {
      return const _Message('Sign in to see the looks you have saved.');
    }
    // When each look was last worn (W-7), from "Wear today".
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _wear,
      builder: (context, wearSnapshot) =>
          _buildLooks(lastWornByOutfit(wearSnapshot.data ?? const [])),
    );
  }

  /// Asks for a new category and moves the look there.
  Future<void> _moveLook(
    Map<String, dynamic> look,
    Iterable<String> groupNames,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final current = (look['category'] ?? '').toString().trim();
    final category = await showChangeLookCategorySheet(
      context,
      existingCategories: [
        for (final name in groupNames)
          if (name != kUncategorisedLooks) name,
      ],
      currentCategory: current,
    );
    if (category == null) return;
    try {
      await (widget.outfits ?? OutfitService()).setOutfitCategory(
        userId: widget.userId,
        outfitId: look['id'].toString(),
        category: category,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            category.isEmpty
                ? 'Removed from its category.'
                : 'Moved to $category.',
          ),
        ),
      );
    } on PostgrestException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not move it: ${error.message}')),
      );
    }
  }

  Widget _buildLooks(Map<String, DateTime> lastWorn) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _looks,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _Message('Your saved looks could not be loaded.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final groups = groupLooksByCategory(snapshot.data!);
        if (groups.isEmpty) {
          return const _Message(
            'Looks you save from the feed or a makeover appear here. Tap the '
            'wardrobe icon under any look to save it.',
          );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            for (final MapEntry(key: category, value: looks)
                in groups.entries) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  '$category (${looks.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75,
                children: [
                  for (final look in looks)
                    _LookTile(
                      look: look,
                      lastWorn: lastWorn[look['id']],
                      onMove: () => _moveLook(look, groups.keys),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Looks with a picture, grouped by category (uncategorised last), newest
/// first within each group.
Map<String, List<Map<String, dynamic>>> groupLooksByCategory(
  Iterable<Map<String, dynamic>> looks,
) {
  final withImage =
      looks
          .where((look) => (look['imageUrl'] ?? '').toString().isNotEmpty)
          .toList()
        ..sort((a, b) => _createdAt(b).compareTo(_createdAt(a)));
  final groups = <String, List<Map<String, dynamic>>>{};
  for (final look in withImage) {
    final category = (look['category'] ?? '').toString().trim();
    groups
        .putIfAbsent(
          category.isEmpty ? kUncategorisedLooks : category,
          () => [],
        )
        .add(look);
  }
  final names =
      groups.keys.where((name) => name != kUncategorisedLooks).toList()..sort();
  return {
    for (final name in names) name: List.unmodifiable(groups[name]!),
    if (groups[kUncategorisedLooks] case final rest?)
      kUncategorisedLooks: List.unmodifiable(rest),
  };
}

DateTime _createdAt(Map<String, dynamic> look) =>
    asDateTime(look['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);

class _LookTile extends StatelessWidget {
  const _LookTile({
    required this.look,
    required this.lastWorn,
    required this.onMove,
  });

  final Map<String, dynamic> look;
  final DateTime? lastWorn;
  final VoidCallback onMove;

  @override
  Widget build(BuildContext context) {
    final imageUrl = look['imageUrl'].toString();
    final name = (look['name'] ?? '').toString();
    return Semantics(
      button: true,
      label: name.isEmpty ? 'Open saved look' : 'Open $name',
      child: GestureDetector(
        onTap: () => openLookViewer(
          context,
          imageUrl: imageUrl,
          title: name.isEmpty ? 'Saved look' : name,
          caption: '',
          turnViews: parseTurnViews(look['turnViews'], frontUrl: imageUrl),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                child: AppNetworkImage(
                  imageUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  fallback: const Icon(Icons.broken_image_outlined),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: IconButton.filledTonal(
                  key: ValueKey('move_look_${look['id']}'),
                  tooltip: 'Move to a category',
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  onPressed: onMove,
                  icon: const Icon(Icons.drive_file_move_outline),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _WearBadge(
                  status: wearStatus(
                    lastWorn: lastWorn,
                    addedAt: timestampToDate(look['createdAt']),
                    now: DateTime.now(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Worn 3 weeks ago" across the foot of a saved look.
class _WearBadge extends StatelessWidget {
  const _WearBadge({required this.status});

  final WearStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      color: status.isNudge
          ? const Color(0xE6D9822B)
          : Colors.black.withValues(alpha: 0.55),
      child: Text(
        status.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
