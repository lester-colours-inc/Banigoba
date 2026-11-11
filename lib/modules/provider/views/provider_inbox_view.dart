// The list inside "Orders & requests": filter chips, then one card per
// order or request, the ones waiting for an answer first.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/provider/controllers/provider_inbox_filter_controller.dart';
import 'package:banigoba/modules/provider/models/provider_inbox.dart';

class ProviderInboxView extends StatelessWidget {
  const ProviderInboxView({
    super.key,
    required this.items,
    required this.onOpen,
  });

  final List<InboxItem> items;
  final ValueChanged<InboxItem> onOpen;

  static const Map<InboxKind, IconData> _icons = {
    InboxKind.order: Icons.receipt_long_outlined,
    InboxKind.design: Icons.design_services_outlined,
    InboxKind.hair: Icons.content_cut,
  };

  @override
  Widget build(BuildContext context) {
    // Scoped to this list: only the chosen filter lives in the controller.
    return GetBuilder<ProviderInboxFilterController>(
      init: ProviderInboxFilterController(),
      global: false,
      builder: (filter) => Obx(() => _list(context, filter)),
    );
  }

  Widget _list(BuildContext context, ProviderInboxFilterController filter) {
    final colors = Theme.of(context).colorScheme;
    final only = filter.only.value;
    final kinds = {for (final item in items) item.kind};
    final shown = mergeInbox([items], only: only);
    return Column(
      children: [
        if (kinds.length > 1)
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                _chip('All', only == null, () => filter.select(null)),
                for (final kind in InboxKind.values)
                  if (kinds.contains(kind))
                    _chip(
                      kind.filterLabel,
                      only == kind,
                      () => filter.select(kind),
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
        onTap: () => onOpen(item),
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
