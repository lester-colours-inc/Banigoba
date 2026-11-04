// The provider side of the app: one card per role the user holds, each
// opening the screen that already exists for it. "Switch to customer" returns
// to the normal app without signing out.
import '../../../core/supabase/app_auth.dart';
import '../../../data/services/profile_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../data/models/provider_inbox.dart';
import '../../../data/models/provider_roles.dart';
import '../../../data/services/provider_inbox_service.dart';
import '../../../data/services/provider_service.dart';
import '../agents/agents_page.dart';
import '../designers/fashion_designers_page.dart';
import '../shop/seller_dashboard_page.dart';
import '../shop/shop_links_pages.dart';
import '../shop/shop_chat_page.dart';
import 'become_provider_page.dart';
import 'earnings_page.dart';
import 'provider_inbox_page.dart';

class ProviderHomePage extends StatelessWidget {
  const ProviderHomePage({super.key});

  static const Color _primary = Color(0xFF0D0140);

  Future<void> _switchToCustomer() async {
    final user = AppAuth.instance.currentUser;
    if (user == null) return;
    await ProviderService().setMode(user.uid, provider: false);
  }

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  Widget _pageFor(ProviderRole role) => switch (role) {
    ProviderRole.shop => const SellerDashboardPage(),
    ProviderRole.designer => const DesignerProfileEditorPage(),
    ProviderRole.salon => const AgentProfileEditorPage(),
  };

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

  @override
  Widget build(BuildContext context) {
    final user = AppAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider mode'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            key: const ValueKey('switch_to_customer'),
            onPressed: _switchToCustomer,
            icon: const Icon(Icons.person_outline, color: Colors.white),
            label: const Text(
              'Customer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: user == null
          ? const SizedBox.shrink()
          : StreamBuilder<Map<String, dynamic>>(
              stream: ProfileService().watch(user.uid),
              builder: (context, snapshot) {
                final data = snapshot.data ?? const <String, dynamic>{};
                final roles = providerRolesOf(data);
                final name = (data['displayName'] ?? '').toString();
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Your business',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InboxTile(
                      userId: user.uid,
                      roles: roles,
                      onOpen: () =>
                          _open(context, ProviderInboxPage(roles: roles)),
                    ),
                    const SizedBox(height: 12),
                    if (roles.contains(ProviderRole.shop)) ...[
                      Card(
                        child: ListTile(
                          key: const ValueKey('card_share_stock'),
                          contentPadding: const EdgeInsets.all(18),
                          leading: const CircleAvatar(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            child: Icon(Icons.qr_code_2),
                          ),
                          title: const Text(
                            'Share my stock',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                            'A link or QR to your stock for WhatsApp groups, '
                            'followers and the public: they try on and buy.',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _open(context, const ShopLinksPage()),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Card(
                      child: ListTile(
                        key: const ValueKey('card_earnings'),
                        contentPadding: const EdgeInsets.all(18),
                        leading: const CircleAvatar(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          child: Icon(Icons.account_balance_wallet_outlined),
                        ),
                        title: const Text(
                          'Earnings',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'Commission on your sales and your referral '
                          'earnings.',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _open(context, const EarningsPage()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final role in roles) ...[
                      Card(
                        child: ListTile(
                          key: ValueKey('card_${role.key}'),
                          contentPadding: const EdgeInsets.all(18),
                          leading: CircleAvatar(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            child: Icon(_cards[role]!.$1),
                          ),
                          title: Text(
                            role.label,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(_cards[role]!.$2),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _open(context, _pageFor(role)),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(18),
                        leading: const CircleAvatar(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          child: Icon(Icons.chat_bubble_outline),
                        ),
                        title: const Text(
                          'Messages',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'Answer customers who write to you.',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _open(
                          context,
                          const ShopChatInboxPage(sellerOnly: true),
                        ),
                      ),
                    ),
                    if (roles.length < ProviderRole.values.length) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        key: const ValueKey('add_role'),
                        onPressed: () => _open(
                          context,
                          BecomeProviderPage(held: roles, suggestedName: name),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Add another thing you offer'),
                      ),
                    ],
                  ],
                );
              },
            ),
    );
  }
}

/// "Orders & requests" with a count of what is waiting for an answer.
class _InboxTile extends StatefulWidget {
  const _InboxTile({
    required this.userId,
    required this.roles,
    required this.onOpen,
  });

  final String userId;
  final List<ProviderRole> roles;
  final VoidCallback onOpen;

  @override
  State<_InboxTile> createState() => _InboxTileState();
}

class _InboxTileState extends State<_InboxTile> {
  late Stream<List<InboxItem>> _items;

  @override
  void initState() {
    super.initState();
    _items = ProviderInboxService().watch(widget.userId, widget.roles);
  }

  @override
  void didUpdateWidget(_InboxTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.roles, widget.roles)) {
      _items = ProviderInboxService().watch(widget.userId, widget.roles);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InboxItem>>(
      stream: _items,
      builder: (context, snapshot) {
        final waiting = openCount(snapshot.data ?? const []);
        return Card(
          child: ListTile(
            key: const ValueKey('card_inbox'),
            contentPadding: const EdgeInsets.all(18),
            leading: CircleAvatar(
              backgroundColor: ProviderHomePage._primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.inbox_outlined),
            ),
            title: const Text(
              'Orders & requests',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              waiting == 0
                  ? 'Nothing waiting for you.'
                  : '$waiting waiting for your answer.',
            ),
            trailing: waiting == 0
                ? const Icon(Icons.arrow_forward_ios, size: 16)
                : Badge.count(count: waiting),
            onTap: widget.onOpen,
          ),
        );
      },
    );
  }
}
