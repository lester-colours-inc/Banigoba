// Admin dashboard for marketplace curation.
//
// Curators use this workspace to approve public-facing content: hairstyle
// uploads, events, designers, boutiques, and agents. Verification flags stored
// on nested user profile maps control whether those profiles are visible in the
// customer marketplace.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/admin/controllers/curators_workspace_controller.dart';
import 'package:banigoba/modules/admin/widgets/admin_menu.dart';
import 'package:banigoba/modules/admin/widgets/event_verification_panel.dart';
import 'package:banigoba/modules/admin/widgets/hairstyle_catalog_panel.dart';
import 'package:banigoba/modules/admin/widgets/profile_verification_list.dart';

class CuratorsWorkspacePage extends GetView<CuratorsWorkspaceController> {
  const CuratorsWorkspacePage({super.key});

  static const _menuItems = [
    AdminMenuItem(
      label: 'Hair Uploads',
      icon: Icons.content_cut_outlined,
      title: 'Hairstyle Catalog',
    ),
    AdminMenuItem(
      label: 'Events',
      icon: Icons.event_available_outlined,
      title: 'Event Verification',
    ),
    AdminMenuItem(
      label: 'Designers',
      icon: Icons.design_services_outlined,
      title: 'Designer Verification',
    ),
    AdminMenuItem(
      label: 'Shops',
      icon: Icons.storefront_outlined,
      title: 'Shop Verification',
    ),
    AdminMenuItem(
      label: 'Agents',
      icon: Icons.support_agent_outlined,
      title: 'Agent Verification',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (controller.userId == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in as an admin to continue.')),
      );
    }
    return Obx(() {
      if (controller.profile.value == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (!controller.isAdmin) return _denied();
      return _workspace();
    });
  }

  Widget _logoutButton() => IconButton(
    tooltip: 'Logout',
    icon: const Icon(Icons.logout),
    onPressed: controller.signOut,
  );

  Widget _denied() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Curators Workspace'),
        actions: [_logoutButton()],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Admin access is required to open Curators Workspace.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _workspace() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Curators Workspace'),
        actions: [_logoutButton()],
      ),
      body: Obx(() {
        final tab = controller.tab.value;
        return Column(
          children: [
            AdminMenu(
              selectedIndex: tab,
              items: _menuItems,
              onSelected: controller.selectTab,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Text(
                    _menuItems[tab].title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (tab == 0) const HairstyleCatalogPanel(),
                  if (tab == 1)
                    EventVerificationPanel(service: controller.events),
                  if (tab == 2)
                    const ProfileVerificationList(
                      profileField: 'designerProfile',
                      titleFallback: 'Designer',
                      emptyText: 'No designer profiles to verify.',
                      profileTypeLabel: 'designer',
                    ),
                  if (tab == 3)
                    const ProfileVerificationList(
                      profileField: 'shop',
                      titleFallback: 'Shop',
                      emptyText: 'No shop profiles to verify.',
                      profileTypeLabel: 'shop',
                      requireActive: false,
                    ),
                  if (tab == 4)
                    const ProfileVerificationList(
                      profileField: 'agentProfile',
                      titleFallback: 'Agent',
                      emptyText: 'No agent profiles to verify.',
                      profileTypeLabel: 'agent',
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
