// A packing list as a tick-off dialog; every tick is saved straight away.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/wardrobe/models/upcoming_plan.dart';

Future<void> showPackingList({
  required UpcomingPlan plan,
  required Future<void> Function(List<Map<String, dynamic>> items) onChanged,
}) {
  return Get.dialog<void>(_PackingListDialog(plan: plan, onChanged: onChanged));
}

class _PackingItemsController extends GetxController {
  _PackingItemsController(this.plan, this.onChanged);

  final UpcomingPlan plan;
  final Future<void> Function(List<Map<String, dynamic>> items) onChanged;

  late final RxList<Map<String, dynamic>> items = plan.packingItems
      .map((item) => Map<String, dynamic>.from(item))
      .toList()
      .obs;

  Future<void> setPacked(int index, bool packed) async {
    items[index] = {...items[index], 'packed': packed};
    await onChanged(items.toList());
  }
}

class _PackingListDialog extends StatelessWidget {
  const _PackingListDialog({required this.plan, required this.onChanged});

  final UpcomingPlan plan;
  final Future<void> Function(List<Map<String, dynamic>> items) onChanged;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<_PackingItemsController>(
      init: _PackingItemsController(plan, onChanged),
      global: false,
      builder: (list) => AlertDialog(
        title: Text(plan.name),
        content: SizedBox(
          width: double.maxFinite,
          child: Obx(
            () => ListView(
              shrinkWrap: true,
              children: [
                for (var index = 0; index < list.items.length; index++)
                  CheckboxListTile(
                    value: list.items[index]['packed'] == true,
                    title: Text((list.items[index]['name'] ?? '').toString()),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) => list.setPacked(index, value == true),
                  ),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: Get.back, child: const Text('Close'))],
      ),
    );
  }
}
