// Asks for an event name and its days. Null when cancelled.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/wardrobe/models/upcoming_plan.dart';

Future<EventDraft?> askEventSeries() =>
    Get.dialog<EventDraft>(const _EventSeriesDialog());

class _EventDraftController extends GetxController {
  final TextEditingController name = TextEditingController();
  final Rxn<DateTimeRange> range = Rxn<DateTimeRange>();

  Future<void> pickRange(BuildContext context) async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(DateTime.now().year + 5, 12, 31),
      initialDateRange: range.value,
      helpText: 'Select event days',
    );
    if (selected != null) range.value = selected;
  }

  void submit() {
    final trimmed = name.text.trim();
    final days = range.value;
    if (trimmed.isEmpty || days == null) return;
    Get.back<EventDraft>(
      result: EventDraft(name: trimmed, range: days),
    );
  }

  @override
  void onClose() {
    name.dispose();
    super.onClose();
  }
}

class _EventSeriesDialog extends StatelessWidget {
  const _EventSeriesDialog();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<_EventDraftController>(
      init: _EventDraftController(),
      global: false,
      builder: (draft) => AlertDialog(
        title: const Text('Create Event Series'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: draft.name,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Event name',
                hintText: 'Wedding weekend',
              ),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final range = draft.range.value;
              return OutlinedButton.icon(
                onPressed: () => draft.pickRange(context),
                icon: const Icon(Icons.date_range),
                label: Text(
                  range == null
                      ? 'Choose event days'
                      : '${shortDate(range.start)} - ${shortDate(range.end)}',
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          FilledButton(onPressed: draft.submit, child: const Text('Create')),
        ],
      ),
    );
  }
}
