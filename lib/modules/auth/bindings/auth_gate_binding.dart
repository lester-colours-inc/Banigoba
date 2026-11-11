import 'package:get/get.dart';

import 'package:banigoba/modules/auth/controllers/auth_gate_controller.dart';
import 'package:banigoba/modules/auth/controllers/email_signin_controller.dart';

class AuthGateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthGateController>(AuthGateController.new);
    // The gate hosts the sign-in form when nobody is signed in.
    Get.lazyPut<EmailSignInController>(EmailSignInController.new, fenix: true);
  }
}
