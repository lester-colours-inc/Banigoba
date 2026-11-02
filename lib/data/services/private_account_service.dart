// The signed-in person's private account details: the email they signed up
// with and their delivery or collection address. Only they can read them.
import '../../core/supabase/supabase_config.dart';

class PrivateAccountService {
  /// The saved address, or an empty map.
  Future<Map<String, dynamic>> address(String userId) async {
    final row = await supabase
        .from('private_account')
        .select('address')
        .eq('id', userId)
        .maybeSingle();
    final value = row?['address'];
    return value is Map ? Map<String, dynamic>.from(value) : {};
  }

  Future<void> saveAddress(String userId, Map<String, dynamic> address) async {
    await supabase.from('private_account').upsert({
      'id': userId,
      'address': address,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
