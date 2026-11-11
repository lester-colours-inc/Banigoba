import 'package:get/get.dart';

import 'package:banigoba/modules/admin/controllers/curators_workspace_controller.dart';

class CuratorsWorkspaceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CuratorsWorkspaceController>(CuratorsWorkspaceController.new);
  }
}
