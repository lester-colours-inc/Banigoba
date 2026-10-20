import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../core/app_routes.dart';
import '../../data/services/cart_service.dart';

class CartBadgeButton extends StatelessWidget {
  const CartBadgeButton({
    super.key,
    this.onPressed,
    this.color,
    this.iconSize = 28,
    this.tooltip = 'Cart',
  });

  final VoidCallback? onPressed;
  final Color? color;
  final double iconSize;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    // No badge without Firebase (widget tests and previews).
    final user = Firebase.apps.isEmpty
        ? null
        : FirebaseAuth.instance.currentUser;
    final iconButton = IconButton(
      tooltip: tooltip,
      onPressed:
          onPressed ?? () => Navigator.pushNamed(context, AppRoutes.cart),
      icon: Icon(Icons.shopping_bag_outlined, color: color, size: iconSize),
    );

    if (user == null) return iconButton;

    return StreamBuilder<int>(
      stream: CartService().watchItemCount(user.uid),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            iconButton,
            if (count > 0)
              Positioned(
                right: 5,
                top: 5,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
