// The Customer / Provider switch at the top of the menu (S-1). Without a
// provider role it offers "Become a provider" instead.
import '../../core/supabase/app_auth.dart';
import '../../data/services/profile_service.dart';
import 'package:flutter/material.dart';

import '../../data/models/provider_roles.dart';
import '../../data/services/provider_service.dart';
import '../screens/provider/become_provider_page.dart';

class ProviderModeSwitch extends StatelessWidget {
  const ProviderModeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AppAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();
    return StreamBuilder<Map<String, dynamic>>(
      stream: ProfileService().watch(user.uid),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null || data.isEmpty) return const SizedBox.shrink();
        final roles = providerRolesOf(data);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: roles.isEmpty
              ? OutlinedButton.icon(
                  key: const ValueKey('become_provider'),
                  onPressed: () => Navigator.of(context)
                    ..pop()
                    ..push(
                      MaterialPageRoute<void>(
                        builder: (_) => BecomeProviderPage(
                          suggestedName: (data['displayName'] ?? '').toString(),
                        ),
                      ),
                    ),
                  icon: const Icon(Icons.storefront_outlined, size: 18),
                  label: const Text('Become a provider'),
                )
              : SegmentedButton<bool>(
                  key: const ValueKey('mode_switch'),
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: false, label: Text('Customer')),
                    ButtonSegment(value: true, label: Text('Provider')),
                  ],
                  selected: const {false},
                  onSelectionChanged: (choice) {
                    if (choice.first) {
                      ProviderService().setMode(user.uid, provider: true);
                    }
                  },
                ),
        );
      },
    );
  }
}
