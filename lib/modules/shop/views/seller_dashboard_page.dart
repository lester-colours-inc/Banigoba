// The shop screen inside provider mode, for boutique owners.
//
// Three tabs: Home (what needs doing and the shop's activity timeline), Stock
// (products and inventory) and Messages (customer conversations). The
// storefront details and delivery live behind the Shop profile button.
// The products, orders and conversations are each streamed once here and
// shared by the tabs.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/utils/stock_status.dart';
import 'package:banigoba/modules/shop/controllers/admin_products_controller.dart';
import 'package:banigoba/modules/shop/controllers/seller_dashboard_controller.dart';
import 'package:banigoba/modules/shop/controllers/seller_orders_controller.dart';
import 'package:banigoba/modules/shop/controllers/shop_chat_inbox_controller.dart';
import 'package:banigoba/modules/shop/views/admin_products_page.dart';
import 'package:banigoba/modules/shop/views/seller_orders_page.dart';
import 'package:banigoba/modules/shop/views/shop_chat_page.dart';
import 'package:banigoba/modules/shop/views/shop_home_tab.dart';
import 'package:banigoba/modules/shop/views/shop_profile_page.dart';

class SellerDashboardPage extends StatelessWidget {
  const SellerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Each controller is scoped to this screen: created and disposed with it.
    return GetBuilder<SellerDashboardController>(
      init: SellerDashboardController(),
      global: false,
      builder: (shop) => GetBuilder<AdminProductsController>(
        init: AdminProductsController(),
        global: false,
        builder: (stock) => GetBuilder<SellerOrdersController>(
          init: SellerOrdersController(),
          global: false,
          builder: (orders) => GetBuilder<ShopChatInboxController>(
            init: ShopChatInboxController(sellerOnly: true),
            global: false,
            builder: (inbox) => _ShopDashboardView(
              shop: shop,
              stock: stock,
              orders: orders,
              inbox: inbox,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopDashboardView extends StatelessWidget {
  const _ShopDashboardView({
    required this.shop,
    required this.stock,
    required this.orders,
    required this.inbox,
  });

  static const _primary = Color(0xFF0D0140);
  static const _homeTab = 0;
  static const _stockTab = 1;
  static const _messagesTab = 2;

  final SellerDashboardController shop;
  final AdminProductsController stock;
  final SellerOrdersController orders;
  final ShopChatInboxController inbox;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Builder(
        builder: (context) {
          final tabs = DefaultTabController.of(context);
          return Scaffold(
            appBar: AppBar(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              toolbarHeight: 68,
              titleSpacing: 0,
              title: Obx(() => _ShopTitle(name: shop.title.value)),
              actions: [
                IconButton(
                  key: const ValueKey('shop_profile_button'),
                  tooltip: 'Shop profile',
                  icon: const Icon(Icons.manage_accounts_outlined),
                  onPressed: () =>
                      Get.to<void>(() => ShopProfilePage(controller: shop)),
                ),
                const SizedBox(width: 4),
              ],
              bottom: _tabBar(),
            ),
            body: TabBarView(
              children: [
                ShopHomeTab(
                  stock: stock,
                  orders: orders,
                  inbox: inbox,
                  onOpenOrders: () =>
                      Get.to<void>(() => const SellerOrdersPage()),
                  onOpenStock: (level) {
                    stock.filterBy(level);
                    tabs.animateTo(_stockTab);
                  },
                  onOpenMessages: () => tabs.animateTo(_messagesTab),
                ),
                AdminProductsView(controller: stock, showAppBar: false),
                ShopChatInboxList(controller: inbox),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _tabBar() {
    return TabBar(
      key: const ValueKey('shop_tabs'),
      indicatorColor: Colors.white,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white60,
      dividerColor: Colors.transparent,
      labelStyle: const TextStyle(fontWeight: FontWeight.w800),
      tabs: [
        const Tab(
          key: ValueKey('tab_home_$_homeTab'),
          icon: Icon(Icons.timeline),
          text: 'Home',
          iconMargin: EdgeInsets.only(bottom: 4),
        ),
        Tab(
          key: const ValueKey('tab_stock_$_stockTab'),
          iconMargin: const EdgeInsets.only(bottom: 4),
          icon: Obx(() {
            final summary = summarizeStock(stock.products);
            return Badge(
              isLabelVisible: summary.low + summary.soldOut > 0,
              backgroundColor: const Color(0xFFF59E0B),
              smallSize: 8,
              child: const Icon(Icons.inventory_2_outlined),
            );
          }),
          text: 'Stock',
        ),
        Tab(
          key: const ValueKey('tab_messages_$_messagesTab'),
          iconMargin: const EdgeInsets.only(bottom: 4),
          icon: Obx(() {
            final unread = inbox.chats
                .where((c) => ((c['unreadBySeller'] as num?)?.toInt() ?? 0) > 0)
                .length;
            return Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.chat_bubble_outline),
            );
          }),
          text: 'Messages',
        ),
      ],
    );
  }
}

/// The shop's initial in a circle, its name, and what this screen is.
class _ShopTitle extends StatelessWidget {
  const _ShopTitle({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'S' : name.trim()[0].toUpperCase();
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0D0140),
          child: Text(
            initial,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'Your shop',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
