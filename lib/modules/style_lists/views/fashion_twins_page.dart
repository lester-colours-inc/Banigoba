// My Fashion Twins (October 2026 review, F-1): people on Banigoba whose
// style is like yours. Find them by name or @username, add them, and they
// are followed too, so their looks come into your feeds (no separate
// timeline, F-4).
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/home/views/search_page.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/modules/style_lists/controllers/fashion_twins_controller.dart';
import 'package:banigoba/modules/style_lists/services/style_lists_service.dart';

class FashionTwinsPage extends StatelessWidget {
  const FashionTwinsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: created and disposed with the widget.
    return GetBuilder<FashionTwinsController>(
      init: FashionTwinsController(),
      global: false,
      builder: (controller) => _TwinsView(controller: controller),
    );
  }
}

class _TwinsView extends StatelessWidget {
  const _TwinsView({required this.controller});

  final FashionTwinsController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('My Fashion Twins')),
      body: StreamBuilder<List<StyleListEntry>>(
        stream: controller.twins,
        builder: (context, snapshot) {
          final twins = snapshot.data ?? const <StyleListEntry>[];
          final twinIds = {for (final twin in twins) twin.id};
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                'People whose style is like yours. Their looks come into '
                'your feeds, and you can copy one onto yourself in a '
                'makeover.',
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('twins_search'),
                onChanged: controller.onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Find people by name or @username',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              Obx(
                () => controller.query.value.isEmpty
                    ? const SizedBox.shrink()
                    : _Results(controller: controller, twinIds: twinIds),
              ),
              const SizedBox(height: 24),
              Text(
                twins.isEmpty
                    ? 'No Fashion Twins yet'
                    : 'Your Fashion Twins (${twins.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (twins.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Search above to add your first one.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
              for (final twin in twins)
                _PersonTile(
                  key: ValueKey('twin_${twin.id}'),
                  name: twin.name,
                  username: twin.username,
                  imageUrl: twin.imageUrl,
                  onTap: () => controller.openProfile(twin.id),
                  trailing: IconButton(
                    tooltip: 'Remove from Fashion Twins',
                    icon: const Icon(Icons.person_remove_outlined),
                    onPressed: () => controller.removeTwin(twin.id),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.controller, required this.twinIds});

  final FashionTwinsController controller;
  final Set<String> twinIds;

  @override
  Widget build(BuildContext context) {
    final query = controller.query.value;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ProfileService().searchPeople(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final people = snapshot.data!
            .where(
              (person) =>
                  person['id'] != controller.userId &&
                  matchesPersonSearch(person, query),
            )
            .take(20)
            .toList();
        if (people.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text('Nobody found for "$query".'),
          );
        }
        return Column(
          children: [
            for (final person in people)
              _PersonTile(
                key: ValueKey('twin_result_${person['id']}'),
                name: (person['displayName'] ?? 'User').toString(),
                username: (person['username'] ?? '').toString(),
                imageUrl: (person['profileImageUrl'] ?? '').toString(),
                onTap: () => controller.openProfile(person['id'].toString()),
                trailing: twinIds.contains(person['id'])
                    ? const Chip(label: Text('Twin'))
                    : FilledButton.tonal(
                        key: ValueKey('add_twin_${person['id']}'),
                        onPressed: () =>
                            controller.addTwin(person['id'].toString(), person),
                        child: const Text('Add'),
                      ),
              ),
          ],
        );
      },
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({
    super.key,
    required this.name,
    required this.username,
    required this.imageUrl,
    required this.onTap,
    required this.trailing,
  });

  final String name;
  final String username;
  final String imageUrl;
  final VoidCallback onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundImage: imageUrl.isEmpty
            ? null
            : CachedNetworkImageProvider(imageUrl),
        child: imageUrl.isEmpty
            ? Text(name.isEmpty ? '?' : name[0].toUpperCase())
            : null,
      ),
      title: Text(name),
      subtitle: username.isEmpty ? null : Text('@$username'),
      trailing: trailing,
    );
  }
}
