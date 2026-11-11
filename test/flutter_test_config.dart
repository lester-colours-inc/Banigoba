// Runs before every test file (see package:flutter_test docs).
import 'dart:async';

import 'package:banigoba/shared/widgets/app_network_image.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Widget tests have no network or image cache; show fallbacks instead.
  AppNetworkImage.loadFromNetwork = false;
  AppToast.autoCloseEnabled = false;
  // A toast left on screen would leave its auto-close timer pending.
  tearDown(() {
    toastification.dismissAll(delayForAnimation: false);
    // The package keeps a global manager per alignment; reset it so one
    // test's toasts and overlay never leak into the next.
    toastification.managers.clear();
    AppToast.reset();
  });
  await testMain();
}
