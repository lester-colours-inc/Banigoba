// The user's own style lists (October 2026 review, F-1 to F-3):
//   - Fashion Twins: people on Banigoba whose style is like theirs
//   - Fashion Idols: people they admire, on Banigoba or not, by name
//   - Hairstyles I like: pictures of hairstyles to try or show a salon
// Each list lives privately in `style_list_entries`; only the owner can read
// or change it (row-level security).
import 'package:flutter/foundation.dart';

import 'package:banigoba/core/supabase/supabase_config.dart';
import 'package:banigoba/core/supabase/rows.dart';
import 'package:banigoba/core/supabase/storage_files.dart' show randomFileName;

enum StyleList {
  twins('fashionTwins'),
  idols('fashionIdols'),
  hairstyles('hairInspiration');

  const StyleList(this.collection);

  final String collection;
}

/// One entry: a person (twin or idol) or a hairstyle picture.
@immutable
class StyleListEntry {
  const StyleListEntry({
    required this.id,
    required this.name,
    this.imageUrl = '',
    this.username = '',
    this.addedAt,
  });

  final String id;

  /// The person's name, or a note on a hairstyle.
  final String name;
  final String imageUrl;

  /// Twins only: their @username.
  final String username;
  final DateTime? addedAt;

  factory StyleListEntry.fromMap(String id, Map<String, dynamic> data) {
    return StyleListEntry(
      id: id,
      name: (data['name'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      username: (data['username'] ?? '').toString(),
      addedAt: asDateTime(data['addedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
    if (username.isNotEmpty) 'username': username,
  };
}

/// Newest first; entries still waiting for a server time come first.
List<StyleListEntry> sortNewestFirst(Iterable<StyleListEntry> entries) {
  final far = DateTime(9999);
  return List.unmodifiable(
    entries.toList()
      ..sort((a, b) => (b.addedAt ?? far).compareTo(a.addedAt ?? far)),
  );
}

/// A stable id for an idol typed by name, so adding the same name twice
/// keeps one entry: "Michelle Obama" -> "michelle-obama".
String idolIdFor(String name) => name
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

class StyleListsService {
  Stream<List<StyleListEntry>> watch(String userId, StyleList list) {
    if (userId.isEmpty) return Stream.value(const []);
    return supabase
        .from('style_list_entries')
        .stream(primaryKey: ['user_id', 'list', 'id'])
        .eq('user_id', userId)
        .map(
          (rows) => sortNewestFirst([
            for (final row in rows)
              if (row['list'] == list.collection)
                StyleListEntry.fromMap(row['id'].toString(), {
                  'name': row['name'],
                  'imageUrl': row['image_url'],
                  'username': row['username'],
                  'addedAt': row['added_at'],
                }),
          ]),
        );
  }

  /// Adds [entry] under its own id, or a new id when [entry.id] is empty.
  Future<void> add(String userId, StyleList list, StyleListEntry entry) async {
    await supabase.from('style_list_entries').upsert({
      'user_id': userId,
      'list': list.collection,
      'id': entry.id.isEmpty ? randomFileName('x').split('.').first : entry.id,
      'name': entry.name,
      'image_url': entry.imageUrl,
      'username': entry.username,
    });
  }

  Future<void> remove(String userId, StyleList list, String id) async {
    await supabase
        .from('style_list_entries')
        .delete()
        .eq('user_id', userId)
        .eq('list', list.collection)
        .eq('id', id);
  }
}
