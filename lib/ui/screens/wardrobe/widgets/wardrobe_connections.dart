// Smart Wardrobe › Shops & Designers: the way into the shops and designers
// the wardrobe draws on. A personal "connected" list comes later (review
// items P-7 and W-2); for now this opens the existing directories.
import 'package:flutter/material.dart';

import '../../../../core/app_routes.dart';

class WardrobeConnections extends StatelessWidget {
  const WardrobeConnections({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: const [
        _ConnectionCard(
          key: ValueKey('wardrobe_shops'),
          icon: Icons.storefront_outlined,
          title: 'Shops',
          subtitle: 'Browse boutiques and follow the ones you buy from.',
          route: AppRoutes.shops,
        ),
        SizedBox(height: 12),
        _ConnectionCard(
          key: ValueKey('wardrobe_designers'),
          icon: Icons.design_services_outlined,
          title: 'Fashion designers',
          subtitle: 'Find designers and follow their new collections.',
          route: AppRoutes.fashionDesigners,
        ),
        SizedBox(height: 12),
        _ConnectionCard(
          key: ValueKey('wardrobe_body_profile'),
          icon: Icons.straighten,
          title: 'My sizes and measurements',
          subtitle: 'So shops can suggest pieces that fit you.',
          route: AppRoutes.bodyProfile,
        ),
      ],
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colors.primaryContainer,
          child: Icon(icon, color: colors.onPrimaryContainer),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}
