// Adding one suggested shop piece to the bag.
import 'package:get/get.dart';

enum BagState { idle, adding, added }

class PickTileController<T> extends GetxController {
  PickTileController({required this.pick, required this.onAddToCart});

  final T pick;

  /// Returns a problem message, or null when added.
  final Future<String?> Function(T pick) onAddToCart;

  final Rx<BagState> state = BagState.idle.obs;
  final RxnString message = RxnString();

  Future<void> add() async {
    state.value = BagState.adding;
    message.value = null;
    final problem = await onAddToCart(pick);
    if (isClosed) return;
    state.value = problem == null ? BagState.added : BagState.idle;
    message.value = problem;
  }
}
