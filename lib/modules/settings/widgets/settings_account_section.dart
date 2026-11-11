// The top of Settings: profile photo, name, @username, email, address and the
// Save button.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/settings/controllers/settings_controller.dart';
import 'package:banigoba/modules/settings/widgets/settings_heading.dart';

const Color _primaryColor = Color(0xFF0D0140);

class SettingsPhoto extends StatelessWidget {
  const SettingsPhoto({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Obx(() {
        final url = controller.profileImageUrl.value;
        return Stack(
          children: [
            CircleAvatar(
              radius: 54,
              backgroundColor: _primaryColor,
              backgroundImage: url.isEmpty
                  ? null
                  : CachedNetworkImageProvider(url),
              child: url.isEmpty
                  ? const Icon(Icons.person, color: Colors.white, size: 54)
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: IconButton.filled(
                onPressed: controller.saving.value
                    ? null
                    : controller.pickProfilePicture,
                icon: const Icon(Icons.camera_alt_outlined),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class SettingsAccountSection extends StatelessWidget {
  const SettingsAccountSection({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsHeading('Account'),
        const SizedBox(height: 12),
        TextField(
          controller: controller.name,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        // The unique @handle (U-4); changed on its own screen so
        // availability can be checked as you type.
        Obx(
          () => Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              key: const ValueKey('settings_username'),
              leading: const Icon(Icons.alternate_email),
              title: Text(
                controller.username.value.isEmpty
                    ? 'Choose a username'
                    : '@${controller.username.value}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('How people find and mention you'),
              trailing: const Icon(Icons.chevron_right),
              onTap: controller.saving.value ? null : controller.changeUsername,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: AppAuth.instance.currentUser?.email ?? '',
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Email (private)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 26),
        const SettingsHeading('Address'),
        const SizedBox(height: 12),
        SettingsField(controller: controller.street, label: 'Street address'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SettingsField(
                controller: controller.city,
                label: 'City (public, for Near me)',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SettingsField(
                controller: controller.state,
                label: 'State',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SettingsField(
                controller: controller.postal,
                label: 'Postal code',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SettingsField(
                controller: controller.country,
                label: 'Country',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Obx(
          () => FilledButton(
            onPressed: controller.saving.value ? null : controller.saveProfile,
            style: FilledButton.styleFrom(
              backgroundColor: _primaryColor,
              minimumSize: const Size(double.infinity, 52),
            ),
            child: Text(
              controller.saving.value ? 'Saving...' : 'Save Settings',
            ),
          ),
        ),
      ],
    );
  }
}
