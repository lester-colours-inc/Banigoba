// Registers a new account; the database creates its profile.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/auth/controllers/email_signup_controller.dart';
import 'package:banigoba/modules/auth/widgets/auth_primary_button.dart';
import 'package:banigoba/modules/auth/widgets/auth_scaffold.dart';
import 'package:banigoba/modules/auth/widgets/auth_social_buttons.dart';
import 'package:banigoba/modules/auth/widgets/auth_switch_prompt.dart';
import 'package:banigoba/modules/auth/widgets/auth_text_field.dart';

class EmailSignUpScreen extends GetView<EmailSignUpController> {
  const EmailSignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create your account',
      children: [
        AuthTextField(
          label: 'Name',
          hint: 'ex: jon smith',
          controller: controller.name,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Email',
          hint: 'ex: jon.smith@email.com',
          controller: controller.email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 16),
        Obx(
          () => AuthTextField(
            label: 'Password',
            hint: '*********',
            controller: controller.password,
            obscureText: controller.obscurePassword.value,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            suffixIcon: PasswordVisibilityToggle(
              obscured: controller.obscurePassword.value,
              onPressed: controller.togglePasswordVisibility,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Obx(
          () => AuthTextField(
            label: 'Confirm password',
            hint: '*********',
            controller: controller.confirmPassword,
            obscureText: controller.obscureConfirmation.value,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => controller.signUp(),
            autofillHints: const [AutofillHints.newPassword],
            suffixIcon: PasswordVisibilityToggle(
              obscured: controller.obscureConfirmation.value,
              onPressed: controller.toggleConfirmationVisibility,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const _TermsRow(),
        const SizedBox(height: 20),
        Obx(
          () => AuthPrimaryButton(
            label: 'SIGN UP',
            isLoading: controller.isLoading.value,
            onPressed: controller.signUp,
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            'or sign up with',
            style: TextStyle(fontSize: 14, color: Color(0xFF8B8B8B)),
          ),
        ),
        const SizedBox(height: 18),
        Obx(
          () => AuthSocialButtons(
            enabled: !controller.isLoading.value,
            onPressed: controller.socialSignIn,
          ),
        ),
        const SizedBox(height: 28),
        AuthSwitchPrompt(
          question: 'Have an account? ',
          actionLabel: 'SIGN IN',
          onPressed: controller.backToSignIn,
        ),
      ],
    );
  }
}

class _TermsRow extends GetView<EmailSignUpController> {
  const _TermsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: Obx(
            () => Checkbox(
              value: controller.termsAccepted.value,
              onChanged: controller.isLoading.value
                  ? null
                  : controller.setTermsAccepted,
              activeColor: kAuthNavy,
              side: const BorderSide(color: kAuthNavy),
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Expanded(
          child: Text.rich(
            TextSpan(
              text: 'I understood the ',
              children: [
                TextSpan(
                  text: 'terms & policy.',
                  style: TextStyle(color: kAuthNavy),
                ),
              ],
            ),
            style: TextStyle(fontSize: 12, color: Color(0xFF555555)),
          ),
        ),
      ],
    );
  }
}
