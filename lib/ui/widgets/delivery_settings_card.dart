// "Delivery" in My Shop (K-3): whether the shop delivers itself, the fee and
// the areas it covers. Buyers see these at checkout; the fee they pay is
// always recomputed from what is saved here.
import 'package:flutter/material.dart';

import '../../data/models/delivery.dart';

class DeliverySettingsCard extends StatefulWidget {
  const DeliverySettingsCard({
    super.key,
    required this.initial,
    required this.onSave,
  });

  final DeliverySettings initial;
  final Future<void> Function(DeliverySettings settings) onSave;

  @override
  State<DeliverySettingsCard> createState() => _DeliverySettingsCardState();
}

class _DeliverySettingsCardState extends State<DeliverySettingsCard> {
  late bool _delivers = widget.initial.delivers;
  late final TextEditingController _fee = TextEditingController(
    text: widget.initial.delivers || widget.initial.fee > 0
        ? widget.initial.fee.toStringAsFixed(2)
        : '',
  );
  late final TextEditingController _areas = TextEditingController(
    text: widget.initial.areas.join(', '),
  );
  late final TextEditingController _note = TextEditingController(
    text: widget.initial.note,
  );
  bool _saving = false;
  String? _error;
  bool _saved = false;

  @override
  void dispose() {
    _fee.dispose();
    _areas.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final feeText = _fee.text.trim().replaceAll(',', '.');
    final fee = feeText.isEmpty ? 0.0 : double.tryParse(feeText);
    if (_delivers && (fee == null || fee < 0)) {
      setState(() => _error = 'Enter the fee as a number, like 2.50.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _saved = false;
    });
    try {
      await widget.onSave(
        DeliverySettings.cleaned(
          delivers: _delivers,
          fee: fee ?? 0,
          areas: _areas.text.split(','),
          note: _note.text,
        ),
      );
      if (mounted) setState(() => _saved = true);
    } on Exception catch (error) {
      if (mounted) setState(() => _error = 'Could not save: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              key: const ValueKey('delivers_switch'),
              contentPadding: EdgeInsets.zero,
              value: _delivers,
              onChanged: (on) => setState(() {
                _delivers = on;
                _saved = false;
              }),
              secondary: const Icon(Icons.local_shipping_outlined),
              title: const Text(
                'I deliver',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Buyers can choose delivery instead of collecting. You '
                'deliver yourself and set the fee.',
              ),
            ),
            if (_delivers) ...[
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('delivery_fee'),
                controller: _fee,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Delivery fee',
                  prefixText: '\$ ',
                  helperText: 'Leave empty for free delivery.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('delivery_areas'),
                controller: _areas,
                decoration: const InputDecoration(
                  labelText: 'Areas you deliver to',
                  helperText:
                      'Separate with commas. Leave empty to deliver anywhere '
                      'the buyer gives an address.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('delivery_note'),
                controller: _note,
                decoration: const InputDecoration(
                  labelText: 'Note for buyers (optional)',
                  helperText: 'For example: same day before 4pm.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: colors.error)),
            ],
            if (_saved) ...[
              const SizedBox(height: 10),
              Text('Saved.', style: TextStyle(color: colors.primary)),
            ],
            const SizedBox(height: 12),
            FilledButton(
              key: const ValueKey('save_delivery'),
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(_saving ? 'Saving...' : 'Save delivery'),
            ),
          ],
        ),
      ),
    );
  }
}
