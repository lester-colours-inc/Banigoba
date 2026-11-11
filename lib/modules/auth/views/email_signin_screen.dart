// Email/password sign-in, with a link to account registration.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/auth/controllers/email_signin_controller.dart';
import 'package:banigoba/modules/auth/widgets/auth_primary_button.dart';
import 'package:banigoba/modules/auth/widgets/auth_scaffold.dart';
import 'package:banigoba/modules/auth/widgets/auth_social_buttons.dart';
import 'package:banigoba/modules/auth/widgets/auth_switch_prompt.dart';
import 'package:banigoba/modules/auth/widgets/auth_text_field.dart';

class EmailSignInScreen extends GetView<EmailSignInController> {
  const EmailSignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Sign in your account',
      logoGap: 84,
      titleGap: 34,
      children: [
        AuthTextField(
          label: 'Email',
          hint: 'ex: jon.smith@email.com',
          controller: controller.email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          verticalPadding: 15,
        ),
        const SizedBox(height: 20),
        Obx(
          () => AuthTextField(
            label: 'Password',
            hint: '*********',
            controller: controller.password,
            obscureText: controller.obscurePassword.value,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => controller.signIn(),
            verticalPadding: 15,
            suffixIcon: PasswordVisibilityToggle(
              obscured: controller.obscurePassword.value,
              onPressed: controller.togglePasswordVisibility,
            ),
          ),
        ),
        const SizedBox(height: 38),
        Obx(
          () => AuthPrimaryButton(
            label: 'SIGN IN',
            isLoading: controller.isLoading.value,
            onPressed: controller.signIn,
          ),
        ),
        const SizedBox(height: 28),
        const Center(
          child: Text(
            'or sign in with',
            style: TextStyle(fontSize: 14, color: Color(0xFF8B8B8B)),
          ),
        ),
        const SizedBox(height: 20),
        Obx(
          () => AuthSocialButtons(
            enabled: !controller.isLoading.value,
            onPressed: controller.socialSignIn,
          ),
        ),
        const SizedBox(height: 44),
        AuthSwitchPrompt(
          question: 'Don’t have an account? ',
          actionLabel: 'SIGN UP',
          onPressed: controller.openSignUp,
        ),
      ],
    );
  }
}
