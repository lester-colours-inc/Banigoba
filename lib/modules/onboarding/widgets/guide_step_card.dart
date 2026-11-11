// One step of the first-run guide: number or tick, title, and a Start button.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/onboarding/models/first_run_guide.dart';

class GuideStepCard extends StatelessWidget {
  const GuideStepCard({
    super.key,
    required this.step,
    required this.number,
    required this.progress,
    required this.busy,
    required this.onStart,
  });

  static const Color _navy = Color(0xFF17008A);

  final GuideStep step;
  final int number;
  final GuideProgress progress;

  /// The step currently running, if any; disables the other Start buttons.
  final GuideStep? busy;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final done = progress.isDone(step);
    final isNext = progress.next == step;
    final label = progress.progressLabel(step);
    final working = busy == step;
    final repeatable = step == GuideStep.wardrobe && !done;

    return Card(
      key: ValueKey('guide_${step.name}'),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isNext ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isNext ? _navy : colors.outlineVariant,
          width: isNext ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: done ? Colors.green.shade600 : _navy,
              foregroundColor: Colors.white,
              child: done ? const Icon(Icons.check) : Text('$number'),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label == null ? step.subtitle : '${step.subtitle} ($label)',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (working)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (!done)
              FilledButton.tonal(
                key: ValueKey('guide_${step.name}_go'),
                onPressed: busy == null ? onStart : null,
                child: Text(
                  repeatable && progress.wardrobeCount > 0
                      ? 'Add another'
                      : 'Start',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
