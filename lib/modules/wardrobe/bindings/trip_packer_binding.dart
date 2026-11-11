import 'package:get/get.dart';

import 'package:banigoba/modules/wardrobe/controllers/trip_packer_controller.dart';

class TripPackerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TripPackerController>(TripPackerController.new);
  }
}
