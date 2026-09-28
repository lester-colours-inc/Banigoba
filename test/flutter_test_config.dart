// Runs before every test file (see package:flutter_test docs).
import 'dart:async';

import 'package:banigoba/ui/widgets/app_network_image.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Widget tests have no network or image cache; show fallbacks instead.
  AppNetworkImage.loadFromNetwork = false;
  await testMain();
}
