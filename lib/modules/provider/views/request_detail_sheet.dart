// The details of a design or hair request, with the answers a provider can
// give: accept or decline a new one, mark an accepted one completed.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/provider/controllers/request_detail_controller.dart';
import 'package:banigoba/modules/provider/models/provider_inbox.dart';

typedef RespondToRequest = Future<void> Function(String status);

Future<void> showRequestDetailSheet(
  BuildContext context, {
  required InboxItem item,
  required RespondToRequest onRespond,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => RequestDetailSheet(item: item, onRespond: onRespond),
  );
}

class RequestDetailSheet extends StatelessWidget {
  const RequestDetailSheet({
    super.key,
    required this.item,
    required this.onRespond,
  });

  final InboxItem item;
  final RespondToRequest onRespond;

  static const Map<String, String> _labels = {
    'occasion': 'Occasion',
    'service': 'Service',
    'budget': 'Budget',
    'deadline': 'Needed by',
    'preferredDate': 'Preferred date',
    'location': 'Location',
    'measurements': 'Measurements',
    'notes': 'Notes',
  };

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RequestDetailController>(
      init: RequestDetailController(onRespond: onRespond),
      global: false,
      builder: (controller) => _view(context, controller),
    );
  }

  Widget _view(BuildContext context, RequestDetailController controller) {
    final colors = Theme.of(context).colorScheme;
    final rows = [
      for (final entry in _labels.entries)
        if ((item.data[entry.key] ?? '').toString().trim().isNotEmpty)
          (entry.value, item.data[entry.key].toString().trim()),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${item.kind.label} from ${item.customerName} · '
              '${item.statusLabel}',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Text(value),
                  ],
                ),
              ),
            Obx(() {
              final error = controller.error.value;
              if (error == null) return const SizedBox.shrink();
              return Text(error, style: TextStyle(color: colors.error));
            }),
            const SizedBox(height: 8),
            if (item.needsAction)
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const ValueKey('decline'),
                        onPressed: controller.busy.value
                            ? null
                            : () => controller.answer('declined'),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const ValueKey('accept'),
                        onPressed: controller.busy.value
                            ? null
                            : () => controller.answer('accepted'),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              )
            else if (item.status == 'accepted')
              Obx(
                () => FilledButton(
                  key: const ValueKey('complete'),
                  onPressed: controller.busy.value
                      ? null
                      : () => controller.answer('completed'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Mark as completed'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
