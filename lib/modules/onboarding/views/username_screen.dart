// Choose your @username. Shown once to anyone without one (new sign-ups and
// existing users alike) with a suggestion made from their name, and reused
// from Settings to change it (October 2026 review, U-4).
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/onboarding/controllers/username_controller.dart';
import 'package:banigoba/modules/onboarding/models/username.dart';

class UsernameScreen extends StatelessWidget {
  const UsernameScreen({
    super.key,
    required this.suggest,
    required this.isAvailable,
    required this.onClaim,
    this.current = '',
    this.isFirstRun = true,
  });

  /// A free suggestion based on the user's name, or null.
  final Future<String?> Function() suggest;
  final Future<bool> Function(String username) isAvailable;

  /// Saves the username; throws with a readable message when it is taken.
  final Future<void> Function(String username) onClaim;

  /// The username the user has now, when changing it from Settings.
  final String current;
  final bool isFirstRun;

  @override
  Widget build(BuildContext context) {
    // Scoped to this screen: created and disposed with the widget.
    return GetBuilder<UsernameController>(
      init: UsernameController(
        suggest: suggest,
        isAvailable: isAvailable,
        onClaim: onClaim,
        current: current,
        isFirstRun: isFirstRun,
      ),
      global: false,
      builder: (controller) => _UsernameView(controller: controller),
    );
  }
}

class _UsernameView extends StatelessWidget {
  const _UsernameView({required this.controller});

  final UsernameController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Obx(
      () => Scaffold(
        appBar: controller.isFirstRun
            ? null
            : AppBar(title: const Text('Username')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            children: [
              if (controller.isFirstRun) ...[
                Text(
                  'Choose your username',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                'Your username is how people find and mention you, like '
                '@tariro.m. Your name can be shared with others; your username '
                'is yours alone. Your email stays private.',
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 24),
              TextField(
                key: const ValueKey('username_field'),
                controller: controller.text,
                autofocus: !controller.isFirstRun,
                autocorrect: false,
                enableSuggestions: false,
                maxLength: kUsernameMaxLength,
                textInputAction: TextInputAction.done,
                onChanged: controller.onChanged,
                onSubmitted: (_) =>
                    controller.canSave ? controller.save() : null,
                decoration: InputDecoration(
                  prefixText: '@',
                  labelText: 'Username',
                  helperText: controller.helper,
                  errorText: controller.errorText,
                  suffixIcon: switch (controller.check.value) {
                    UsernameCheck.checking => const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    UsernameCheck.available => Icon(
                      Icons.check_circle,
                      color: colors.primary,
                    ),
                    _ => null,
                  },
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const ValueKey('username_save'),
                onPressed: controller.canSave ? controller.save : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: controller.saving.value
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(controller.isFirstRun ? 'Continue' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
