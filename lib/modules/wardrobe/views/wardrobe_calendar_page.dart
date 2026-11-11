// Lets users repeat saved outfits and schedule them against calendar dates.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/wardrobe/controllers/wardrobe_calendar_controller.dart';
import 'package:banigoba/modules/wardrobe/models/calendar_dates.dart';
import 'package:banigoba/modules/wardrobe/widgets/calendar_week_header.dart';
import 'package:banigoba/modules/wardrobe/widgets/previously_worn_outfits.dart';
import 'package:banigoba/modules/wardrobe/widgets/selected_date_summary.dart';

class WardrobeCalendarPage extends StatelessWidget {
  const WardrobeCalendarPage({
    super.key,
    this.planningMode = false,
    this.eventId,
    this.eventName,
    this.eventStart,
    this.eventEnd,
  });

  final bool planningMode;
  final String? eventId;
  final String? eventName;
  final DateTime? eventStart;
  final DateTime? eventEnd;

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: built from its parameters, disposed with it.
    return GetBuilder<WardrobeCalendarController>(
      init: WardrobeCalendarController(
        planningMode: planningMode,
        eventId: eventId,
        eventName: eventName,
        eventStart: eventStart,
        eventEnd: eventEnd,
      ),
      global: false,
      builder: (controller) => _CalendarView(controller: controller),
    );
  }
}

class _CalendarView extends StatelessWidget {
  const _CalendarView({required this.controller});

  final WardrobeCalendarController controller;

  @override
  Widget build(BuildContext context) {
    final userId = controller.userId;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: Get.back,
          icon: Icon(Icons.chevron_left_rounded, color: colors.onSurface),
        ),
        title: Text(
          controller.eventName ??
              (controller.planningMode ? 'Week Planner' : 'Quick Wear'),
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Open full calendar',
            onPressed: userId == null
                ? null
                : controller.openFullCalendarForUser,
            icon: const Icon(Icons.calendar_month, color: calendarPrimary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: userId == null
          ? const Center(child: Text('Sign in to view your worn outfits.'))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: CalendarWeekHeader(controller: controller),
                ),
                SliverToBoxAdapter(
                  child: SelectedDateSummary(controller: controller),
                ),
                if (controller.planningMode)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Obx(
                        () => FilledButton.icon(
                          onPressed: controller.createOutfitForSelectedDate,
                          style: FilledButton.styleFrom(
                            backgroundColor: calendarPrimary,
                            minimumSize: const Size(double.infinity, 52),
                          ),
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: Text(
                            'Create outfit for ${formatCalendarDate(controller.selectedDate.value)}',
                          ),
                        ),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  sliver: PreviouslyWornOutfits(controller: controller),
                ),
              ],
            ),
    );
  }
}
