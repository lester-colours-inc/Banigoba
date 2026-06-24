import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_products_page.dart';
import 'seller_orders_page.dart';
import 'shop_chat_page.dart';

class SellerDashboardPage extends StatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  State<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage> {
  static const _primary = Color(0xFF0D0140);
  final _shopName = TextEditingController();
  final _description = TextEditingController();
  final _contact = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadShop();
  }

  @override
  void dispose() {
    _shopName.dispose();
    _description.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _loadShop() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = snapshot.data() ?? const <String, dynamic>{};
    final shop = Map<String, dynamic>.from(data['shop'] as Map? ?? const {});
    _shopName.text =
        (shop['name'] ?? data['displayName'] ?? user.displayName ?? '')
            .toString();
    _description.text = (shop['description'] ?? '').toString();
    _contact.text = (shop['contact'] ?? user.email ?? '').toString();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveShop() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _saving) return;
    if (_shopName.text.trim().isEmpty) {
      _message('Enter your shop or boutique name.');
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isSeller': true,
        'shop': {
          'name': _shopName.text.trim(),
          'description': _description.text.trim(),
          'contact': _contact.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
      _message('Boutique details saved.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _leaveSellerMode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'sellerMode': false,
      'sellerModeUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Mode'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _leaveSellerMode,
            icon: const Icon(Icons.storefront_outlined, color: Colors.white),
            label: const Text(
              'Shop as Customer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Manage Your Boutique',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Update your storefront and manage the products customers can shop.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _shopName,
                  decoration: const InputDecoration(
                    labelText: 'Shop or boutique name',
                    prefixIcon: Icon(Icons.storefront),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _description,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Boutique description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _contact,
                  decoration: const InputDecoration(
                    labelText: 'Customer contact',
                    prefixIcon: Icon(Icons.alternate_email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: _saving ? null : _saveShop,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  child: Text(_saving ? 'Saving...' : 'Save Boutique'),
                ),
                const SizedBox(height: 28),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    leading: const CircleAvatar(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      child: Icon(Icons.inventory_2_outlined),
                    ),
                    title: const Text(
                      'Products & Inventory',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Add products, update prices and stock, or remove listings.',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const AdminProductsPage(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    leading: const CircleAvatar(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      child: Icon(Icons.receipt_long_outlined),
                    ),
                    title: const Text(
                      'Orders',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Review collection orders and update customer status.',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const SellerOrdersPage(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
                      'Answer product questions and help customers.',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const ShopChatInboxPage(sellerOnly: true),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
