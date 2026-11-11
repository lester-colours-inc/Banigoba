// Searches community members and opens their social profiles.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/app/routes/app_routes.dart';
import 'package:banigoba/modules/events/views/events_page.dart';
import 'package:banigoba/modules/home/controllers/discover_controller.dart';
import 'package:banigoba/modules/home/widgets/discover_search_bar.dart';
import 'package:banigoba/modules/home/widgets/discover_tabs.dart';
import 'package:banigoba/modules/home/widgets/home_app_bar_action.dart';
import 'package:banigoba/modules/home/widgets/people_search_results.dart';
import 'package:banigoba/modules/notifications/widgets/notification_bell_button.dart';
import 'package:banigoba/shared/widgets/menu_or_back_button.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: created and disposed with the widget.
    return GetBuilder<DiscoverController>(
      init: DiscoverController(),
      global: false,
      builder: (controller) => _DiscoverView(controller: controller),
    );
  }
}

class _DiscoverView extends StatelessWidget {
  const _DiscoverView({required this.controller});

  final DiscoverController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: MenuOrBackButton(color: colors.onSurface),
        title: Row(
          children: [
            Expanded(
              // Matches the bottom bar's "Discover" tab (G-1).
              child: Text(
                'Discover',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
            ),
            NotificationBellButton(color: colors.onSurface),
            HomeCartAction(onPressed: () => Get.toNamed<void>(AppRoutes.cart)),
          ],
        ),
        actions: const [SizedBox(width: 20)],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            DiscoverSearchBar(onChanged: controller.onSearchChanged),
            const SizedBox(height: 25),
            DiscoverTabs(controller: controller),
            const SizedBox(height: 20),
            Expanded(
              child: Obx(
                () => switch (controller.selectedTab.value) {
                  0 => PeopleSearchResults(controller: controller),
                  1 => const EventsSection(embedded: true),
                  _ => const Center(child: Text('Trending News Coming Soon')),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Whether a user record matches a people search. Names and @usernames
/// match on any part;
/// an email only on the whole address, so emails stay private and cannot be
/// fished for (October 2026 review: "you don't want people using people's
/// emails"). [query] is already trimmed and lower-case.
bool matchesPersonSearch(Map<String, dynamic> data, String query) {
  if (query.isEmpty) return false;
  final name = (data['displayName'] ?? data['name'] ?? '')
      .toString()
      .toLowerCase();
  final email = (data['email'] ?? '').toString().trim().toLowerCase();
  final username = (data['username'] ?? '').toString().toLowerCase();
  final handle = query.startsWith('@') ? query.substring(1) : query;
  return name.contains(query) ||
      (handle.isNotEmpty && username.contains(handle)) ||
      (email.isNotEmpty && email == query);
}
