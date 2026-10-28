// The details of a design or hair request, with the answers a provider can
// give: accept or decline a new one, mark an accepted one completed.
import 'package:flutter/material.dart';

import '../../../data/models/provider_inbox.dart';

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

class RequestDetailSheet extends StatefulWidget {
  const RequestDetailSheet({
    super.key,
    required this.item,
    required this.onRespond,
  });

  final InboxItem item;
  final RespondToRequest onRespond;

  @override
  State<RequestDetailSheet> createState() => _RequestDetailSheetState();
}

class _RequestDetailSheetState extends State<RequestDetailSheet> {
  bool _busy = false;
  String? _error;

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

  Future<void> _answer(String status) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onRespond(status);
      if (mounted) Navigator.pop(context);
    } on Exception catch (error) {
      if (mounted) setState(() => _error = 'Could not save: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
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
            if (_error != null)
              Text(_error!, style: TextStyle(color: colors.error)),
            const SizedBox(height: 8),
            if (item.needsAction)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey('decline'),
                      onPressed: _busy ? null : () => _answer('declined'),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('accept'),
                      onPressed: _busy ? null : () => _answer('accepted'),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              )
            else if (item.status == 'accepted')
              FilledButton(
                key: const ValueKey('complete'),
                onPressed: _busy ? null : () => _answer('completed'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Mark as completed'),
              ),
          ],
        ),
      ),
    );
  }
}
