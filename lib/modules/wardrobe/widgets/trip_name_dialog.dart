// Asks what to call a new packing list. Null when cancelled.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<String?> askTripName() {
  return Get.dialog<String>(const _TripNameDialog());
}

class _TripNameDialog extends StatefulWidget {
  const _TripNameDialog();

  @override
  State<_TripNameDialog> createState() => _TripNameDialogState();
}

// Only owns the text field's controller so it is disposed with the dialog.
class _TripNameDialogState extends State<_TripNameDialog> {
  final TextEditingController _name = TextEditingController(text: 'My Trip');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Name your packing list'),
      content: TextField(
        controller: _name,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Trip name'),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Get.back<String>(result: _name.text.trim()),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
