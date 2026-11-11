import 'package:get/get.dart';

import 'package:banigoba/modules/auth/controllers/email_signin_controller.dart';

class EmailSignInBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EmailSignInController>(EmailSignInController.new);
  }
}
