// Discover: the search text, the selected tab, and the people lookup.
import 'package:get/get.dart';

import 'package:banigoba/modules/settings/services/account_privacy_service.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';

class DiscoverController extends GetxController {
  DiscoverController({ProfileService? profiles, AccountPrivacyService? privacy})
    : _profiles = profiles ?? ProfileService(),
      _privacy = privacy ?? AccountPrivacyService();

  final ProfileService _profiles;
  final AccountPrivacyService _privacy;

  /// The trimmed, lower-case search text.
  final RxString query = ''.obs;

  /// The user registered for exactly the typed email, looked up by hash
  /// (U-5); null when the query is not a whole email.
  final Rxn<Future<String?>> emailMatch = Rxn<Future<String?>>();

  final RxInt selectedTab = 0.obs;

  void onSearchChanged(String value) {
    final text = value.trim().toLowerCase();
    query.value = text;
    emailMatch.value = looksLikeEmail(text)
        ? _privacy.findUserByEmail(text)
        : null;
  }

  void selectTab(int index) => selectedTab.value = index;

  /// People matching the search, plus the person whose full email was typed.
  Future<List<Map<String, dynamic>>> loadPeople(String emailMatchId) async {
    final people = await _profiles.searchPeople(query.value);
    if (emailMatchId.isEmpty || people.any((p) => p['id'] == emailMatchId)) {
      return people;
    }
    final match = await _profiles.get(emailMatchId);
    return match.isEmpty ? people : [...people, match];
  }
}
