import 'package:get/get.dart';

import 'package:banigoba/modules/wardrobe/controllers/plan_ahead_controller.dart';

class PlanAheadBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlanAheadController>(PlanAheadController.new);
  }
}
