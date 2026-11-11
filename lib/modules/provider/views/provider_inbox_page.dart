// "Orders & requests": one inbox for every role a provider holds (S-3).
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/provider/controllers/provider_inbox_controller.dart';
import 'package:banigoba/modules/provider/models/provider_inbox.dart';
import 'package:banigoba/modules/provider/models/provider_roles.dart';
import 'package:banigoba/modules/provider/views/provider_inbox_view.dart';
import 'package:banigoba/modules/provider/views/request_detail_sheet.dart';

class ProviderInboxPage extends StatelessWidget {
  const ProviderInboxPage({super.key, required this.roles});

  final List<ProviderRole> roles;

  static const Color _primary = Color(0xFF0D0140);

  void _open(BuildContext context, ProviderInboxController c, InboxItem item) {
    if (item.kind == InboxKind.order) {
      c.openOrders();
      return;
    }
    showRequestDetailSheet(
      context,
      item: item,
      onRespond: (status) => c.respond(item, status),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProviderInboxController>(
      init: ProviderInboxController(roles: roles),
      global: false,
      builder: (controller) => Scaffold(
        appBar: AppBar(
          title: const Text('Orders & requests'),
          backgroundColor: _primary,
          foregroundColor: Colors.white,
        ),
        body: !controller.signedIn
            ? const Center(child: Text('Sign in to see your orders.'))
            : Obx(() {
                if (!controller.loaded.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ProviderInboxView(
                  items: controller.items.toList(),
                  onOpen: (item) => _open(context, controller, item),
                );
              }),
      ),
    );
  }
}
