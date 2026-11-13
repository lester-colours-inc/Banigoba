// The signed-in person's private account details: the email they signed up
// with and their delivery or collection address. Only they can read them.
import 'package:banigoba/core/supabase/supabase_config.dart';

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

  /// Gender and date of birth (`gender`, `dateOfBirth` as a date), or nulls.
  Future<PersonalDetails> details(String userId) async {
    final row = await supabase
        .from('private_account')
        .select('gender, date_of_birth')
        .eq('id', userId)
        .maybeSingle();
    return PersonalDetails(
      gender: row?['gender']?.toString(),
      dateOfBirth: DateTime.tryParse((row?['date_of_birth'] ?? '').toString()),
    );
  }

  Future<void> saveDetails(String userId, PersonalDetails details) async {
    await supabase.from('private_account').upsert({
      'id': userId,
      'gender': details.gender,
      'date_of_birth': details.dateOfBirth == null
          ? null
          : _dateOnly(details.dateOfBirth!),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Private personal details used for shopping suggestions and age checks.
class PersonalDetails {
  const PersonalDetails({this.gender, this.dateOfBirth});

  /// 'male', 'female', 'non_binary', 'prefer_not' or null when unset.
  final String? gender;
  final DateTime? dateOfBirth;

  /// The product gender this person shops for first ('male' / 'female'), or
  /// null when unknown or not binary (then no gender is preferred).
  String? get shopsFor => switch (gender) {
    'male' || 'female' => gender,
    _ => null,
  };

  /// Whole years old on [today], or null without a birth date.
  int? ageOn(DateTime today) {
    final dob = dateOfBirth;
    if (dob == null) return null;
    final hadBirthday =
        today.month > dob.month ||
        (today.month == dob.month && today.day >= dob.day);
    return today.year - dob.year - (hadBirthday ? 0 : 1);
  }
}
