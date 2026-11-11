// Which angle of a turn-around look is showing, and dragging between them.
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// How far to drag, in logical pixels, to turn one angle.
const double kTurnStepPixels = 48;

/// The index reached after [steps] turns from [current] in a ring of
/// [length] angles. Positive steps go forward (front, right, back, left).
int turnedIndex(int current, int length, int steps) {
  if (length <= 0) return 0;
  return ((current + steps) % length + length) % length;
}

class TurnAroundController extends GetxController {
  final RxInt index = 0.obs;
  double _dragged = 0;

  void startDrag() => _dragged = 0;

  /// Turns by [steps] through the [readyCount] angles that exist so far.
  void turn(int steps, int readyCount) {
    if (readyCount < 2) return;
    index.value = turnedIndex(index.value, readyCount, steps);
  }

  void dragUpdate(DragUpdateDetails details, int readyCount) {
    _dragged += details.delta.dx;
    // Dragging left turns the person forward, like spinning a turntable.
    while (_dragged <= -kTurnStepPixels) {
      _dragged += kTurnStepPixels;
      turn(1, readyCount);
    }
    while (_dragged >= kTurnStepPixels) {
      _dragged -= kTurnStepPixels;
      turn(-1, readyCount);
    }
  }
}
