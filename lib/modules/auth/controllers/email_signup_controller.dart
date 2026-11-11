import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/auth/controllers/auth_form_controller.dart';
import 'package:banigoba/modules/auth/services/auth_service.dart';

class EmailSignUpController extends AuthFormController {
  EmailSignUpController({AuthService? authService})
    : super(authService ?? AuthService());

  late final TextEditingController name = newText();
  late final TextEditingController email = newText();
  late final TextEditingController password = newText();
  late final TextEditingController confirmPassword = newText();

  final RxBool termsAccepted = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxBool obscureConfirmation = true.obs;

  @override
  String get actionVerb => 'signing up';

  void togglePasswordVisibility() => obscurePassword.toggle();
  void toggleConfirmationVisibility() => obscureConfirmation.toggle();
  void setTermsAccepted(bool? value) => termsAccepted.value = value ?? false;

  Future<void> signUp() async {
    final nameText = name.text.trim();
    final emailText = email.text.trim();
    if (nameText.isEmpty || emailText.isEmpty || password.text.isEmpty) {
      say('Complete all account details');
      return;
    }
    if (!AuthFormController.isValidEmail(emailText)) {
      say('Enter a valid email address');
      return;
    }
    if (password.text.length < 6) {
      say('Password must be at least 6 characters');
      return;
    }
    if (!termsAccepted.value) {
      say('Please accept terms & policy');
      return;
    }
    if (password.text != confirmPassword.text) {
      say('Passwords do not match');
      return;
    }
    await runBusy(
      () => authService.registerWithEmail(
        name: nameText,
        email: emailText,
        password: password.text,
      ),
    );
  }

  void backToSignIn() => Get.back<void>();
}
