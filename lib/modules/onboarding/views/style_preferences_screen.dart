// Optional style preferences, asked once after the account exists.
//
// Every question can be skipped, and the same screen is reachable later from
// Settings, so nobody has to answer everything up front (September 2026
// review). Persistence is injected so the screen stays testable.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/onboarding/controllers/style_preferences_controller.dart';
import 'package:banigoba/modules/onboarding/models/style_preferences.dart';

class StylePreferencesScreen extends StatelessWidget {
  const StylePreferencesScreen({
    super.key,
    required this.onSave,
    required this.onSkip,
    this.initial = const StylePreferences(),
    this.isFirstRun = true,
  });

  /// Called with the user's answers.
  final Future<void> Function(StylePreferences preferences) onSave;

  /// Called when the user chooses to answer later.
  final Future<void> Function() onSkip;

  final StylePreferences initial;

  /// First run shows "Skip for now"; from Settings it is a normal page.
  final bool isFirstRun;

  static const List<String> styleOptions =
      StylePreferencesController.styleOptions;

  @override
  Widget build(BuildContext context) {
    // Scoped to this screen: created and disposed with the widget.
    return GetBuilder<StylePreferencesController>(
      init: StylePreferencesController(
        onSave: onSave,
        onSkip: onSkip,
        initial: initial,
      ),
      global: false,
      builder: (controller) =>
          _StylePreferencesView(controller: controller, isFirstRun: isFirstRun),
    );
  }
}

class _StylePreferencesView extends StatelessWidget {
  const _StylePreferencesView({
    required this.controller,
    required this.isFirstRun,
  });

  static const Color _navy = Color(0xFF17008A);

  final StylePreferencesController controller;
  final bool isFirstRun;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final saving = controller.isSaving.value;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Your style'),
          automaticallyImplyLeading: !isFirstRun,
          actions: [
            if (isFirstRun)
              TextButton(
                key: const ValueKey('preferences_skip'),
                onPressed: saving ? null : controller.skip,
                child: const Text('Skip for now'),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Help us suggest looks you will love. Answer as much or as '
              'little as you like; you can change this any time in Settings.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text('Styles you like', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final style in StylePreferencesController.styleOptions)
                  FilterChip(
                    label: Text(style),
                    selected: controller.styles.contains(style),
                    onSelected: saving
                        ? null
                        : (_) => controller.toggleStyle(style),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'What should a makeover change?',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final focus in MakeoverFocus.values)
                  ChoiceChip(
                    label: Text(focus.label),
                    selected: controller.focus.value == focus,
                    onSelected: saving
                        ? null
                        : (selected) =>
                              controller.setFocus(focus, selected: selected),
                  ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: FilledButton(
            key: const ValueKey('preferences_save'),
            style: FilledButton.styleFrom(
              backgroundColor: _navy,
              minimumSize: const Size.fromHeight(54),
            ),
            onPressed: saving ? null : controller.save,
            child: Text(saving ? 'Saving...' : 'Continue'),
          ),
        ),
      );
    });
  }
}
