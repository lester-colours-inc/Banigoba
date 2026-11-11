import 'package:banigoba/modules/provider/models/provider_roles.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';

class ProviderService {
  ProviderService({ProfileService? profiles})
    : _profiles = profiles ?? ProfileService();

  final ProfileService _profiles;

  /// Switches between the customer and provider sides without signing out.
  Future<void> setMode(String userId, {required bool provider}) {
    return _profiles.update(userId, {'providerMode': provider});
  }

  /// Adds [added] roles to the ones in [held], creating their profiles, and
  /// switches to provider mode. Roles already held keep their profiles, and
  /// anything already saved inside a profile (such as delivery settings) is
  /// kept.
  Future<void> become({
    required String userId,
    required List<ProviderRole> held,
    required List<ProviderRole> added,
    required String businessName,
    required String location,
  }) async {
    final update = providerProfileUpdate(
      roles: added,
      businessName: businessName,
      location: location,
    );
    final changes = <String, dynamic>{
      'providerMode': true,
      'providerRoles': [
        for (final role in ProviderRole.values)
          if (held.contains(role) || added.contains(role)) role.key,
      ],
    };
    final existing = await _profiles.get(userId);
    for (final key in const ['shop', 'designerProfile', 'agentProfile']) {
      final fresh = update[key];
      if (fresh is! Map) continue;
      final current = existing[key];
      changes[key] = {
        if (current is Map) ...Map<String, dynamic>.from(current),
        ...Map<String, dynamic>.from(fresh),
      };
    }
    // `verified` is set by curators only and never written from here.
    for (final key in const ['shop', 'designerProfile', 'agentProfile']) {
      (changes[key] as Map?)?.remove('verified');
    }
    await _profiles.update(userId, changes);
  }
}
