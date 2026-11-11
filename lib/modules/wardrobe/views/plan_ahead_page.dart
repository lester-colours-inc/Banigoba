// Provides planning shortcuts for future outfits and wardrobe activities.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/wardrobe/controllers/plan_ahead_controller.dart';
import 'package:banigoba/modules/wardrobe/widgets/plan_cards.dart';

/// Hub for planning outfits in advance, including weekly planning and trip packing.
class PlanAheadPage extends GetView<PlanAheadController> {
  const PlanAheadPage({super.key});

  static Color primaryColor = const Color(0xFF0D0140);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: Get.back,
        ),
        title: Text(
          'Plan Ahead',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Organize Your Style',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Prepare for your upcoming week, trips, and special events.',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 16),
            ),
            const SizedBox(height: 30),
            PlanningCard(
              title: 'Week Planner',
              subtitle: 'Schedule your outfits for the next 7 days',
              icon: Icons.calendar_view_week,
              color: Colors.blue.shade400,
              onTap: controller.openWeekPlanner,
            ),
            const SizedBox(height: 20),
            PlanningCard(
              title: 'Trip Packer',
              subtitle: 'Create smart packing lists for your travels',
              icon: Icons.luggage,
              color: Colors.orange.shade400,
              onTap: controller.openTripPacker,
            ),
            const SizedBox(height: 20),
            PlanningCard(
              title: 'Event Series',
              subtitle: 'Coordinate looks for multi-day events',
              icon: Icons.event_available,
              color: Colors.pink.shade400,
              onTap: controller.createEvent,
            ),
            const SizedBox(height: 40),
            const Text(
              'Upcoming Plans',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            const _UpcomingPlans(),
          ],
        ),
      ),
    );
  }
}

class _UpcomingPlans extends GetView<PlanAheadController> {
  const _UpcomingPlans();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final plans = controller.plans;
      if (plans.isEmpty) return const PlansEmptyState();
      return Column(
        children: [
          for (final plan in plans) ...[
            UpcomingPlanCard(
              plan: plan,
              onTap: () => controller.openPlan(plan),
            ),
            const SizedBox(height: 12),
          ],
        ],
      );
    });
  }
}
