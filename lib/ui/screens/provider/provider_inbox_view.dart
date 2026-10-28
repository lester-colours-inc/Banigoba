// The list inside "Orders & requests": filter chips, then one card per
// order or request, the ones waiting for an answer first.
import 'package:flutter/material.dart';

import '../../../data/models/provider_inbox.dart';

class ProviderInboxView extends StatefulWidget {
  const ProviderInboxView({
    super.key,
    required this.items,
    required this.onOpen,
  });

  final List<InboxItem> items;
  final ValueChanged<InboxItem> onOpen;

  @override
  State<ProviderInboxView> createState() => _ProviderInboxViewState();
}

class _ProviderInboxViewState extends State<ProviderInboxView> {
  InboxKind? _only;

  static const Map<InboxKind, IconData> _icons = {
    InboxKind.order: Icons.receipt_long_outlined,
    InboxKind.design: Icons.design_services_outlined,
    InboxKind.hair: Icons.content_cut,
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final kinds = {for (final item in widget.items) item.kind};
    final shown = mergeInbox([widget.items], only: _only);
    return Column(
      children: [
        if (kinds.length > 1)
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                _chip('All', _only == null, () => setState(() => _only = null)),
                for (final kind in InboxKind.values)
                  if (kinds.contains(kind))
                    _chip(
                      kind.filterLabel,
                      _only == kind,
                      () => setState(() => _only = kind),
                    ),
              ],
            ),
          ),
        Expanded(
          child: shown.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Nothing yet. Orders and requests from customers will '
                      'appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: shown.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _card(context, shown[index]),
                ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        key: ValueKey('filter_$label'),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _card(BuildContext context, InboxItem item) {
    final colors = Theme.of(context).colorScheme;
    final open = item.needsAction;
    return Card(
      key: ValueKey('inbox_${item.kind.name}_${item.id}'),
      elevation: open ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: open ? colors.primary : colors.outlineVariant,
          width: open ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        onTap: () => widget.onOpen(item),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0D0140),
          foregroundColor: Colors.white,
          child: Icon(_icons[item.kind]),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          [
            '${item.kind.label} from ${item.customerName}',
            if (item.detail.isNotEmpty) item.detail,
          ].join('\n'),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: open ? colors.primary : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            item.statusLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: open ? colors.onPrimary : colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
