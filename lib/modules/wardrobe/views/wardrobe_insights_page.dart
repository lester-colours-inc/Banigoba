// Wardrobe insights (review item W-10): what the person wears most, what is
// sitting unworn, near-duplicates, missing basics and weather gaps. Private to
// the owner; nothing here is shown to anyone else or compared with others.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/wardrobe/controllers/wardrobe_insights_controller.dart';
import 'package:banigoba/modules/wardrobe/models/wardrobe_insights.dart';

export 'package:banigoba/modules/wardrobe/controllers/wardrobe_insights_controller.dart'
    show LoadWardrobe;

class WardrobeInsightsPage extends StatelessWidget {
  const WardrobeInsightsPage({super.key, this.load, this.now});

  /// Where the wardrobe is read from; a fake in tests.
  final LoadWardrobe? load;
  final DateTime? now;

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
    // Scoped to this page: created with its parameters, disposed with it.
    return GetBuilder<WardrobeInsightsController>(
      init: WardrobeInsightsController(load: load, now: now),
      global: false,
      builder: (controller) => Scaffold(
        appBar: AppBar(title: const Text('Wardrobe insights')),
        body: _Body(controller: controller),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.controller});

  final WardrobeInsightsController controller;

  @override
  Widget build(BuildContext context) => Obx(() => _content(context));

  Widget _content(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (controller.hasError.value) {
      return const Center(child: Text('Your wardrobe could not be loaded.'));
    }
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.wardrobe.isEmpty) {
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
    final insights = controller.insights;
    final names = controller.names;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          controller.headline,
          key: const ValueKey('insights_headline'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Only you can see this.',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        if (insights.isEmpty)
          const Text('Nothing to point out. Your wardrobe looks well rounded.'),
        for (final kind in InsightKind.values)
          if (insights.any((i) => i.kind == kind))
            _Section(
              key: ValueKey('insight_${kind.name}'),
              kind: kind,
              icon: WardrobeInsightsPage._icons[kind]!,
              insights: [
                for (final i in insights)
                  if (i.kind == kind) i,
              ],
              names: names,
            ),
      ],
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
