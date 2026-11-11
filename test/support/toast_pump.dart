// Test helper: toasts are inserted into an overlay over a few frames, so a
// single `pump()` is not enough for them to be findable.
import 'package:flutter_test/flutter_test.dart';

extension ToastPump on WidgetTester {
  /// Advances time until a just-shown toast is on screen.
  Future<void> pumpToast() async {
    for (var i = 0; i < 5; i++) {
      await pump(const Duration(milliseconds: 100));
    }
  }
}
