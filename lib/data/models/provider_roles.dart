// Provider mode (review items S-1 to S-4): any user can switch between
// Customer and Provider, like passenger and driver in InDrive. One person can
// be a shop, a designer and a salon at once.
//
// The roles are stored as `providerRoles` and the side last used as
// `providerMode`. Shops, designers and salons set up before provider mode
// existed are recognised from their old fields, so nobody registers twice.
enum ProviderRole {
  shop('shop', 'My Shop'),
  designer('designer', 'My Designs'),
  salon('salon', 'My Salon');

  const ProviderRole(this.key, this.label);

  final String key;
  final String label;

  static ProviderRole? fromKey(Object? key) {
    for (final role in values) {
      if (role.key == key) return role;
    }
    return null;
  }
}

bool _isActive(Object? profile) => profile is Map && profile['active'] == true;

/// The roles a user holds, once each, in a fixed order.
List<ProviderRole> providerRolesOf(Map<String, dynamic> user) {
  final found = <ProviderRole>{};
  if (user['providerRoles'] case final List stored) {
    for (final key in stored) {
      if (ProviderRole.fromKey(key) case final role?) found.add(role);
    }
  }
  final shop = user['shop'];
  if (user['isSeller'] == true ||
      user['sellerMode'] == true ||
      (shop is Map && (shop['name'] ?? '').toString().trim().isNotEmpty)) {
    found.add(ProviderRole.shop);
  }
  if (_isActive(user['designerProfile'])) found.add(ProviderRole.designer);
  final agent = user['agentProfile'];
  if (_isActive(agent) && (agent as Map)['type'] == 'hair') {
    found.add(ProviderRole.salon);
  }
  return [
    for (final role in ProviderRole.values)
      if (found.contains(role)) role,
  ];
}

/// True when the user is on the provider side. Until a user first switches,
/// the old Seller Mode switch decides.
bool isProviderMode(Map<String, dynamic> user) {
  if (providerRolesOf(user).isEmpty) return false;
  final mode = user['providerMode'];
  return mode is bool ? mode : user['sellerMode'] == true;
}

/// What "Become a provider" writes: a section for each chosen role plus the
/// role list. Never includes `verified`; curators set that.
Map<String, Object?> providerProfileUpdate({
  required List<ProviderRole> roles,
  required String businessName,
  required String location,
}) {
  final name = businessName.trim();
  final place = location.trim();
  final chosen = [
    for (final role in ProviderRole.values)
      if (roles.contains(role)) role,
  ];
  return {
    'providerRoles': [for (final role in chosen) role.key],
    'providerMode': true,
    if (chosen.contains(ProviderRole.shop)) ...{
      'isSeller': true,
      'shop': {'name': name, if (place.isNotEmpty) 'location': place},
    },
    if (chosen.contains(ProviderRole.designer)) ...{
      'isDesigner': true,
      'designerProfile': {'active': true, 'name': name, 'location': place},
    },
    if (chosen.contains(ProviderRole.salon)) ...{
      'isAgent': true,
      'agentProfile': {
        'active': true,
        'type': 'hair',
        'name': name,
        'location': place,
      },
    },
  };
}
