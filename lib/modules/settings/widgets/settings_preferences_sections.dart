// Settings sections for style, notifications, location, business and password.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/settings/controllers/settings_controller.dart';
import 'package:banigoba/modules/settings/widgets/settings_heading.dart';

const TextStyle _tileTitle = TextStyle(fontWeight: FontWeight.bold);

class SettingsPreferencesSections extends StatelessWidget {
  const SettingsPreferencesSections({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final hasPasswordProvider =
        AppAuth.instance.currentUser?.hasPassword ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsHeading('Style'),
        const SizedBox(height: 8),
        Obx(
          () => Card(
            child: ListTile(
              key: const ValueKey('settings_style_preferences'),
              leading: const Icon(Icons.style_outlined),
              title: const Text('Style preferences', style: _tileTitle),
              subtitle: const Text(
                'Styles you like and what a makeover should change.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: controller.saving.value
                  ? null
                  : controller.openStylePreferences,
            ),
          ),
        ),
        const SizedBox(height: 28),
        const SettingsHeading('Notifications'),
        const SizedBox(height: 8),
        Obx(
          () => Card(
            child: SwitchListTile(
              key: const ValueKey('notify_trending'),
              value: controller.notifyTrending.value,
              onChanged: controller.setNotifyTrending,
              secondary: const Icon(Icons.trending_up),
              title: const Text('Trending looks near me', style: _tileTitle),
              subtitle: const Text(
                'A look people in your city are talking about. At '
                'most one a day, and only when a look has real '
                'attention.',
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const SettingsHeading('Location'),
        const SizedBox(height: 8),
        Obx(
          () => Card(
            child: SwitchListTile(
              key: const ValueKey('use_location_switch'),
              value: controller.useLocation.value,
              onChanged: controller.setUseLocation,
              secondary: const Icon(Icons.my_location),
              title: const Text(
                'Use my location for Near me',
                style: _tileTitle,
              ),
              subtitle: const Text(
                'Only a rough area about 22 km wide is saved, never '
                'your exact position.',
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const SettingsHeading('Business'),
        const SizedBox(height: 8),
        Obx(() {
          final roles = controller.providerRoles.value;
          return Card(
            child: ListTile(
              key: const ValueKey('provider_mode_tile'),
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Business mode', style: _tileTitle),
              subtitle: Text(
                roles.isEmpty
                    ? 'Run a shop, design service or hair salon on '
                          'Banigoba.'
                    : 'Switch to your business: '
                          '${roles.map((r) => r.label).join(', ')}.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: controller.saving.value
                  ? null
                  : controller.openProviderMode,
            ),
          );
        }),
        const SizedBox(height: 28),
        const SettingsHeading('Password'),
        const SizedBox(height: 12),
        if (hasPasswordProvider) ...[
          SettingsField(
            controller: controller.currentPassword,
            label: 'Current password',
            obscureText: true,
          ),
          const SizedBox(height: 12),
          SettingsField(
            controller: controller.newPassword,
            label: 'New password',
            obscureText: true,
          ),
          const SizedBox(height: 12),
          Obx(
            () => OutlinedButton(
              onPressed: controller.saving.value
                  ? null
                  : controller.changePassword,
              child: const Text('Update Password'),
            ),
          ),
        ] else
          const Text('Password is managed by your social sign-in provider.'),
      ],
    );
  }
}
