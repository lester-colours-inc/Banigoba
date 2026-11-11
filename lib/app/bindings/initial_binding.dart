// App-wide dependencies that live for the whole session.
import 'package:get/get.dart';

import 'package:banigoba/app/controllers/theme_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // ThemeController is registered in main() after its preference loads.
    assert(Get.isRegistered<ThemeController>());
  }
}
