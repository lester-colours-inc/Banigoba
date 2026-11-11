// The provider side of the app: one card per role the user holds, each
// opening the screen that already exists for it. "Switch to customer" returns
// to the normal app without signing out.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/agents/views/agents_page.dart';
import 'package:banigoba/modules/designers/views/fashion_designers_page.dart';
import 'package:banigoba/modules/provider/controllers/provider_home_controller.dart';
import 'package:banigoba/modules/provider/models/provider_roles.dart';
import 'package:banigoba/modules/provider/views/become_provider_page.dart';
import 'package:banigoba/modules/provider/views/earnings_page.dart';
import 'package:banigoba/modules/provider/views/provider_inbox_page.dart';
import 'package:banigoba/modules/provider/widgets/provider_nav_card.dart';
import 'package:banigoba/modules/shop/views/seller_dashboard_page.dart';
import 'package:banigoba/modules/shop/views/shop_chat_page.dart';
import 'package:banigoba/modules/shop/views/shop_links_pages.dart';

class ProviderHomePage extends StatelessWidget {
  const ProviderHomePage({super.key});

  static const Color _primary = ProviderNavCard.primary;

  static const Map<ProviderRole, (IconData, String)> _cards = {
    ProviderRole.shop: (
      Icons.storefront_outlined,
      'Your storefront, products, stock and orders.',
    ),
    ProviderRole.designer: (
      Icons.design_services_outlined,
      'Your portfolio and design requests.',
    ),
    ProviderRole.salon: (
      Icons.content_cut,
      'Your salon profile and hairstyle requests.',
    ),
  };

  static Widget _pageFor(ProviderRole role) => switch (role) {
    ProviderRole.shop => const SellerDashboardPage(),
    ProviderRole.designer => const DesignerProfileEditorPage(),
    ProviderRole.salon => const AgentProfileEditorPage(),
  };

  static void _open(Widget page) => Get.to<void>(() => page);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProviderHomeController>(
      init: ProviderHomeController(),
      global: false,
      builder: (controller) => Scaffold(
        appBar: AppBar(
          title: const Text('Business mode'),
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          actions: [
            TextButton.icon(
              key: const ValueKey('switch_to_customer'),
              onPressed: controller.switchToCustomer,
              icon: const Icon(Icons.person_outline, color: Colors.white),
              label: const Text(
                'Customer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: controller.userId == null
            ? const SizedBox.shrink()
            : Obx(() => _body(controller)),
      ),
    );
  }

  Widget _body(ProviderHomeController controller) {
    final roles = controller.roles.toList();
    final waiting = controller.waiting.value;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Your business',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ProviderNavCard(
          key: const ValueKey('card_inbox'),
          icon: Icons.inbox_outlined,
          title: 'Orders & requests',
          subtitle: waiting == 0
              ? 'Nothing waiting for you.'
              : '$waiting waiting for your answer.',
          trailing: waiting == 0 ? null : Badge.count(count: waiting),
          onTap: () => _open(ProviderInboxPage(roles: roles)),
        ),
        const SizedBox(height: 12),
        if (roles.contains(ProviderRole.shop)) ...[
          ProviderNavCard(
            key: const ValueKey('card_share_stock'),
            icon: Icons.qr_code_2,
            title: 'Share my stock',
            subtitle:
                'A link or QR to your stock for WhatsApp groups, '
                'followers and the public: they try on and buy.',
            onTap: () => _open(const ShopLinksPage()),
          ),
          const SizedBox(height: 12),
        ],
        ProviderNavCard(
          key: const ValueKey('card_earnings'),
          icon: Icons.account_balance_wallet_outlined,
          title: 'Earnings',
          subtitle: 'Commission on your sales and your referral earnings.',
          onTap: () => _open(const EarningsPage()),
        ),
        const SizedBox(height: 12),
        for (final role in roles) ...[
          ProviderNavCard(
            key: ValueKey('card_${role.key}'),
            icon: _cards[role]!.$1,
            title: role.label,
            subtitle: _cards[role]!.$2,
            onTap: () => _open(_pageFor(role)),
          ),
          const SizedBox(height: 12),
        ],
        ProviderNavCard(
          icon: Icons.chat_bubble_outline,
          title: 'Messages',
          subtitle: 'Answer customers who write to you.',
          onTap: () => _open(const ShopChatInboxPage(sellerOnly: true)),
        ),
        if (roles.length < ProviderRole.values.length) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const ValueKey('add_role'),
            onPressed: () => _open(
              BecomeProviderPage(
                held: roles,
                suggestedName: controller.name.value,
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add another thing you offer'),
          ),
        ],
      ],
    );
  }
}
