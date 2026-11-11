// The "Previously Worn" grid of saved outfits, as a sliver.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/wardrobe/controllers/wardrobe_calendar_controller.dart';
import 'package:banigoba/modules/wardrobe/models/saved_outfit.dart';
import 'package:banigoba/modules/wardrobe/widgets/calendar_week_header.dart';
import 'package:banigoba/modules/wardrobe/widgets/outfit_planner_visual.dart';

class PreviouslyWornOutfits extends StatelessWidget {
  const PreviouslyWornOutfits({super.key, required this.controller});

  final WardrobeCalendarController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.outfitsFailed.value) {
        return const SliverToBoxAdapter(
          child: _Message('Previously worn outfits could not be loaded.'),
        );
      }
      final outfits = controller.outfits.value;
      if (outfits == null) {
        return const SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (outfits.isEmpty) {
        return const SliverToBoxAdapter(
          child: _Message(
            'No previous outfits yet. Save a look from Avatar Try-On first.',
          ),
        );
      }
      return SliverMainAxisGroup(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Text(
                'Previously Worn',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.68,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _OutfitCard(controller: controller, outfit: outfits[index]),
              childCount: outfits.length,
            ),
          ),
        ],
      );
    });
  }
}

class _OutfitCard extends StatelessWidget {
  const _OutfitCard({required this.controller, required this.outfit});

  final WardrobeCalendarController controller;
  final SavedOutfit outfit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: colors.surface,
              child: OutfitPlannerVisual(data: outfit.data),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Text(
              outfit.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: Obx(() {
              final savingId = controller.savingOutfitId.value;
              return FilledButton(
                onPressed: savingId == null
                    ? () => controller.reuseOutfit(outfit)
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: calendarPrimary,
                  minimumSize: const Size(double.infinity, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: savingId == outfit.id
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Wear Again'),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.checkroom_outlined, size: 52),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
