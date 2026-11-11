import 'package:get/get.dart';

import 'package:banigoba/modules/auth/controllers/email_signup_controller.dart';

class EmailSignUpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EmailSignUpController>(EmailSignUpController.new);
  }
}
