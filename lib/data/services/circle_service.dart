// My Circle: the salons, shops and designers a user has added as their own,
// so they come first whenever a look is sent (October 2026 review, P-6 and
// P-7). Stored privately in circle_entries; only the owner
// can read or change it (row-level security on circle_entries).
import 'package:flutter/foundation.dart';

import '../../core/supabase/supabase_config.dart';

/// What a Circle member is to the user.
enum CircleKind {
  salon('salon', 'Hair salons'),
  shop('shop', 'Shops'),
  designer('designer', 'Designers');

  const CircleKind(this.value, this.title);

  final String value;
  final String title;

  static CircleKind? fromValue(Object? value) {
    for (final kind in values) {
      if (kind.value == value) return kind;
    }
    return null;
  }
}

@immutable
class CircleMember {
  const CircleMember({
    required this.id,
    required this.kind,
    required this.name,
    this.avatarUrl = '',
    this.detail = '',
  });

  final String id;
  final CircleKind kind;
  final String name;
  final String avatarUrl;
  final String detail;

  static CircleMember? fromMap(String id, Map<String, dynamic> data) {
    final kind = CircleKind.fromValue(data['kind']);
    if (kind == null) return null;
    return CircleMember(
      id: id,
      kind: kind,
      name: (data['name'] ?? '').toString(),
      avatarUrl: (data['avatarUrl'] ?? '').toString(),
      detail: (data['detail'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'kind': kind.value,
    'name': name,
    'avatarUrl': avatarUrl,
    'detail': detail,
  };
}

class CircleService {
  /// Everyone in the user's Circle, A to Z.
  Stream<List<CircleMember>> watch(String userId) {
    if (userId.isEmpty) return Stream.value(const []);
    return supabase
        .from('circle_entries')
        .stream(primaryKey: ['user_id', 'kind', 'target_id'])
        .eq('user_id', userId)
        .map((rows) {
          final members =
              [
                for (final row in rows)
                  if (CircleMember.fromMap(row['target_id'].toString(), {
                        'kind': row['kind'],
                        'name': row['name'],
                        'avatarUrl': row['avatar_url'],
                        'detail': row['detail'],
                      })
                      case final member?)
                    member,
              ]..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );
          return List<CircleMember>.unmodifiable(members);
        });
  }

  Future<void> add(String userId, CircleMember member) async {
    await supabase.from('circle_entries').upsert({
      'user_id': userId,
      'kind': member.kind.value,
      'target_id': member.id,
      'name': member.name,
      'avatar_url': member.avatarUrl,
      'detail': member.detail,
    });
  }

  Future<void> remove(String userId, String memberId) async {
    await supabase
        .from('circle_entries')
        .delete()
        .eq('user_id', userId)
        .eq('target_id', memberId);
  }
}
