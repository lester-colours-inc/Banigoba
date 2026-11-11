// "Leave this look?" — asked before an unsaved look is thrown away.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// True when the user chose to leave.
Future<bool> confirmDiscardLook() async {
  final result = await Get.dialog<bool>(
    AlertDialog(
      title: const Text('Leave this look?'),
      content: const Text("It hasn't been saved yet."),
      actions: [
        TextButton(
          onPressed: () => Get.back<bool>(result: false),
          child: const Text('Keep it'),
        ),
        TextButton(
          onPressed: () => Get.back<bool>(result: true),
          child: const Text('Leave'),
        ),
      ],
    ),
  );
  return result ?? false;
}
