// UI-06: progress, per domain. One domain failing stays legible.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/makeover/controllers/create_makeover_controller.dart';
import 'package:banigoba/modules/makeover/models/makeover_job.dart';
import 'package:banigoba/modules/makeover/widgets/create_makeover_parts.dart';

class CreateMakeoverProgress extends StatelessWidget {
  const CreateMakeoverProgress({super.key, required this.controller});

  final CreateMakeoverController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final job = controller.job.value;
      if (job == null) return const SizedBox.shrink();
      final busy = controller.isBusy.value;
      final error = controller.error.value;

      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Working on your look',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You can leave this screen. The work carries on and your saved '
            'looks will be waiting.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          for (final domain in MakeoverDomain.values)
            if (job.stageFor(domain).isRequested)
              _StageTile(stage: job.stageFor(domain)),
          if (job.isPartial) ...[
            const SizedBox(height: 16),
            const MakeoverErrorBanner(
              'Part of this look could not be created. What succeeded is kept '
              'below — nothing has been substituted.',
            ),
          ],
          if (error.isNotEmpty) ...[
            const SizedBox(height: 16),
            MakeoverErrorBanner(error),
          ],
          const SizedBox(height: 24),
          if (job.hasFailure && !busy) ...[
            for (final domain in MakeoverDomain.values)
              if (job.stageFor(domain).status == MakeoverStageStatus.failed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilledButton.tonalIcon(
                    onPressed: () => controller.refine(domain),
                    icon: const Icon(Icons.refresh),
                    label: Text('Retry ${domain.label.toLowerCase()}'),
                  ),
                ),
            OutlinedButton(
              onPressed: () => controller.goTo(CreateStep.brief),
              child: const Text('Change the brief instead'),
            ),
          ],
          if (job.alternatives.isNotEmpty && !busy)
            FilledButton(
              onPressed: () => controller.goTo(CreateStep.compare),
              child: const Text('See what worked'),
            ),
        ],
      );
    });
  }
}

/// Per-domain progress row.
class _StageTile extends StatelessWidget {
  const _StageTile({required this.stage});

  final MakeoverStage stage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final (icon, label) = switch (stage.status) {
      MakeoverStageStatus.queued => (Icons.schedule, 'Waiting'),
      MakeoverStageStatus.running => (Icons.autorenew, 'Working'),
      MakeoverStageStatus.succeeded => (Icons.check_circle_outline, 'Done'),
      MakeoverStageStatus.failed => (Icons.error_outline, 'Could not finish'),
      MakeoverStageStatus.skipped => (Icons.remove, 'Not requested'),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (stage.status == MakeoverStageStatus.running)
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              icon,
              size: 18,
              color: stage.status == MakeoverStageStatus.failed
                  ? colors.error
                  : colors.onSurfaceVariant,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.domain.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  stage.errorMessage.isNotEmpty ? stage.errorMessage : label,
                  style: TextStyle(
                    fontSize: 12,
                    color: stage.status == MakeoverStageStatus.failed
                        ? colors.error
                        : colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
