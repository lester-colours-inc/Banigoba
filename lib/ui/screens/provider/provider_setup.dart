// The single way into setting up a provider role (S-4). From any old
// "Create profile" button: someone who already holds the role goes straight
// to its editor; anyone else gets the one sign-up with that role ticked.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/models/provider_roles.dart';
import 'become_provider_page.dart';

Future<void> openProviderSetup(
  BuildContext context,
  ProviderRole role, {
  required Widget Function() editor,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  final messenger = ScaffoldMessenger.of(context);
  if (user == null) {
    messenger.showSnackBar(const SnackBar(content: Text('Sign in first.')));
    return;
  }
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  if (!context.mounted) return;
  final data = snapshot.data() ?? const <String, dynamic>{};
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
