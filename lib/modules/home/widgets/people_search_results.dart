// The Community tab of Discover: a prompt, then people matching the search.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/home/controllers/discover_controller.dart';
import 'package:banigoba/modules/home/views/search_page.dart'
    show matchesPersonSearch;
import 'package:banigoba/modules/home/widgets/discover_empty_state.dart';
import 'package:banigoba/modules/home/widgets/person_result_tile.dart';

class PeopleSearchResults extends StatelessWidget {
  const PeopleSearchResults({super.key, required this.controller});

  final DiscoverController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final query = controller.query.value;
      if (query.isEmpty) {
        return const DiscoverEmptyState(
          icon: Icons.people_outline,
          title: 'Search to follow people',
          message:
              'Search by name or @username, or type their full email address, to follow them.',
        );
      }
      return FutureBuilder<String?>(
        future: controller.emailMatch.value,
        builder: (context, emailMatch) => _Results(
          controller: controller,
          emailMatchId: emailMatch.data ?? '',
        ),
      );
    });
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.controller, required this.emailMatchId});

  final DiscoverController controller;
  final String emailMatchId;

  @override
  Widget build(BuildContext context) {
    final query = controller.query.value;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: controller.loadPeople(emailMatchId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Unable to search people right now.'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentUserId = AppAuth.instance.currentUser?.uid;
        final people =
            (snapshot.data ?? []).where((person) {
              if (person['id'] == currentUserId) return false;
              return person['id'] == emailMatchId ||
                  matchesPersonSearch(person, query);
            }).toList()..sort((a, b) {
              final aName = (a['displayName'] ?? '').toString();
              final bName = (b['displayName'] ?? '').toString();
              return aName.toLowerCase().compareTo(bName.toLowerCase());
            });

        if (people.isEmpty) {
          return const DiscoverEmptyState(
            icon: Icons.person_search_outlined,
            title: 'No people found',
            message: 'Try another name, or their full email address.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: people.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              PersonResultTile(person: people[index]),
        );
      },
    );
  }
}
