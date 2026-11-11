// "Orders & requests": one inbox for every role a provider holds (S-3).
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:flutter/material.dart';

import 'package:banigoba/modules/provider/models/provider_inbox.dart';
import 'package:banigoba/modules/provider/models/provider_roles.dart';
import 'package:banigoba/modules/provider/services/provider_inbox_service.dart';
import 'package:banigoba/modules/shop/views/seller_orders_page.dart';
import 'package:banigoba/modules/provider/views/provider_inbox_view.dart';
import 'package:banigoba/modules/provider/views/request_detail_sheet.dart';

class ProviderInboxPage extends StatefulWidget {
  const ProviderInboxPage({super.key, required this.roles});

  final List<ProviderRole> roles;

  @override
  State<ProviderInboxPage> createState() => _ProviderInboxPageState();
}

class _ProviderInboxPageState extends State<ProviderInboxPage> {
  static const Color _primary = Color(0xFF0D0140);
  final ProviderInboxService _service = ProviderInboxService();
  late final Stream<List<InboxItem>>? _items;

  @override
  void initState() {
    super.initState();
    final user = AppAuth.instance.currentUser;
    _items = user == null ? null : _service.watch(user.uid, widget.roles);
  }

  void _open(InboxItem item) {
    if (item.kind == InboxKind.order) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const SellerOrdersPage()),
      );
      return;
    }
    showRequestDetailSheet(
      context,
      item: item,
      onRespond: (status) => _service.respond(
        item: item,
        status: status,
        providerName:
            AppAuth.instance.currentUser?.displayName ?? 'Your business',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders & requests'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
      body: _items == null
          ? const Center(child: Text('Sign in to see your orders.'))
          : StreamBuilder<List<InboxItem>>(
              stream: _items,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ProviderInboxView(items: snapshot.data!, onOpen: _open);
              },
            ),
    );
  }
}
