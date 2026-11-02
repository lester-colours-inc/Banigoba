// The single way into setting up a provider role (S-4). From any old
// "Create profile" button: someone who already holds the role goes straight
// to its editor; anyone else gets the one sign-up with that role ticked.
import 'package:flutter/material.dart';

import '../../../core/supabase/app_auth.dart';
import '../../../data/models/provider_roles.dart';
import '../../../data/services/profile_service.dart';
import 'become_provider_page.dart';

Future<void> openProviderSetup(
  BuildContext context,
  ProviderRole role, {
  required Widget Function() editor,
}) async {
  final user = AppAuth.instance.currentUser;
  final messenger = ScaffoldMessenger.of(context);
  if (user == null) {
    messenger.showSnackBar(const SnackBar(content: Text('Sign in first.')));
    return;
  }
  final data = await ProfileService().get(user.uid);
  if (!context.mounted) return;
  final held = providerRolesOf(data);
  final page = held.contains(role)
      ? editor()
      : BecomeProviderPage(
          held: held,
          initialRoles: [role],
          suggestedName: (data['displayName'] ?? user.displayName ?? '')
              .toString(),
        );
  await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
}
