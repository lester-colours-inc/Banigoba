// A custom design request, for the customer and for the designer.
import 'package:flutter/material.dart';

class DesignRequestCard extends StatelessWidget {
  const DesignRequestCard({
    super.key,
    required this.data,
    this.designerView = false,
    this.onMessage,
    this.onStatusSelected,
  });

  final Map<String, dynamic> data;
  final bool designerView;
  final VoidCallback? onMessage;
  final ValueChanged<String>? onStatusSelected;

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? 'pending').toString();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    (data['occasion'] ?? 'Custom design').toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(label: Text(status)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              designerView
                  ? 'Customer: ${data['customerName'] ?? 'Customer'}'
                  : 'Designer: ${data['designerName'] ?? 'Designer'}',
            ),
            if ((data['deadline'] ?? '').toString().isNotEmpty)
              Text('Deadline: ${data['deadline']}'),
            if ((data['budget'] ?? '').toString().isNotEmpty)
              Text('Budget: ${data['budget']}'),
            if (designerView &&
                (data['measurements'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Measurements: ${data['measurements']}'),
            ],
            if ((data['notes'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                data['notes'].toString(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (onMessage != null || designerView && onStatusSelected != null)
              const SizedBox(height: 12),
            if (onMessage != null)
              OutlinedButton.icon(
                onPressed: onMessage,
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(
                  designerView ? 'Message Customer' : 'Message Designer',
                ),
              ),
            if (designerView && onStatusSelected != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statusButton('Accept', 'accepted'),
                  _statusButton('Decline', 'declined'),
                  _statusButton('Complete', 'completed'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusButton(String label, String status) {
    return OutlinedButton(
      onPressed: () => onStatusSelected?.call(status),
      child: Text(label),
    );
  }
}
