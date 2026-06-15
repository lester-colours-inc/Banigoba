// Searches community members and opens their social profiles.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/app_routes.dart';
import '../social/profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const Color primaryColor = Color(0xFF0D0140);

  String _searchQuery = '';
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: colors.onSurface),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Search',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
            ),
            _buildAppBarAction(
              Icons.shopping_bag_outlined,
              () => Navigator.pushNamed(context, AppRoutes.cart),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: colors.onSurface,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          const SizedBox(width: 20),
        ],
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
                  : Center(
                      child: Text(
                        _selectedTabIndex == 1
                            ? 'Events Coming Soon'
                            : 'Trending News Coming Soon',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarAction(IconData icon, VoidCallback onTap) {
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
                hintText: 'Search people by name or email',
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
                setState(() => _searchQuery = value.trim().toLowerCase());
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
        title: 'Find people in the community',
        message: 'Search by their name or email address.',
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Unable to search people right now.'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final people =
            (snapshot.data?.docs ?? []).where((doc) {
              if (doc.id == currentUserId) return false;
              final data = doc.data();
              final name = (data['displayName'] ?? data['name'] ?? '')
                  .toString()
                  .toLowerCase();
              final email = (data['email'] ?? '').toString().toLowerCase();
              return name.contains(_searchQuery) ||
                  email.contains(_searchQuery);
            }).toList()..sort((a, b) {
              final aName = (a.data()['displayName'] ?? '').toString();
              final bName = (b.data()['displayName'] ?? '').toString();
              return aName.toLowerCase().compareTo(bName.toLowerCase());
            });

        if (people.isEmpty) {
          return _buildEmptyState(
            icon: Icons.person_search_outlined,
            title: 'No people found',
            message: 'Try another name or email address.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: people.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final person = people[index];
            final data = person.data();
            final name = (data['displayName'] ?? data['name'] ?? 'User')
                .toString()
                .trim();
            final email = (data['email'] ?? '').toString();
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
                      builder: (_) => ProfilePage(userId: person.id),
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
                            : NetworkImage(imageUrl),
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
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
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
        data['profileImageURL'] ??
        data['profileImageUrl'] ??
        data['photoURL'] ??
        data['photoUrl'];
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
