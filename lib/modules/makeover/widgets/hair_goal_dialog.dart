// Asks for a new hair goal when changing only the hair. Null when cancelled.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<String?> askHairGoal(String current) =>
    Get.dialog<String>(_HairGoalDialog(current: current));

class _HairGoalController extends GetxController {
  _HairGoalController(String current)
    : text = TextEditingController(text: current);

  final TextEditingController text;

  @override
  void onClose() {
    text.dispose();
    super.onClose();
  }
}

class _HairGoalDialog extends StatelessWidget {
  const _HairGoalDialog({required this.current});

  final String current;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<_HairGoalController>(
      init: _HairGoalController(current),
      global: false,
      builder: (goal) => AlertDialog(
        title: const Text('Change hair'),
        content: TextField(
          controller: goal.text,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Hair goal',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Get.back<String>(result: goal.text.text),
            child: const Text('Regenerate hair'),
          ),
        ],
      ),
    );
  }
}
