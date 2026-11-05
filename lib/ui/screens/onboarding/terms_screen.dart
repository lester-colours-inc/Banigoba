// Agreeing to the Terms of Use before using the community (App Store
// guideline 1.2): no tolerance for objectionable content or abusive people,
// and how to report and block. Shown once per Terms version, after sign-in.
import 'package:flutter/material.dart';

import '../../../core/legal_links.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key, required this.onAccept, this.onDecline});

  final Future<void> Function() onAccept;

  /// Declining signs out.
  final VoidCallback? onDecline;

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _agreed = false;
  bool _saving = false;

  Future<void> _accept() async {
    setState(() => _saving = true);
    try {
      await widget.onAccept();
    } on Exception catch (error) {
      debugPrint('Unable to save Terms acceptance: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Keeping Banigoba kind',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: const [
                    _Rule(
                      icon: Icons.block,
                      text:
                          'There is no tolerance for objectionable content or '
                          'abusive people: no harassment, hate, nudity, '
                          'violence, spam or impersonation.',
                    ),
                    _Rule(
                      icon: Icons.flag_outlined,
                      text:
                          'Report a look, comment or profile from its ⋯ menu. '
                          'We review reports within 24 hours and remove '
                          'content and accounts that break the rules.',
                    ),
                    _Rule(
                      icon: Icons.person_off_outlined,
                      text:
                          'Block anyone from their profile or their looks. '
                          'You will no longer see each other.',
                    ),
                    _Rule(
                      icon: Icons.lock_outline,
                      text:
                          'You choose who sees each look, and you can delete '
                          'your account and data at any time in Settings.',
                    ),
                  ],
                ),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => openLegalPage(kTermsOfUseUrl),
                    child: const Text('Terms of Use'),
                  ),
                  TextButton(
                    onPressed: () => openLegalPage(kPrivacyPolicyUrl),
                    child: const Text('Privacy Policy'),
                  ),
                ],
              ),
              CheckboxListTile(
                key: const ValueKey('terms_agree'),
                value: _agreed,
                onChanged: (value) => setState(() => _agreed = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'I agree to the Terms of Use and Privacy Policy',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const ValueKey('terms_continue'),
                onPressed: _agreed && !_saving ? _accept : null,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
              if (widget.onDecline != null)
                TextButton(
                  onPressed: _saving ? null : widget.onDecline,
                  child: const Text('Not now, sign out'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
