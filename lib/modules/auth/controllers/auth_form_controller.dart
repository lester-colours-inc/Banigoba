// What sign-in and sign-up share: a busy flag, social sign-in, email checks
// and where to go once signed in.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/auth/services/auth_service.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

abstract class AuthFormController extends GetxController {
  AuthFormController(this.authService);

  final AuthService authService;
  final RxBool isLoading = false.obs;

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool isValidEmail(String email) => _emailPattern.hasMatch(email);

  /// "signing in" / "signing up", used in social-error messages.
  String get actionVerb;

  void say(String message) => AppToast.say(message);

  /// Runs [work] with the busy flag on, reporting failures as a toast.
  Future<void> runBusy(
    Future<void> Function() work, {
    String Function(Object error)? describeError,
  }) async {
    isLoading.value = true;
    try {
      await work();
      _goToLaunchGate();
    } catch (error) {
      say(describeError?.call(error) ?? error.toString());
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  Future<void> socialSignIn(String provider) {
    return runBusy(() async {
      switch (provider) {
        case 'Google':
          await authService.signInWithGoogle();
        case 'Facebook':
          await authService.signInWithFacebook();
        default:
          await authService.signInWithApple();
      }
    }, describeError: (e) => 'Error $actionVerb with $provider: $e');
  }

  /// Back to the launch gate, which now shows the signed-in app.
  void _goToLaunchGate() => Get.until((route) => route.isFirst);

  TextEditingController newText() {
    final controller = TextEditingController();
    _texts.add(controller);
    return controller;
  }

  final List<TextEditingController> _texts = [];

  @override
  void onClose() {
    for (final controller in _texts) {
      controller.dispose();
    }
    super.onClose();
  }
}
