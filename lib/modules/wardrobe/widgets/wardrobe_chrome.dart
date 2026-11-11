// The wardrobe's tab bar, floating Add Item button and app-bar actions.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/shop/widgets/cart_badge_button.dart';
import 'package:banigoba/modules/wardrobe/controllers/wardrobe_controller.dart';

const Color wardrobePrimary = Color(0xFF0D0140);

class WardrobeTabBar extends StatelessWidget {
  const WardrobeTabBar({super.key, required this.controller});

  final WardrobeController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TabButton(controller: controller, title: 'My Clothes', index: 0),
          const SizedBox(width: 12),
          _TabButton(controller: controller, title: 'Saved Looks', index: 1),
          const SizedBox(width: 12),
          _TabButton(
            controller: controller,
            title: 'Shops & Designers',
            index: 2,
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.controller,
    required this.title,
    required this.index,
  });

  final WardrobeController controller;
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
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? wardrobePrimary : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? wardrobePrimary : colors.outlineVariant,
              width: 1.5,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      );
    });
  }
}

/// Floating Add Item button.
class AddItemButton extends StatelessWidget {
  const AddItemButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: wardrobePrimary,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: wardrobePrimary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'Add Item',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WardrobeCartAction extends StatelessWidget {
  const WardrobeCartAction({super.key, required this.controller});

  final WardrobeController controller;

  @override
  Widget build(BuildContext context) {
    return CartBadgeButton(
      onPressed: controller.openCart,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
}

class WardrobeNotificationsAction extends StatelessWidget {
  const WardrobeNotificationsAction({super.key, required this.controller});

  final WardrobeController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_none_rounded,
            color: colors.onSurface,
            size: 28,
          ),
          onPressed: controller.openNotifications,
        ),
        Obx(() {
          final unreadCount = controller.unreadCount.value;
          if (unreadCount == 0) return const SizedBox.shrink();
          return Positioned(
            right: 5,
            top: 5,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.surface, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
