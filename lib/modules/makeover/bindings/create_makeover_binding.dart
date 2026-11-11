import 'package:get/get.dart';

import 'package:banigoba/modules/makeover/controllers/create_makeover_controller.dart';

class CreateMakeoverBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateMakeoverController>(CreateMakeoverController.new);
  }
}
