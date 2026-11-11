// Settings › Privacy & safety: the AI photo switch, blocked people, the
// Privacy Policy and Terms, and deleting the account (App Store guidelines
// 1.2, 5.1.1 and 5.1.2).
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/legal_links.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/modules/settings/services/safety_service.dart';
import 'package:banigoba/modules/makeover/widgets/ai_photo_consent.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';
import 'package:banigoba/modules/settings/controllers/delete_confirm_controller.dart';
import 'package:banigoba/modules/settings/controllers/privacy_safety_controller.dart';

class PrivacySafetySection extends StatelessWidget {
  const PrivacySafetySection({super.key});

  @override
  Widget build(BuildContext context) {
    // Scoped to this section: created and disposed with the widget.
    return GetBuilder<PrivacySafetyController>(
      init: PrivacySafetyController(),
      global: false,
      builder: (controller) => _PrivacySafetyView(controller: controller),
    );
  }
}

class _PrivacySafetyView extends StatelessWidget {
  const _PrivacySafetyView({required this.controller});

  final PrivacySafetyController controller;

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (confirmed != true) return;
    await controller.deleteAccount();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        const Text(
          'Privacy & safety',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              Obx(
                () => SwitchListTile(
                  key: const ValueKey('ai_photo_consent_switch'),
                  secondary: const Icon(Icons.auto_awesome_outlined),
                  title: const Text('Use AI with my photos'),
                  subtitle: const Text(kAiPhotoDisclosure),
                  isThreeLine: true,
                  value: controller.aiAllowed.value ?? false,
                  onChanged: controller.aiAllowed.value == null
                      ? null
                      : controller.setAi,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                key: const ValueKey('blocked_people_tile'),
                leading: const Icon(Icons.person_off_outlined),
                title: const Text('Blocked people'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Get.to<void>(() => const BlockedPeoplePage()),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => openLegalPage(kPrivacyPolicyUrl),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terms of Use'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => openLegalPage(kTermsOfUseUrl),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final deleting = controller.deleting.value;
          return OutlinedButton.icon(
            key: const ValueKey('delete_account_button'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.error,
              side: BorderSide(color: colors.error),
            ),
            onPressed: deleting ? null : () => _deleteAccount(context),
            icon: deleting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_forever_outlined),
            label: Text(deleting ? 'Deleting your account…' : 'Delete account'),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Typing DELETE makes sure this is meant: it cannot be undone.
class _DeleteAccountDialog extends StatelessWidget {
  const _DeleteAccountDialog();

  @override
  Widget build(BuildContext context) {
    // Scoped to this dialog: created and disposed with the widget.
    return GetBuilder<DeleteConfirmController>(
      init: DeleteConfirmController(),
      global: false,
      builder: (confirm) => AlertDialog(
        title: const Text('Delete your account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This permanently deletes your profile, looks, wardrobe, photos, '
              'comments, messages and orders history. It cannot be undone.',
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('delete_account_confirm_field'),
              controller: confirm.text,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Type DELETE'),
              onChanged: (value) => confirm.typed.value = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          Obx(
            () => FilledButton(
              key: const ValueKey('delete_account_confirm'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: confirm.ready
                  ? () => Navigator.pop(context, true)
                  : null,
              child: const Text('Delete forever'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Everyone the person has blocked, each with Unblock.
class BlockedPeoplePage extends StatelessWidget {
  const BlockedPeoplePage({super.key});

  @override
  Widget build(BuildContext context) {
    final safety = SafetyService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked people')),
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: safety.blockedIds,
        builder: (context, ids, _) {
          if (ids.isEmpty) {
            return const Center(child: Text('You have not blocked anyone.'));
          }
          final list = ids.toList();
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                _BlockedTile(key: ValueKey(list[index]), userId: list[index]),
          );
        },
      ),
    );
  }
}

class _BlockedTile extends StatelessWidget {
  const _BlockedTile({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ProfileService().get(userId),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const {};
        final name = (data['displayName'] ?? '').toString();
        final username = (data['username'] ?? '').toString();
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(name.isEmpty ? 'Banigoba member' : name),
          subtitle: username.isEmpty ? null : Text('@$username'),
          trailing: TextButton(
            onPressed: () async {
              try {
                await SafetyService.instance.unblock(userId);
              } on Exception catch (error) {
                debugPrint('Unable to unblock: $error');
                AppToast.say('Could not unblock. Try again.');
              }
            },
            child: const Text('Unblock'),
          ),
        );
      },
    );
  }
}
