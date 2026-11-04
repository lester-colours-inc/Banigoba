// The guided first five minutes (review item O-1). A new person sees four
// short steps: their photo, their style, a few pieces from their wardrobe and
// a first makeover. Every step can be skipped, and so can the whole guide, so
// nobody is held up. What each step does is injected, so this screen can be
// tested without a backend.
import 'package:flutter/material.dart';

import '../../../data/models/first_run_guide.dart';

/// What the guide's steps do. Each returns true when the person completed it.
abstract interface class GuideActions {
  Future<bool> addPhoto(BuildContext context);
  Future<bool> pickStyle(BuildContext context);
  Future<bool> addPiece(BuildContext context);
  Future<bool> tryMakeover(BuildContext context);

  /// Marks the guide as seen, so it is not shown again.
  Future<void> finish();
}

class FirstRunGuideScreen extends StatefulWidget {
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
  State<FirstRunGuideScreen> createState() => _FirstRunGuideScreenState();
}

class _FirstRunGuideScreenState extends State<FirstRunGuideScreen> {
  static const Color _navy = Color(0xFF17008A);

  GuideProgress _progress = const GuideProgress();
  GuideStep? _busy;
  bool _leaving = false;

  Future<void> _run(GuideStep step) async {
    if (_busy != null || _leaving) return;
    setState(() => _busy = step);
    try {
      final done = switch (step) {
        GuideStep.photo => await widget.actions.addPhoto(context),
        GuideStep.style => await widget.actions.pickStyle(context),
        GuideStep.wardrobe => await widget.actions.addPiece(context),
        GuideStep.makeover => await widget.actions.tryMakeover(context),
      };
      if (!mounted || !done) return;
      setState(() {
        _progress = switch (step) {
          GuideStep.photo => _progress.copyWith(photoDone: true),
          GuideStep.style => _progress.copyWith(styleDone: true),
          GuideStep.wardrobe => _progress.copyWith(
            wardrobeCount: _progress.wardrobeCount + 1,
          ),
          GuideStep.makeover => _progress.copyWith(makeoverTried: true),
        };
      });
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('That did not work: $error. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _leave() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    try {
      await widget.actions.finish();
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _leaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not continue: $error')));
    }
  }

  Widget _card(GuideStep step, int number) {
    final colors = Theme.of(context).colorScheme;
    final done = _progress.isDone(step);
    final isNext = _progress.next == step;
    final label = _progress.progressLabel(step);
    final working = _busy == step;
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
                onPressed: _busy == null ? () => _run(step) : null,
                child: Text(
                  repeatable && _progress.wardrobeCount > 0
                      ? 'Add another'
                      : 'Start',
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final complete = _progress.isComplete;
    final first = widget.name.trim().split(' ').first;
    final welcome = welcomeAffirmation(widget.userId);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          children: [
            Text(
              first.isEmpty ? 'Welcome to Banigoba' : 'Welcome, $first',
              key: const ValueKey('guide_title'),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
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
                value: _progress.doneCount / GuideStep.values.length,
                minHeight: 8,
                color: _navy,
                backgroundColor: colors.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < GuideStep.values.length; i++)
              _card(GuideStep.values[i], i + 1),
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
                onPressed: _leaving ? null : _leave,
                style: FilledButton.styleFrom(
                  backgroundColor: _navy,
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: const Text('Start using Banigoba'),
              )
            else
              TextButton(
                key: const ValueKey('guide_skip'),
                onPressed: _leaving ? null : _leave,
                child: Text(
                  _progress.doneCount == 0 ? 'Skip for now' : 'Finish later',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
