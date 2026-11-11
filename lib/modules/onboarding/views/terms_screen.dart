// Agreeing to the Terms of Use before using the community (App Store
// guideline 1.2): no tolerance for objectionable content or abusive people,
// and how to report and block. Shown once per Terms version, after sign-in.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/legal_links.dart';
import 'package:banigoba/modules/onboarding/controllers/terms_controller.dart';
import 'package:banigoba/modules/onboarding/widgets/terms_rule.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key, required this.onAccept, this.onDecline});

  final Future<void> Function() onAccept;

  /// Declining signs out.
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    // Scoped to this screen: created and disposed with the widget.
    return GetBuilder<TermsController>(
      init: TermsController(onAccept: onAccept),
      global: false,
      builder: (controller) =>
          _TermsView(controller: controller, onDecline: onDecline),
    );
  }
}

class _TermsView extends StatelessWidget {
  const _TermsView({required this.controller, this.onDecline});

  final TermsController controller;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(
      () => Scaffold(
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
                      TermsRule(
                        icon: Icons.block,
                        text:
                            'There is no tolerance for objectionable content or '
                            'abusive people: no harassment, hate, nudity, '
                            'violence, spam or impersonation.',
                      ),
                      TermsRule(
                        icon: Icons.flag_outlined,
                        text:
                            'Report a look, comment or profile from its ⋯ menu. '
                            'We review reports within 24 hours and remove '
                            'content and accounts that break the rules.',
                      ),
                      TermsRule(
                        icon: Icons.person_off_outlined,
                        text:
                            'Block anyone from their profile or their looks. '
                            'You will no longer see each other.',
                      ),
                      TermsRule(
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
                  value: controller.agreed.value,
                  onChanged: controller.setAgreed,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'I agree to the Terms of Use and Privacy Policy',
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  key: const ValueKey('terms_continue'),
                  onPressed: controller.canContinue ? controller.accept : null,
                  child: controller.saving.value
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
                if (onDecline != null)
                  TextButton(
                    onPressed: controller.saving.value ? null : onDecline,
                    child: const Text('Not now, sign out'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
