// Reads and writes a user's provider side (see provider_roles.dart).
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/provider_roles.dart';

class ProviderService {
  ProviderService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _user(String userId) =>
      _db.collection('users').doc(userId);

  /// Switches between the customer and provider sides without signing out.
  Future<void> setMode(String userId, {required bool provider}) {
    return _user(userId).set({
      'providerMode': provider,
      'providerModeUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Adds [added] roles to the ones in [held], creating their profiles, and
  /// switches to provider mode. Roles already held keep their profiles.
  Future<void> become({
    required String userId,
    required List<ProviderRole> held,
    required List<ProviderRole> added,
    required String businessName,
    required String location,
  }) {
    final update = providerProfileUpdate(
      roles: added,
      businessName: businessName,
      location: location,
    );
    update['providerRoles'] = [
      for (final role in ProviderRole.values)
        if (held.contains(role) || added.contains(role)) role.key,
    ];
    update['providerModeUpdatedAt'] = FieldValue.serverTimestamp();
    return _user(userId).set(update, SetOptions(merge: true));
  }
}
