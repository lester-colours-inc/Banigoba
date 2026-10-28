// The provider side of the app: one card per role the user holds, each
// opening the screen that already exists for it. "Switch to customer" returns
// to the normal app without signing out.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/models/provider_roles.dart';
import '../../../data/services/provider_service.dart';
import '../agents/agents_page.dart';
import '../designers/fashion_designers_page.dart';
import '../shop/seller_dashboard_page.dart';
import '../shop/shop_chat_page.dart';
import 'become_provider_page.dart';

class ProviderHomePage extends StatelessWidget {
  const ProviderHomePage({super.key});

  static const Color _primary = Color(0xFF0D0140);

  Future<void> _switchToCustomer() async {
    final user = FirebaseAuth.instance.currentUser;
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
    final user = FirebaseAuth.instance.currentUser;
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
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() ?? const {};
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
