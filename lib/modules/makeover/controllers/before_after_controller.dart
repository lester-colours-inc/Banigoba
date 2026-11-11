// The draggable reveal handle of a before/after comparison.
import 'package:get/get.dart';

class BeforeAfterController extends GetxController {
  /// Keeps the handle away from the very edges so it stays grabbable.
  static const double minSplit = 0.08;
  static const double maxSplit = 0.92;

  /// How much of the width the "before" side takes, 0 to 1.
  final RxDouble split = 0.5.obs;

  void dragTo(double dx, double width) {
    if (width <= 0) return;
    split.value = (dx / width).clamp(minSplit, maxSplit);
  }
}
