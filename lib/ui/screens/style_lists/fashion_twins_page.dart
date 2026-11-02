// My Fashion Twins (October 2026 review, F-1): people on Banigoba whose
// style is like yours. Find them by name or @username, add them, and they
// are followed too, so their looks come into your feeds (no separate
// timeline, F-4).
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/supabase/app_auth.dart';
import '../../../data/services/profile_service.dart';
import 'package:flutter/material.dart';

import '../../../data/services/friend_service.dart';
import '../../../data/services/style_lists_service.dart';
import '../main/search_page.dart';
import '../social/profile_page.dart';

class FashionTwinsPage extends StatefulWidget {
  const FashionTwinsPage({super.key});

  @override
  State<FashionTwinsPage> createState() => _FashionTwinsPageState();
}

class _FashionTwinsPageState extends State<FashionTwinsPage> {
  final StyleListsService _lists = StyleListsService();
  final FriendService _friends = FriendService();
  final String _userId = AppAuth.instance.currentUser?.uid ?? '';
  late final Stream<List<StyleListEntry>> _twins = _lists.watch(
    _userId,
    StyleList.twins,
  );
  String _query = '';

  Future<void> _addTwin(String uid, Map<String, dynamic> data) async {
    final messenger = ScaffoldMessenger.of(context);
    final name = (data['displayName'] ?? data['name'] ?? 'User').toString();
    try {
      await _lists.add(
        _userId,
        StyleList.twins,
        StyleListEntry(
          id: uid,
          name: name,
          username: (data['username'] ?? '').toString(),
          imageUrl: (data['profileImageUrl'] ?? '')
              .toString(),
        ),
      );
      // Twins' looks reach your feeds through following them.
      final following = await _friends.isFollowing(uid).first;
      if (!following) await _friends.sendFollowRequest(uid);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            following
                ? '$name is now one of your Fashion Twins.'
                : '$name is now one of your Fashion Twins. We asked to '
                      'follow them so their looks reach your feed.',
          ),
        ),
      );
    } on FirebaseException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not add $name: ${error.message}')),
      );
    }
  }

  void _openProfile(String uid) => Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => ProfilePage(userId: uid)),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('My Fashion Twins')),
      body: StreamBuilder<List<StyleListEntry>>(
        stream: _twins,
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
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Find people by name or @username',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              if (_query.isNotEmpty) _buildResults(twinIds),
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
                  onTap: () => _openProfile(twin.id),
                  trailing: IconButton(
                    tooltip: 'Remove from Fashion Twins',
                    icon: const Icon(Icons.person_remove_outlined),
                    onPressed: () =>
                        _lists.remove(_userId, StyleList.twins, twin.id),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResults(Set<String> twinIds) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ProfileService().searchPeople(_query),
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
                  person['id'] != _userId &&
                  matchesPersonSearch(person, _query),
            )
            .take(20)
            .toList();
        if (people.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text('Nobody found for "$_query".'),
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
                onTap: () => _openProfile(person['id'].toString()),
                trailing: twinIds.contains(person['id'])
                    ? const Chip(label: Text('Twin'))
                    : FilledButton.tonal(
                        key: ValueKey('add_twin_${person['id']}'),
                        onPressed: () =>
                            _addTwin(person['id'].toString(), person),
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
