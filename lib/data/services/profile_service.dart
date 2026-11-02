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
}
