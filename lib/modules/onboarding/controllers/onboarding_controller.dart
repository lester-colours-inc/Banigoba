// The intro slides: current page and finishing (saves "seen", opens the gate).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:banigoba/app/routes/app_routes.dart';
import 'package:banigoba/modules/auth/controllers/auth_gate_controller.dart';

/// Preference key set once the intro has been seen or skipped.
const String onboardingDoneKey = 'onboarding_done';

class OnboardingController extends GetxController {
  OnboardingController({required this.slideCount});

  final int slideCount;

  final PageController pageController = PageController();
  final RxInt page = 0.obs;

  bool get isLastPage => page.value == slideCount - 1;

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void onPageChanged(int value) => page.value = value;

  Future<void> finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingDoneKey, true);
    if (isClosed) return;
    // The slides are drawn inside the AuthGate on the root route, so going
    // "to root" is a no-op; tell the gate directly instead.
    if (Get.isRegistered<AuthGateController>()) {
      Get.find<AuthGateController>().onboardingDone.value = true;
      return;
    }
    await Get.offAllNamed<void>(AppRoutes.root);
  }

  void next() {
    if (isLastPage) {
      unawaited(finish());
      return;
    }
    pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }
}
