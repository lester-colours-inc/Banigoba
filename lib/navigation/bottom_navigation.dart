import 'package:flutter/material.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0D0140);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.white,
        unselectedItemColor: primaryColor,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        items: [
          _buildNavItem(Icons.home_outlined, Icons.home, 0),
          _buildNavItem(Icons.shopping_bag_outlined, Icons.shopping_bag, 1),
          _buildNavItem(Icons.shopping_cart_outlined, Icons.shopping_cart, 2),
          _buildNavItem(Icons.search, Icons.search, 3),
          _buildNavItem(Icons.person_outline, Icons.person, 4),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
      IconData icon, IconData activeIcon, int index) {
    bool isActive = currentIndex == index;
    return BottomNavigationBarItem(
      icon: isActive
          ? Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF0D0140),
                shape: BoxShape.circle,
              ),
              child: Icon(activeIcon, color: Colors.white),
            )
          : Icon(icon),
      label: '',
    );
  }
}
