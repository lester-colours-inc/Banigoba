// Smart Wardrobe › Saved Looks: every look the user saved (from the feed or
// a makeover), grouped by the category they chose when saving. This is where
// a "Save to Smart Wardrobe" goes, so it never feels like a dark hole
// (October 2026 review, P-3 and W-1).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../data/services/outfit_service.dart';
import '../../../widgets/app_network_image.dart';
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
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _looks =
      (widget.outfits ?? OutfitService()).watchSavedOutfits(widget.userId);

  @override
  Widget build(BuildContext context) {
    if (widget.userId.isEmpty) {
      return const _Message('Sign in to see the looks you have saved.');
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _looks,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _Message('Your saved looks could not be loaded.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final groups = groupLooksByCategory(
          snapshot.data!.docs.map((doc) => doc.data()),
        );
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
                children: [for (final look in looks) _LookTile(look: look)],
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

DateTime _createdAt(Map<String, dynamic> look) => switch (look['createdAt']) {
  Timestamp(:final seconds) => DateTime.fromMillisecondsSinceEpoch(
    seconds * 1000,
  ),
  _ => DateTime.fromMillisecondsSinceEpoch(0),
};

class _LookTile extends StatelessWidget {
  const _LookTile({required this.look});

  final Map<String, dynamic> look;

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
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: AppNetworkImage(
              imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              fallback: const Icon(Icons.broken_image_outlined),
            ),
          ),
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
