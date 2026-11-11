// The All / Friends / Shops / Designers pills.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/notifications/controllers/notifications_controller.dart';

const Color _primaryColor = Color(0xFF0D0140);

class NotificationTabs extends StatelessWidget {
  const NotificationTabs({super.key, required this.controller});

  final NotificationsController controller;

  static const List<String> _titles = ['All', 'Friends', 'Shops', 'Designers'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Obx(() {
        final selected = controller.selectedTab.value;
        return Row(
          children: [
            for (var i = 0; i < _titles.length; i++) ...[
              if (i > 0) const SizedBox(width: 15),
              GestureDetector(
                onTap: () => controller.selectTab(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected == i ? _primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: selected == i
                          ? _primaryColor
                          : colors.surfaceContainerHighest,
                    ),
                  ),
                  child: Text(
                    _titles[i],
                    style: TextStyle(
                      color: selected == i ? Colors.white : colors.outline,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}
