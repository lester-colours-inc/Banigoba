// One step of the step-by-step makeover: the item being changed now, the
// result as soon as it exists, and what to do with it.
//
// Keep moves on to the next item. Try again and Tweak redo this item; Skip
// moves on, keeping any result already made; Undo steps back to the previous
// item. Once a result exists, a slider compares it with the photo before
// this step.
import 'package:flutter/material.dart';

import '../../../../data/models/look_request.dart';
import '../../../../data/models/look_session.dart';
import 'makeover_controls.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/before_after_view.dart';

class LookStepView extends StatelessWidget {
  const LookStepView({
    super.key,
    required this.session,
    required this.isGenerating,
    required this.elapsedSeconds,
    required this.onKeep,
    required this.onTryAgain,
    required this.onTweak,
    required this.onSkip,
    required this.onUndo,
    required this.onGenerate,
    this.onJumpTo,
    this.errorMessage = '',
  });

  final LookSession session;
  final bool isGenerating;
  final int elapsedSeconds;
  final VoidCallback onKeep;
  final VoidCallback onTryAgain;
  final VoidCallback onTweak;
  final VoidCallback onSkip;
  final VoidCallback onUndo;

  /// Styles the current item when nothing is pending (after an undo to a
  /// skipped item, or a failure).
  final VoidCallback onGenerate;

  /// Moves straight to the step tapped in the progress strip.
  final ValueChanged<int>? onJumpTo;
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    final part = session.currentPart;
    if (part == null) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (session.parts.length > 1)
            LookProgressStrip(session: session, onStepTap: onJumpTo),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: _buildImage(context, part),
            ),
          ),
          if (errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: MakeoverErrorBanner(message: errorMessage),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: _buildActionRow(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: _buildPrimary(part),
          ),
        ],
      ),
    );
  }

  /// Fills the space between the steps and the actions, showing the whole
  /// photo on navy so nothing is cropped.
  Widget _buildImage(BuildContext context, LookPart part) {
    if (session.hasPending && !isGenerating) {
      return LayoutBuilder(
        builder: (context, constraints) => BeforeAfterView(
          key: const ValueKey('look_step_compare'),
          beforeImageUrl: session.baseUrl,
          afterImageUrl: session.currentUrl,
          aspectRatio: constraints.maxWidth / constraints.maxHeight,
          borderRadius: 16,
          fit: BoxFit.contain,
          background: kMakeoverNavy,
        ),
      );
    }

    return ClipRRect(
      key: const ValueKey('look_step_image'),
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: kMakeoverNavy),
          AppNetworkImage(
            session.currentUrl,
            key: ValueKey(session.currentUrl),
            fit: BoxFit.contain,
            fallback: const Center(child: Icon(Icons.broken_image_outlined)),
          ),
          if (isGenerating)
            _GeneratingOverlay(
              label: part.progressLabel,
              elapsedSeconds: elapsedSeconds,
            ),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    final busy = isGenerating;

    return Row(
      children: [
        Expanded(
          child: MakeoverIconAction(
            key: const ValueKey('look_step_undo'),
            icon: Icons.undo,
            label: 'Back',
            onTap: session.canUndo ? onUndo : null,
          ),
        ),
        Expanded(
          child: MakeoverIconAction(
            key: const ValueKey('look_step_try_again'),
            icon: Icons.refresh,
            label: 'Try again',
            onTap: !busy && session.hasPending ? onTryAgain : null,
          ),
        ),
        Expanded(
          child: MakeoverIconAction(
            key: const ValueKey('look_step_tweak'),
            icon: Icons.tune,
            label: 'Tweak',
            onTap: busy ? null : onTweak,
          ),
        ),
        Expanded(
          child: MakeoverIconAction(
            key: const ValueKey('look_step_skip'),
            icon: Icons.skip_next_rounded,
            label: 'Skip',
            onTap: onSkip,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimary(LookPart part) {
    if (!session.hasPending && !isGenerating) {
      return MakeoverPrimaryButton(
        key: const ValueKey('look_step_generate'),
        label: 'Style my ${part.label.toLowerCase()}',
        onPressed: onGenerate,
      );
    }

    final next = session.nextPart;
    return MakeoverPrimaryButton(
      key: const ValueKey('look_step_keep'),
      label: next == null ? 'Keep & finish' : 'Keep & next: ${next.label}',
      onPressed: isGenerating ? null : onKeep,
    );
  }
}

/// Where the user is in the run: kept, skipped, current and upcoming items.
/// The steps share the width so they always fit; tapping one jumps to it.
class LookProgressStrip extends StatelessWidget {
  const LookProgressStrip({super.key, required this.session, this.onStepTap});

  final LookSession session;
  final ValueChanged<int>? onStepTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          for (var index = 0; index < session.parts.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            Expanded(
              child: _ProgressPill(
                part: session.parts[index],
                state: session.stateOf(index),
                colors: colors,
                onTap: onStepTap == null ? null : () => onStepTap!(index),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({
    required this.part,
    required this.state,
    required this.colors,
    required this.onTap,
  });

  final LookPart part;
  final LookStepState state;
  final ColorScheme colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isCurrent = state == LookStepState.current;
    final foreground = switch (state) {
      LookStepState.current => Colors.white,
      LookStepState.kept => colors.onSurface,
      LookStepState.skipped ||
      LookStepState.upcoming => colors.onSurfaceVariant,
    };
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(
        color: isCurrent ? kMakeoverNavy : colors.outline,
        width: 1.2,
      ),
    );

    return Semantics(
      button: !isCurrent,
      selected: isCurrent,
      label: switch (state) {
        LookStepState.current => '${part.label}, current step',
        LookStepState.kept => '${part.label}, kept. Go back to it',
        LookStepState.skipped => '${part.label}, skipped. Go back to it',
        LookStepState.upcoming => '${part.label}. Skip to it',
      },
      excludeSemantics: true,
      child: Material(
        key: ValueKey('look_progress_${part.name}_${state.name}'),
        color: isCurrent ? kMakeoverNavy : Colors.transparent,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: isCurrent ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state == LookStepState.kept) ...[
                    Icon(Icons.check, size: 14, color: foreground),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    part.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                      color: foreground,
                      decoration: state == LookStepState.skipped
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GeneratingOverlay extends StatelessWidget {
  const _GeneratingOverlay({required this.label, required this.elapsedSeconds});

  final String label;
  final int elapsedSeconds;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              '$label...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            // UNCLEAR: the seconds counter helps measure the plan's speed
            // target. Decide whether users should keep seeing it.
            Text(
              '${elapsedSeconds}s',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
