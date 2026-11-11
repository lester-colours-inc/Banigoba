// The guided first five minutes (review item O-1). A new person sees four
// short steps: their photo, their style, a few pieces from their wardrobe and
// a first makeover. Every step can be skipped, and so can the whole guide, so
// nobody is held up. What each step does is injected, so this screen can be
// tested without a backend.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/onboarding/models/first_run_guide.dart';
import 'package:banigoba/modules/onboarding/services/guide_actions_contract.dart';

export 'package:banigoba/modules/onboarding/services/guide_actions_contract.dart';
import 'package:banigoba/modules/onboarding/controllers/first_run_guide_controller.dart';
import 'package:banigoba/modules/onboarding/widgets/guide_step_card.dart';

class FirstRunGuideScreen extends StatelessWidget {
  const FirstRunGuideScreen({
    super.key,
    required this.userId,
    required this.name,
    required this.actions,
  });

  final String userId;

  /// The person's first name, for the welcome.
  final String name;
  final GuideActions actions;

  @override
  Widget build(BuildContext context) {
    // Scoped to this screen: created and disposed with the widget.
    return GetBuilder<FirstRunGuideController>(
      init: FirstRunGuideController(actions: actions),
      global: false,
      builder: (controller) =>
          _GuideView(controller: controller, userId: userId, name: name),
    );
  }
}

class _GuideView extends StatelessWidget {
  const _GuideView({
    required this.controller,
    required this.userId,
    required this.name,
  });

  static const Color _navy = Color(0xFF17008A);

  final FirstRunGuideController controller;
  final String userId;
  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final first = name.trim().split(' ').first;
    final welcome = welcomeAffirmation(userId);

    return Obx(() {
      final progress = controller.progress.value;
      final complete = progress.isComplete;
      final leaving = controller.leaving.value;
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            children: [
              Text(
                first.isEmpty ? 'Welcome to Banigoba' : 'Welcome, $first',
                key: const ValueKey('guide_title'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                complete
                    ? 'You are all set.'
                    : 'Four quick steps and you will see your first look. '
                          'Skip any of them.',
                style: TextStyle(fontSize: 16, color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  key: const ValueKey('guide_progress'),
                  value: progress.doneCount / GuideStep.values.length,
                  minHeight: 8,
                  color: _navy,
                  backgroundColor: colors.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 20),
              for (var i = 0; i < GuideStep.values.length; i++)
                GuideStepCard(
                  step: GuideStep.values[i],
                  number: i + 1,
                  progress: progress,
                  busy: controller.busy.value,
                  onStart: () => controller.run(GuideStep.values[i], context),
                ),
              if (complete) ...[
                const SizedBox(height: 8),
                Container(
                  key: const ValueKey('guide_welcome'),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${welcome.emoji} ${welcome.text}. That is how we see you.',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (complete)
                FilledButton(
                  key: const ValueKey('guide_finish'),
                  onPressed: leaving ? null : controller.leave,
                  style: FilledButton.styleFrom(
                    backgroundColor: _navy,
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  child: const Text('Start using Banigoba'),
                )
              else
                TextButton(
                  key: const ValueKey('guide_skip'),
                  onPressed: leaving ? null : controller.leave,
                  child: Text(
                    progress.doneCount == 0 ? 'Skip for now' : 'Finish later',
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}
