// One step of the step-by-step makeover: the item being changed now, the
// result as soon as it exists, and what to do with it.
//
// Keep moves on to the next item straight away. Try again and Tweak redo this
// item; Skip leaves it as it is; Undo steps back to the previous item.
import 'package:flutter/material.dart';

import '../../../../data/models/look_request.dart';
import '../../../../data/models/look_session.dart';
import 'makeover_controls.dart';
import '../../../widgets/app_network_image.dart';

class LookStepView extends StatefulWidget {
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
  final String errorMessage;

  @override
  State<LookStepView> createState() => _LookStepViewState();
}

class _LookStepViewState extends State<LookStepView> {
  /// True while the user holds the image to see it before this step.
  bool _isComparing = false;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final part = session.currentPart;
    if (part == null) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (session.parts.length > 1) LookProgressStrip(session: session),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Center(child: _buildImage(context, part)),
            ),
          ),
          if (widget.errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: MakeoverErrorBanner(message: widget.errorMessage),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: _buildActionRow(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: _buildPrimary(part),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context, LookPart part) {
    final session = widget.session;
    final showBefore = _isComparing && session.hasPending;
    final imageUrl = showBefore ? session.baseUrl : session.currentUrl;

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: GestureDetector(
        key: const ValueKey('look_step_image'),
        onLongPressStart: (_) => setState(() => _isComparing = true),
        onLongPressEnd: (_) => setState(() => _isComparing = false),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: Theme.of(context).colorScheme.surfaceContainer),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: AppNetworkImage(
                  imageUrl,
                  key: ValueKey(imageUrl),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  fallback: const Center(
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
              if (widget.isGenerating)
                _GeneratingOverlay(
                  label: part.progressLabel,
                  elapsedSeconds: widget.elapsedSeconds,
                )
              else if (session.hasPending)
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: _ImageTag(
                    label: showBefore ? 'Before' : 'Hold to compare',
                    icon: showBefore ? Icons.history : Icons.touch_app,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    final session = widget.session;
    final busy = widget.isGenerating;

    return Row(
      children: [
        Expanded(
          child: MakeoverIconAction(
            key: const ValueKey('look_step_undo'),
            icon: Icons.undo,
            label: 'Back',
            onTap: session.canUndo ? widget.onUndo : null,
          ),
        ),
        Expanded(
          child: MakeoverIconAction(
            key: const ValueKey('look_step_try_again'),
            icon: Icons.refresh,
            label: 'Try again',
            onTap: !busy && session.hasPending ? widget.onTryAgain : null,
          ),
        ),
        Expanded(
          child: MakeoverIconAction(
            key: const ValueKey('look_step_tweak'),
            icon: Icons.tune,
            label: 'Tweak',
            onTap: busy ? null : widget.onTweak,
          ),
        ),
        Expanded(
          child: MakeoverIconAction(
            key: const ValueKey('look_step_skip'),
            icon: Icons.skip_next_outlined,
            label: 'Skip',
            onTap: widget.onSkip,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimary(LookPart part) {
    final session = widget.session;

    if (!session.hasPending && !widget.isGenerating) {
      return MakeoverPrimaryButton(
        key: const ValueKey('look_step_generate'),
        icon: Icons.auto_awesome,
        label: 'Style my ${part.label.toLowerCase()}',
        onPressed: widget.onGenerate,
      );
    }

    final next = session.nextPart;
    return MakeoverPrimaryButton(
      key: const ValueKey('look_step_keep'),
      icon: next == null ? Icons.check : Icons.arrow_forward,
      label: next == null ? 'Keep & finish' : 'Keep & next: ${next.label}',
      onPressed: widget.isGenerating ? null : widget.onKeep,
    );
  }
}

/// Where the user is in the run: kept, skipped, current and upcoming items.
class LookProgressStrip extends StatelessWidget {
  const LookProgressStrip({super.key, required this.session});

  final LookSession session;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        itemCount: session.parts.length,
        separatorBuilder: (_, _) =>
            Icon(Icons.chevron_right, size: 16, color: colors.outline),
        itemBuilder: (context, index) {
          final part = session.parts[index];
          final state = session.stateOf(index);
          final isCurrent = state == LookStepState.current;

          return Center(
            child: Container(
              key: ValueKey('look_progress_${part.name}_${state.name}'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: ShapeDecoration(
                color: isCurrent ? kMakeoverNavy : Colors.transparent,
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isCurrent ? kMakeoverNavy : colors.outlineVariant,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state == LookStepState.kept) ...[
                    Icon(Icons.check, size: 14, color: colors.onSurface),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    part.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: switch (state) {
                        LookStepState.current => Colors.white,
                        LookStepState.kept => colors.onSurface,
                        LookStepState.skipped ||
                        LookStepState.upcoming => colors.onSurfaceVariant,
                      },
                      decoration: state == LookStepState.skipped
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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

class _ImageTag extends StatelessWidget {
  const _ImageTag({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: ShapeDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
