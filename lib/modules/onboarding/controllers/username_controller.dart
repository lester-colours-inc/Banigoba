// Checking and claiming an @username: debounced availability, validation.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/onboarding/models/username.dart';

enum UsernameCheck { idle, checking, available, taken }

class UsernameController extends GetxController {
  UsernameController({
    required this.suggest,
    required this.isAvailable,
    required this.onClaim,
    this.current = '',
    this.isFirstRun = true,
  });

  /// A free suggestion based on the user's name, or null.
  final Future<String?> Function() suggest;
  final Future<bool> Function(String username) isAvailable;

  /// Saves the username; throws with a readable message when it is taken.
  final Future<void> Function(String username) onClaim;

  /// The username the user has now, when changing it from Settings.
  final String current;
  final bool isFirstRun;

  static const Duration _debounce = Duration(milliseconds: 400);

  late final TextEditingController text = TextEditingController(text: current);
  final Rx<UsernameCheck> check = UsernameCheck.idle.obs;
  final RxBool saving = false.obs;
  final RxString error = ''.obs;
  // Mirrors [text] so the view reacts to typing.
  final RxString typed = ''.obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    typed.value = current;
    if (current.isEmpty) unawaited(_loadSuggestion());
  }

  @override
  void onClose() {
    _timer?.cancel();
    text.dispose();
    super.onClose();
  }

  Future<void> _loadSuggestion() async {
    final suggestion = await suggest();
    if (isClosed || suggestion == null || text.text.isNotEmpty) return;
    text.text = suggestion;
    typed.value = suggestion;
    check.value = UsernameCheck.available;
  }

  String get name => normalizeUsername(typed.value);

  String? get problem =>
      typed.value.isEmpty ? null : usernameProblem(typed.value);

  void onChanged(String value) {
    typed.value = value;
    _timer?.cancel();
    error.value = '';
    check.value = UsernameCheck.idle;
    if (problem != null || name.isEmpty || name == current) return;
    check.value = UsernameCheck.checking;
    _timer = Timer(_debounce, () async {
      final candidate = name;
      final free = await isAvailable(candidate);
      if (isClosed || candidate != name) return;
      check.value = free ? UsernameCheck.available : UsernameCheck.taken;
    });
  }

  bool get canSave =>
      !saving.value &&
      problem == null &&
      name.isNotEmpty &&
      (name == current || check.value == UsernameCheck.available);

  Future<void> save() async {
    saving.value = true;
    error.value = '';
    try {
      await onClaim(name);
      if (!isClosed && !isFirstRun) Get.back<String>(result: name);
    } on Exception catch (e) {
      if (!isClosed) error.value = e.toString();
    } finally {
      if (!isClosed) saving.value = false;
    }
  }

  String? get helper => switch (check.value) {
    _ when problem != null => null,
    UsernameCheck.checking => 'Checking…',
    UsernameCheck.available => '@$name is yours if you want it',
    UsernameCheck.taken => null,
    UsernameCheck.idle => 'Letters, numbers, dots and underscores',
  };

  String? get errorText =>
      problem ??
      (check.value == UsernameCheck.taken
          ? 'That username is taken. Try another.'
          : null) ??
      (error.value.isEmpty ? null : error.value);
}
