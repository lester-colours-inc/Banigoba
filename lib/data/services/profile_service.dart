// Reads and updates profiles: the public side of a user (name, @username,
// photo, city, provider settings). Email and address live in a private table.
import '../../core/supabase/supabase_config.dart';
import '../supabase/rows.dart';

class ProfileService {
  static const String _table = 'profiles';

  /// One profile as a camelCase map, or an empty map if there is none.
  Future<Map<String, dynamic>> get(String userId) async {
    final row = await supabase
        .from(_table)
        .select()
        .eq('id', userId)
        .maybeSingle();
    return row == null ? const {} : camelizeRow(row);
  }

  /// The profile now and every time it changes.
  Stream<Map<String, dynamic>> watch(String userId) {
    return supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) => rows.isEmpty ? const {} : camelizeRow(rows.first));
  }

  /// Saves [changes] (camelCase field names) onto the user's own profile.
  Future<void> update(String userId, Map<String, dynamic> changes) async {
    if (changes.isEmpty) return;
    await supabase
        .from(_table)
        .update({for (final e in changes.entries) snakeCase(e.key): e.value})
        .eq('id', userId);
  }

  /// Stamps "last seen"; best effort.
  Future<void> touchLastSeen(String userId) =>
      update(userId, {'lastSeen': DateTime.now().toUtc().toIso8601String()});

  /// People whose name or @username contains [query], A to Z by name.
  /// Returns camelCase maps with an `id`.
  Future<List<Map<String, dynamic>>> searchPeople(
    String query, {
    int limit = 40,
  }) async {
    // Characters that would change the meaning of the filter are dropped.
    final text = query.trim().replaceAll(RegExp(r'[%,()*\\]'), ' ').trim();
    final needle = text.startsWith('@') ? text.substring(1).trim() : text;
    if (needle.isEmpty) return const [];
    final rows = await supabase
        .from(_table)
        .select()
        .or('display_name.ilike.%$needle%,username.ilike.%$needle%')
        .order('display_name')
        .limit(limit);
    return [for (final row in rows) camelizeRow(row)];
  }

  /// Verified providers of [kind] ('salon', 'shop' or 'designer') as
  /// camelCase maps with an `id`. Salons and designers must also be active.
  Future<List<Map<String, dynamic>>> verifiedProviders(String kind) async {
    final base = supabase.from(_table).select();
    final rows = switch (kind) {
      'salon' =>
        await base
            .eq('agent_verified', true)
            .eq('agent_profile->>active', 'true')
            .eq('agent_profile->>type', 'hair'),
      'designer' =>
        await base
            .eq('designer_verified', true)
            .eq('designer_profile->>active', 'true'),
      _ => await base.eq('shop_verified', true),
    };
    return [for (final row in rows) camelizeRow(row)];
  }
}
