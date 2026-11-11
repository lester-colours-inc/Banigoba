import 'package:get/get.dart';
import 'package:flutter/widgets.dart';

import 'package:banigoba/app/routes/app_routes.dart';
import 'package:banigoba/modules/auth/controllers/auth_form_controller.dart';
import 'package:banigoba/modules/auth/services/auth_service.dart';

class EmailSignInController extends AuthFormController {
  EmailSignInController({AuthService? authService})
    : super(authService ?? AuthService());

  late final TextEditingController email = newText();
  late final TextEditingController password = newText();
  final RxBool obscurePassword = true.obs;

  @override
  String get actionVerb => 'signing in';

  void togglePasswordVisibility() => obscurePassword.toggle();

  Future<void> signIn() async {
    final emailText = email.text.trim();
    if (emailText.isEmpty || password.text.isEmpty) {
      say('Enter your email and password');
      return;
    }
    if (!AuthFormController.isValidEmail(emailText)) {
      say('Enter a valid email address');
      return;
    }
    await runBusy(
      () => authService.signInWithEmail(
        email: emailText,
        password: password.text,
      ),
    );
  }

  void openSignUp() => Get.toNamed<void>(AppRoutes.signUp);
}
