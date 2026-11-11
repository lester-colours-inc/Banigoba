// One door for shops, designers and salons (S-4): tick what you offer, give a
// business name and a place, and provider mode opens. Roles already held are
// shown ticked and left as they are.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/provider/controllers/become_provider_controller.dart';
import 'package:banigoba/modules/provider/models/provider_roles.dart';
import 'package:banigoba/modules/provider/services/provider_service.dart';

class BecomeProviderPage extends StatelessWidget {
  const BecomeProviderPage({
    super.key,
    this.held = const [],
    this.initialRoles = const [],
    this.suggestedName = '',
    this.service,
  });

  final List<ProviderRole> held;

  /// Roles ticked when the page opens, e.g. from a "Create salon profile"
  /// button.
  final List<ProviderRole> initialRoles;
  final String suggestedName;
  final ProviderService? service;

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: it is opened with the roles already held.
    return GetBuilder<BecomeProviderController>(
      init: BecomeProviderController(
        held: held,
        initialRoles: initialRoles,
        suggestedName: suggestedName,
        service: service,
      ),
      global: false,
      builder: (controller) => _BecomeProviderView(controller: controller),
    );
  }
}

class _BecomeProviderView extends StatelessWidget {
  const _BecomeProviderView({required this.controller});

  static const Color _primary = Color(0xFF0D0140);

  static const Map<ProviderRole, (IconData, String)> _blurbs = {
    ProviderRole.shop: (
      Icons.storefront_outlined,
      'Sell clothes and accessories, with photos, sizes and stock.',
    ),
    ProviderRole.designer: (
      Icons.design_services_outlined,
      'Show your portfolio and take design requests.',
    ),
    ProviderRole.salon: (
      Icons.content_cut,
      'Hair salon or stylist: take hairstyle bookings and requests.',
    ),
  };

  final BecomeProviderController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final held = controller.held;
    return Scaffold(
      appBar: AppBar(title: const Text('Business mode')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'What do you offer?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Tick everything that applies. You stay a customer too, and can '
            'switch sides any time.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Obx(
            () => Column(
              children: [
                for (final role in ProviderRole.values)
                  CheckboxListTile(
                    key: ValueKey('role_${role.key}'),
                    value:
                        held.contains(role) || controller.chosen.contains(role),
                    onChanged: held.contains(role)
                        ? null
                        : (on) => controller.toggleRole(role, on: on == true),
                    secondary: Icon(_blurbs[role]!.$1),
                    title: Text(
                      role.label.replaceFirst('My ', ''),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      held.contains(role)
                          ? 'Already set up'
                          : _blurbs[role]!.$2,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('business_name'),
            controller: controller.name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Business name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('business_location'),
            controller: controller.location,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Location (e.g. Harare, Avondale)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your listing appears to customers once a curator has verified it.',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
          ),
          Obx(() {
            final error = controller.error.value;
            if (error == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(error, style: TextStyle(color: colors.error)),
            );
          }),
          const SizedBox(height: 18),
          Obx(
            () => FilledButton(
              key: const ValueKey('start_provider'),
              onPressed: controller.saving.value ? null : controller.start,
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                minimumSize: const Size(double.infinity, 52),
              ),
              child: Text(
                controller.saving.value ? 'Saving...' : 'Start business mode',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
