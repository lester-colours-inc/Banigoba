// The Community / Events / Trending News pills on Discover.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/home/controllers/discover_controller.dart';

const Color _primaryColor = Color(0xFF0D0140);

class DiscoverTabs extends StatelessWidget {
  const DiscoverTabs({super.key, required this.controller});

  final DiscoverController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TabPill(controller: controller, title: 'Community', index: 0),
          const SizedBox(width: 15),
          _TabPill(controller: controller, title: 'Events', index: 1),
          const SizedBox(width: 15),
          _TabPill(controller: controller, title: 'Trending News', index: 2),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.controller,
    required this.title,
    required this.index,
  });

  final DiscoverController controller;
  final String title;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Obx(() {
      final isSelected = controller.selectedTab.value == index;
      return GestureDetector(
        onTap: () => controller.selectTab(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? _primaryColor : colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? _primaryColor : colors.outlineVariant,
              width: 1.5,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      );
    });
  }
}
