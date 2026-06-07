// Provides planning shortcuts for future outfits and wardrobe activities.
import 'package:flutter/material.dart';

/// Hub for planning outfits in advance, including weekly planning and trip packing.
class PlanAheadPage extends StatelessWidget {
  const PlanAheadPage({super.key});

  static const Color primaryColor = Color(0xFF0D0140);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Plan Ahead',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Organize Your Style",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Prepare for your upcoming week, trips, and special events.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 30),
            _buildPlanningCard(
              context,
              title: "Week Planner",
              subtitle: "Schedule your outfits for the next 7 days",
              icon: Icons.calendar_view_week,
              color: Colors.blue.shade400,
              onTap: () {
                // Future: Navigate to Week Planner details
              },
            ),
            const SizedBox(height: 20),
            _buildPlanningCard(
              context,
              title: "Trip Packer",
              subtitle: "Create smart packing lists for your travels",
              icon: Icons.luggage,
              color: Colors.orange.shade400,
              onTap: () {
                // Future: Navigate to Trip Packer details
              },
            ),
            const SizedBox(height: 20),
            _buildPlanningCard(
              context,
              title: "Event Series",
              subtitle: "Coordinate looks for multi-day events",
              icon: Icons.event_available,
              color: Colors.pink.shade400,
              onTap: () {
                // Future: Navigate to Event Series details
              },
            ),
            const SizedBox(height: 40),
            const Text(
              "Upcoming Plans",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanningCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome, size: 50, color: Colors.orange.shade200),
          const SizedBox(height: 20),
          const Text(
            "No plans scheduled yet",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "Start by scheduling your first outfit\nor creating a packing list.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
