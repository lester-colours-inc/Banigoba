import 'package:flutter_test/flutter_test.dart';

import 'package:banigoba/modules/settings/controllers/edit_profile_controller.dart';
import 'package:banigoba/modules/settings/services/private_account_service.dart';

void main() {
  final today = DateTime(2026, 11, 13);

  test('shopsFor only maps male and female', () {
    expect(const PersonalDetails(gender: 'male').shopsFor, 'male');
    expect(const PersonalDetails(gender: 'female').shopsFor, 'female');
    expect(const PersonalDetails(gender: 'non_binary').shopsFor, isNull);
    expect(const PersonalDetails().shopsFor, isNull);
  });

  test('ageOn accounts for birthdays not yet reached', () {
    expect(
      PersonalDetails(dateOfBirth: DateTime(2000, 11, 13)).ageOn(today),
      26,
    );
    expect(
      PersonalDetails(dateOfBirth: DateTime(2000, 11, 14)).ageOn(today),
      25,
    );
    expect(const PersonalDetails().ageOn(today), isNull);
  });

  test('validateDateOfBirth rejects future, too young and implausible', () {
    expect(validateDateOfBirth(null, today), isNull);
    expect(validateDateOfBirth(DateTime(1995, 5, 5), today), isNull);
    expect(validateDateOfBirth(DateTime(2027, 1, 1), today), isNotNull);
    expect(validateDateOfBirth(DateTime(2018, 1, 1), today), isNotNull);
    expect(validateDateOfBirth(DateTime(1900, 1, 1), today), isNotNull);
  });
}
