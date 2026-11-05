// Settings › Privacy & safety: the AI photo switch, blocked people, the
// Privacy Policy and Terms, and deleting the account (App Store guidelines
// 1.2, 5.1.1 and 5.1.2).
import 'package:flutter/material.dart';

import '../../../core/legal_links.dart';
import '../../../data/services/profile_service.dart';
import '../../../data/services/safety_service.dart';
import '../../widgets/ai_photo_consent.dart';

class PrivacySafetySection extends StatefulWidget {
  const PrivacySafetySection({super.key});

  @override
  State<PrivacySafetySection> createState() => _PrivacySafetySectionState();
}

class _PrivacySafetySectionState extends State<PrivacySafetySection> {
  final _safety = SafetyService.instance;
  bool? _aiAllowed;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _safety.hasAiPhotoConsent().then(
      (allowed) {
        if (mounted) setState(() => _aiAllowed = allowed);
      },
      onError: (Object error) {
        debugPrint('Unable to read AI consent: $error');
        if (mounted) setState(() => _aiAllowed = false);
      },
    );
  }

  Future<void> _setAi(bool allowed) async {
    final before = _aiAllowed;
    setState(() => _aiAllowed = allowed);
    try {
      await _safety.setAiPhotoConsent(allowed);
    } on Exception catch (error) {
      debugPrint('Unable to save AI consent: $error');
      if (!mounted) return;
      setState(() => _aiAllowed = before);
      _say('Could not save. Please try again.');
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await _safety.deleteAccount();
      if (!mounted) return;
      // Signed out: back to the start, where the sign-in screen shows.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _deleting = false);
      _say(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _say(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

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
              SwitchListTile(
                key: const ValueKey('ai_photo_consent_switch'),
                secondary: const Icon(Icons.auto_awesome_outlined),
                title: const Text('Use AI with my photos'),
                subtitle: const Text(kAiPhotoDisclosure),
                isThreeLine: true,
                value: _aiAllowed ?? false,
                onChanged: _aiAllowed == null ? null : _setAi,
              ),
              const Divider(height: 1),
              ListTile(
                key: const ValueKey('blocked_people_tile'),
                leading: const Icon(Icons.person_off_outlined),
                title: const Text('Blocked people'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const BlockedPeoplePage(),
                  ),
                ),
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
        OutlinedButton.icon(
          key: const ValueKey('delete_account_button'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.error,
            side: BorderSide(color: colors.error),
          ),
          onPressed: _deleting ? null : _deleteAccount,
          icon: _deleting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_forever_outlined),
          label: Text(_deleting ? 'Deleting your account…' : 'Delete account'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Typing DELETE makes sure this is meant: it cannot be undone.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _confirm.text.trim().toUpperCase() == 'DELETE';
    return AlertDialog(
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
            controller: _confirm,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Type DELETE'),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('delete_account_confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: ready ? () => Navigator.pop(context, true) : null,
          child: const Text('Delete forever'),
        ),
      ],
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
              final messenger = ScaffoldMessenger.of(context);
              try {
                await SafetyService.instance.unblock(userId);
              } on Exception catch (error) {
                debugPrint('Unable to unblock: $error');
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Could not unblock. Try again.'),
                  ),
                );
              }
            },
            child: const Text('Unblock'),
          ),
        );
      },
    );
  }
}
