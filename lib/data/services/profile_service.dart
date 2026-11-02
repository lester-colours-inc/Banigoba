// Reads and updates profiles: the public side of a user (name, @username,
// photo, city, provider settings). Email and address live in a private table.
import '../../core/supabase/supabase_config.dart';
import '../supabase/rows.dart';

/// Provider settings live in jsonb (`shop`, `designerProfile`,
/// `agentProfile`) but "verified" is a guarded column, so reads fold it back
/// in as `verified` for the screens that look for `shop['verified']`.
const Map<String, String> _verifiedColumns = {
  'shop': 'shopVerified',
  'designerProfile': 'designerVerified',
  'agentProfile': 'agentVerified',
};

/// A `profiles` row as the screens read it.
Map<String, dynamic> profileMap(Map<String, dynamic> row) {
  final data = camelizeRow(row);
  for (final entry in _verifiedColumns.entries) {
    final profile = data[entry.key];
    if (profile is Map && profile.isNotEmpty) {
      data[entry.key] = {
        ...Map<String, dynamic>.from(profile),
        'verified': data[entry.value] == true,
      };
    }
  }
  return data;
}

class ProfileService {
  static const String _table = 'profiles';

  /// One profile as a camelCase map, or an empty map if there is none.
  Future<Map<String, dynamic>> get(String userId) async {
    final row = await supabase
        .from(_table)
        .select()
        .eq('id', userId)
        .maybeSingle();
    return row == null ? const {} : profileMap(row);
  }

  /// The profile now and every time it changes.
  Stream<Map<String, dynamic>> watch(String userId) {
    return supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) => rows.isEmpty ? const {} : profileMap(rows.first));
  }

  /// Saves [changes] (camelCase field names) onto the user's own profile.
  Future<void> update(String userId, Map<String, dynamic> changes) async {
    if (changes.isEmpty) return;
    final row = <String, dynamic>{};
    for (final entry in changes.entries) {
      var value = entry.value;
      // "verified" is its own guarded column; only a curator can change it.
      if (_verifiedColumns[entry.key] case final column? when value is Map) {
        final copy = Map<String, dynamic>.from(value);
        if (copy.containsKey('verified')) {
          row[snakeCase(column)] = copy.remove('verified');
        }
        value = copy;
      }
      row[snakeCase(entry.key)] = value;
    }
    await supabase.from(_table).update(row).eq('id', userId);
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
    return [for (final row in rows) profileMap(row)];
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
    return [for (final row in rows) profileMap(row)];
  }

  /// Every profile, live (for the curators' verification lists).
  Stream<List<Map<String, dynamic>>> watchAll() {
    return supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .map((rows) => [for (final row in rows) profileMap(row)]);
  }

  /// Adds [patch] to the provider section [field] (`shop`, `designerProfile`
  /// or `agentProfile`), keeping everything else already saved in it. Never
  /// writes `verified`.
  Future<void> mergeSection(
    String userId,
    String field,
    Map<String, dynamic> patch,
  ) async {
    final current = await get(userId);
    final merged = {
      if (current[field] is Map)
        ...Map<String, dynamic>.from(current[field] as Map),
      ...patch,
    }..remove('verified');
    await update(userId, {field: merged});
  }

  /// Verified, active providers of [kind] ('designer' or 'salon'), live.
  Stream<List<Map<String, dynamic>>> watchVerifiedProviders(String kind) {
    final isDesigner = kind == 'designer';
    final section = isDesigner ? 'designerProfile' : 'agentProfile';
    return supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq(isDesigner ? 'designer_verified' : 'agent_verified', true)
        .map(
          (rows) => [
            for (final row in rows)
              if (profileMap(row)[section] case final Map profile
                  when profile['active'] == true)
                profileMap(row),
          ],
        );
  }
}
