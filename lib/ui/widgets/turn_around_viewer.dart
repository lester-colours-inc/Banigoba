// Turns a try-on like a turntable: drag the picture left or right to see the
// person from the front, the sides and the back. Arrow buttons do the same
// for anyone who can't drag. Only angles that are ready are in the turn;
// angles still being made show as pending dots.
import 'package:flutter/material.dart';

import '../../data/services/turn_around_service.dart';
import 'app_network_image.dart';

/// How far to drag, in logical pixels, to turn one angle.
const double kTurnStepPixels = 48;

/// The index reached after [steps] turns from [current] in a ring of
/// [length] angles. Positive steps go forward (front, right, back, left).
int turnedIndex(int current, int length, int steps) {
  if (length <= 0) return 0;
  return ((current + steps) % length + length) % length;
}

class TurnAroundViewer extends StatefulWidget {
  const TurnAroundViewer({
    super.key,
    required this.views,
    this.isMakingMore = false,
    this.imageBuilder,
  });

  /// Image URL by angle. The front is always there; the rest arrive one by
  /// one.
  final Map<TurnView, String> views;

  /// True while more angles are still being made.
  final bool isMakingMore;

  /// Replaces the network image, for tests.
  final Widget Function(String url)? imageBuilder;

  @override
  State<TurnAroundViewer> createState() => _TurnAroundViewerState();
}

class _TurnAroundViewerState extends State<TurnAroundViewer> {
  int _index = 0;
  double _dragged = 0;

  List<TurnView> get _ready => [
    for (final view in TurnView.values)
      if (widget.views.containsKey(view)) view,
  ];

  void _turn(int steps) {
    final ready = _ready;
    if (ready.length < 2) return;
    setState(() => _index = turnedIndex(_index, ready.length, steps));
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dragged += details.delta.dx;
    // Dragging left turns the person forward, like spinning a turntable.
    while (_dragged <= -kTurnStepPixels) {
      _dragged += kTurnStepPixels;
      _turn(1);
    }
    while (_dragged >= kTurnStepPixels) {
      _dragged -= kTurnStepPixels;
      _turn(-1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ready = _ready;
    final current = ready[_index.clamp(0, ready.length - 1)];
    final url = widget.views[current]!;
    final canTurn = ready.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          key: const ValueKey('turn_surface'),
          onHorizontalDragStart: (_) => _dragged = 0,
          onHorizontalDragUpdate: _onDragUpdate,
          child: Semantics(
            label: '${current.label} view. Drag left or right to turn.',
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ColoredBox(
                  color: colors.surfaceContainerHigh,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.imageBuilder?.call(url) ??
                          AppNetworkImage(
                            url,
                            key: ValueKey(url),
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          ),
                      if (current != TurnView.front)
                        const Positioned(
                          top: 10,
                          right: 10,
                          child: _Tag(text: 'Estimated view'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              key: const ValueKey('turn_back'),
              tooltip: 'Turn the other way',
              onPressed: canTurn ? () => _turn(-1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            for (final view in TurnView.values)
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: view == current
                      ? colors.primary
                      : widget.views.containsKey(view)
                      ? colors.outline
                      : Colors.transparent,
                  border: Border.all(
                    color: widget.views.containsKey(view)
                        ? colors.primary
                        : colors.outlineVariant,
                  ),
                ),
              ),
            IconButton(
              key: const ValueKey('turn_forward'),
              tooltip: 'Turn',
              onPressed: canTurn ? () => _turn(1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Text(
          widget.isMakingMore
              ? '${current.label}  ·  making more angles…'
              : current.label,
          key: const ValueKey('turn_label'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
