// Wardrobe insights (review item W-10): what the person wears most, what is
// sitting unworn, near-duplicates, missing basics and weather gaps. Private to
// the owner; nothing here is shown to anyone else or compared with others.
import 'package:flutter/material.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/wardrobe/models/wardrobe_insights.dart';
import 'package:banigoba/modules/shop/services/product_service.dart';

/// Where the page reads the wardrobe from; a fake in tests.
typedef LoadWardrobe = Future<List<Map<String, dynamic>>> Function();

Future<List<Map<String, dynamic>>> _loadOwnWardrobe() {
  final userId = AppAuth.instance.currentUser?.uid ?? '';
  return ProductService().getUserProducts(userId).first;
}

class WardrobeInsightsPage extends StatefulWidget {
  const WardrobeInsightsPage({super.key, LoadWardrobe? load, DateTime? now})
    : _load = load,
      _now = now;

  final LoadWardrobe? _load;
  final DateTime? _now;

  @override
  State<WardrobeInsightsPage> createState() => _WardrobeInsightsPageState();
}

class _WardrobeInsightsPageState extends State<WardrobeInsightsPage> {
  late final Future<List<Map<String, dynamic>>> _wardrobe =
      (widget._load ?? _loadOwnWardrobe)();

  static const Map<InsightKind, IconData> _icons = {
    InsightKind.mostWorn: Icons.favorite_border,
    InsightKind.neverWorn: Icons.hourglass_empty,
    InsightKind.notWornLately: Icons.history,
    InsightKind.duplicates: Icons.content_copy_outlined,
    InsightKind.missingBasics: Icons.add_circle_outline,
    InsightKind.weatherGaps: Icons.wb_cloudy_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Wardrobe insights')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _wardrobe,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Your wardrobe could not be loaded.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final wardrobe = snapshot.data!;
          if (wardrobe.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Add a few pieces to your wardrobe and we will tell you '
                  'what you wear most, what is sitting unworn and what is '
                  'missing.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final insights = analyzeWardrobe(
            wardrobe,
            now: widget._now ?? DateTime.now(),
          );
          final names = {
            for (final piece in wardrobe)
              piece['id'].toString(): (piece['name'] ?? '').toString(),
          };
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                wardrobeHeadline(wardrobe, insights),
                key: const ValueKey('insights_headline'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Only you can see this.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              if (insights.isEmpty)
                const Text(
                  'Nothing to point out. Your wardrobe looks well rounded.',
                ),
              for (final kind in InsightKind.values)
                if (insights.any((i) => i.kind == kind))
                  _Section(
                    key: ValueKey('insight_${kind.name}'),
                    kind: kind,
                    icon: _icons[kind]!,
                    insights: [
                      for (final i in insights)
                        if (i.kind == kind) i,
                    ],
                    names: names,
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    super.key,
    required this.kind,
    required this.icon,
    required this.insights,
    required this.names,
  });

  final InsightKind kind;
  final IconData icon;
  final List<Insight> insights;
  final Map<String, String> names;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.primary),
                const SizedBox(width: 10),
                Text(
                  kind.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final insight in insights)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(insight.summary),
              ),
          ],
        ),
      ),
    );
  }
}
