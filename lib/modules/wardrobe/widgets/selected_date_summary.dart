// What is planned or worn on the selected day.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/wardrobe/controllers/wardrobe_calendar_controller.dart';
import 'package:banigoba/modules/wardrobe/models/calendar_dates.dart';
import 'package:banigoba/modules/wardrobe/widgets/outfit_planner_visual.dart';

class SelectedDateSummary extends StatelessWidget {
  const SelectedDateSummary({super.key, required this.controller});

  final WardrobeCalendarController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Obx(() {
      final date = controller.selectedDate.value;
      final worn = controller.history[dateKey(date)];
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: worn == null
                ? colors.surfaceContainerLow
                : colors.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: worn == null
                    ? Icon(Icons.checkroom_outlined, color: colors.outline)
                    : OutfitPlannerVisual(data: worn, compact: true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatCalendarDate(date),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      worn == null
                          ? controller.planningMode
                                ? 'Create a new outfit or reuse one below.'
                                : 'Choose a previously worn outfit below.'
                          : 'Wearing ${(worn['outfitName'] ?? 'Completed Look')}',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
