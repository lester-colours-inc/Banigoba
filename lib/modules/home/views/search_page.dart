// Searches community members and opens their social profiles.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:flutter/material.dart';

import 'package:banigoba/app/routes/app_routes.dart';
import 'package:banigoba/modules/settings/services/account_privacy_service.dart';
import 'package:banigoba/modules/shop/widgets/cart_badge_button.dart';
import 'package:banigoba/modules/events/views/events_page.dart';
import 'package:banigoba/modules/social/views/profile_page.dart';
import 'package:banigoba/shared/widgets/menu_or_back_button.dart';
import 'package:banigoba/modules/notifications/widgets/notification_bell_button.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const Color primaryColor = Color(0xFF0D0140);

  String _searchQuery = '';

  /// The user registered for exactly the typed email, looked up by hash
  /// (U-5); null when the query is not a whole email.
  Future<String?>? _emailMatch;
  int _selectedTabIndex = 0;

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
            _buildAppBarAction(
              Icons.shopping_bag_outlined,
              () => Navigator.pushNamed(context, AppRoutes.cart),
            ),
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
            _buildSearchBar(),
            const SizedBox(height: 25),
            _buildTabs(),
            const SizedBox(height: 20),
            Expanded(
              child: _selectedTabIndex == 0
                  ? _buildPeopleSearch()
                  : _selectedTabIndex == 1
                  ? const EventsSection(embedded: true)
                  : const Center(child: Text('Trending News Coming Soon')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarAction(IconData icon, VoidCallback onTap) {
    if (icon == Icons.shopping_bag_outlined) {
      return CartBadgeButton(
        onPressed: onTap,
        color: Theme.of(context).colorScheme.onSurface,
      );
    }

    return IconButton(
      icon: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurface,
        size: 28,
      ),
      onPressed: onTap,
    );
  }

  Widget _buildSearchBar() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.outlineVariant, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.outline,
            size: 24,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search people by name or @username',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 16,
                ),
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                final query = value.trim().toLowerCase();
                setState(() {
                  _searchQuery = query;
                  _emailMatch = looksLikeEmail(query)
                      ? AccountPrivacyService().findUserByEmail(query)
                      : null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tabButton('Community', 0),
          const SizedBox(width: 15),
          _tabButton('Events', 1),
          const SizedBox(width: 15),
          _tabButton('Trending News', 2),
        ],
      ),
    );
  }

  Widget _tabButton(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? primaryColor : colors.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPeopleSearch() {
    if (_searchQuery.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: 'Search to follow people',
        message:
            'Search by name or @username, or type their full email address, to follow them.',
      );
    }

    return FutureBuilder<String?>(
      future: _emailMatch,
      builder: (context, emailMatch) =>
          _buildPeopleResults(emailMatch.data ?? ''),
    );
  }

  /// People matching the search, plus the person whose full email was typed.
  Future<List<Map<String, dynamic>>> _loadPeople(String emailMatchId) async {
    final profiles = ProfileService();
    final people = await profiles.searchPeople(_searchQuery);
    if (emailMatchId.isEmpty || people.any((p) => p['id'] == emailMatchId)) {
      return people;
    }
    final match = await profiles.get(emailMatchId);
    return match.isEmpty ? people : [...people, match];
  }

  Widget _buildPeopleResults(String emailMatchId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadPeople(emailMatchId),
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
                  matchesPersonSearch(person, _searchQuery);
            }).toList()..sort((a, b) {
              final aName = (a['displayName'] ?? '').toString();
              final bName = (b['displayName'] ?? '').toString();
              return aName.toLowerCase().compareTo(bName.toLowerCase());
            });

        if (people.isEmpty) {
          return _buildEmptyState(
            icon: Icons.person_search_outlined,
            title: 'No people found',
            message: 'Try another name, or their full email address.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: people.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final person = people[index];
            final data = person;
            final name = (data['displayName'] ?? data['name'] ?? 'User')
                .toString()
                .trim();
            final imageUrl = _profileImageUrl(data);
            final initial = name.isEmpty ? 'U' : name[0].toUpperCase();

            final colors = Theme.of(context).colorScheme;
            return Material(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProfilePage(userId: person['id'].toString()),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 27,
                        backgroundColor: primaryColor,
                        backgroundImage: imageUrl.isEmpty
                            ? null
                            : CachedNetworkImageProvider(imageUrl),
                        child: imageUrl.isEmpty
                            ? Text(
                                initial,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? 'User' : name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if ((data['username'] ?? '').toString()
                                case final username when username.isNotEmpty)
                              Text(
                                '@$username',
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _profileImageUrl(Map<String, dynamic> data) {
    final value =
        data['profileImageUrl'] ?? data['photoURL'] ?? data['photoUrl'];
    return value is String ? value.trim() : '';
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
