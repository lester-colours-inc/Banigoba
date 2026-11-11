// A list of provider profiles to verify (designers, shops or agents).
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/admin/controllers/profile_verification_controller.dart';

class ProfileVerificationList extends StatelessWidget {
  const ProfileVerificationList({
    super.key,
    required this.profileField,
    required this.titleFallback,
    required this.emptyText,
    required this.profileTypeLabel,
    this.requireActive = true,
  });

  final String profileField;
  final String titleFallback;
  final String emptyText;
  final String profileTypeLabel;
  final bool requireActive;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileVerificationController>(
      init: ProfileVerificationController(
        profileField: profileField,
        titleFallback: titleFallback,
        requireActive: requireActive,
      ),
      global: false,
      builder: (controller) => Obx(() {
        if (controller.failed.value) {
          return Center(
            child: Text('Unable to load $profileTypeLabel profiles.'),
          );
        }
        if (!controller.loaded.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final profiles = controller.profiles;
        if (profiles.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text(emptyText)),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: profiles.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = profiles[index];
            final profile = controller.profileOf(data);
            final userId = data['id'].toString();
            final title = controller.nameOf(profile, data);
            return ProfileVerificationCard(
              profileTypeLabel: profileTypeLabel,
              title: title,
              subtitle: ProfileVerificationController.subtitleOf(profile),
              verified: profile['verified'] == true,
              onSetVerified: (value) => controller.setVerified(
                userId: userId,
                title: title,
                value: value,
              ),
            );
          },
        );
      }),
    );
  }
}

class ProfileVerificationCard extends StatelessWidget {
  const ProfileVerificationCard({
    super.key,
    required this.profileTypeLabel,
    required this.title,
    required this.subtitle,
    required this.verified,
    required this.onSetVerified,
  });

  final String profileTypeLabel;
  final String title;
  final String subtitle;
  final bool verified;
  final ValueChanged<bool> onSetVerified;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: verified
                      ? Colors.green
                      : colors.surfaceContainerHighest,
                  foregroundColor: verified ? Colors.white : colors.onSurface,
                  child: Icon(
                    verified
                        ? Icons.verified_outlined
                        : Icons.pending_actions_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        verified
                            ? 'Verified $profileTypeLabel'
                            : 'Waiting for $profileTypeLabel verification',
                        style: TextStyle(
                          color: verified ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(subtitle),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: verified ? () => onSetVerified(false) : null,
                    icon: const Icon(Icons.visibility_off_outlined),
                    label: const Text('Unverify'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: verified ? null : () => onSetVerified(true),
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Verify'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D0140),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
