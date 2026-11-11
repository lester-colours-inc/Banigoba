// The single way into setting up a provider role (S-4). From any old
// "Create profile" button: someone who already holds the role goes straight
// to its editor; anyone else gets the one sign-up with that role ticked.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/provider/models/provider_roles.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/modules/provider/views/become_provider_page.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

Future<void> openProviderSetup(
  BuildContext context,
  ProviderRole role, {
  required Widget Function() editor,
}) async {
  final user = AppAuth.instance.currentUser;
  if (user == null) {
    AppToast.say('Sign in first.');
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
  await Get.to<void>(() => page);
}
