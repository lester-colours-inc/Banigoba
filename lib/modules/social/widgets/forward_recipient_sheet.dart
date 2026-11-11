// Picks who inside Banigoba a look is sent to: a hair salon (a verified hair
// agent), a verified boutique, or a verified designer. The user's own
// salons, shops and designers (My Circle) show first, in a row above the
// search, and anyone can be added to or removed from My Circle here
// (October 2026 review, P-6 and P-7).
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/social/controllers/forward_recipient_controller.dart';
import 'package:banigoba/modules/social/services/circle_service.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';

enum ForwardRecipientKind {
  salon(
    'Hair salons',
    'No verified hair salons yet.',
    Icons.content_cut,
    CircleKind.salon,
  ),
  shop(
    'Shops',
    'No verified shops yet.',
    Icons.storefront_outlined,
    CircleKind.shop,
  ),
  designer(
    'Designers',
    'No verified designers yet.',
    Icons.design_services_outlined,
    CircleKind.designer,
  );

  const ForwardRecipientKind(
    this.title,
    this.emptyLabel,
    this.icon,
    this.circleKind,
  );

  final String title;
  final String emptyLabel;
  final IconData icon;
  final CircleKind circleKind;
}

@immutable
class ForwardRecipient {
  const ForwardRecipient({
    required this.id,
    required this.name,
    this.avatarUrl = '',
    this.detail = '',
  });

  final String id;
  final String name;
  final String avatarUrl;
  final String detail;

  CircleMember toCircleMember(CircleKind kind) => CircleMember(
    id: id,
    kind: kind,
    name: name,
    avatarUrl: avatarUrl,
    detail: detail,
  );
}

/// My Circle members first (in Circle order), then everyone else; both
/// filtered by [matches].
({List<ForwardRecipient> circle, List<ForwardRecipient> others}) splitByCircle(
  List<ForwardRecipient> recipients,
  Set<String> circleIds,
) => (
  circle: List.unmodifiable(recipients.where((r) => circleIds.contains(r.id))),
  others: List.unmodifiable(recipients.where((r) => !circleIds.contains(r.id))),
);

/// Lists the verified recipients of [kind]. Returns null when cancelled.
Future<ForwardRecipient?> showForwardRecipientSheet(
  BuildContext context,
  ForwardRecipientKind kind, {
  String? title,
}) {
  return showModalBottomSheet<ForwardRecipient>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ForwardRecipientSheet(kind: kind, title: title),
  );
}

Future<List<Map<String, dynamic>>> _loadRecipients(ForwardRecipientKind kind) =>
    ProfileService().verifiedProviders(kind.name);

ForwardRecipient _recipientFromProfile(
  ForwardRecipientKind kind,
  Map<String, dynamic> data,
) {
  final profileKey = switch (kind) {
    ForwardRecipientKind.salon => 'agentProfile',
    ForwardRecipientKind.shop => 'shop',
    ForwardRecipientKind.designer => 'designerProfile',
  };
  final profile = Map<String, dynamic>.from(
    data[profileKey] as Map? ?? const {},
  );
  final fallbackName = switch (kind) {
    ForwardRecipientKind.salon => 'Hair salon',
    ForwardRecipientKind.shop => 'Boutique',
    ForwardRecipientKind.designer => 'Designer',
  };
  return ForwardRecipient(
    id: data['id'].toString(),
    name: (profile['name'] ?? data['displayName'] ?? fallbackName).toString(),
    avatarUrl: (profile['avatarUrl'] ?? data['profileImageUrl'] ?? '')
        .toString(),
    detail: (profile['location'] ?? profile['description'] ?? '').toString(),
  );
}

class _ForwardRecipientSheet extends StatelessWidget {
  const _ForwardRecipientSheet({required this.kind, this.title});

  final ForwardRecipientKind kind;

  /// Defaults to "Send to …"; e.g. "Find a salon" when adding to My Circle.
  final String? title;

  @override
  Widget build(BuildContext context) {
    // Scoped to this sheet: created and disposed with the widget.
    return GetBuilder<ForwardRecipientController>(
      init: ForwardRecipientController(recipients: _loadRecipients(kind)),
      global: false,
      builder: (controller) =>
          _SheetBody(controller: controller, kind: kind, title: title),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.controller,
    required this.kind,
    required this.title,
  });

  final ForwardRecipientController controller;
  final ForwardRecipientKind kind;
  final String? title;

  String get _query => controller.query.value;

  bool _matches(ForwardRecipient recipient) {
    if (_query.isEmpty) return true;
    return recipient.name.toLowerCase().contains(_query) ||
        recipient.detail.toLowerCase().contains(_query);
  }

  Widget _buildList(
    BuildContext context,
    AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
    String currentUserId,
    Set<String> circleIds,
  ) {
    if (snapshot.hasError) {
      return _SheetMessage(
        icon: Icons.warning_amber_rounded,
        text: 'Could not load ${kind.title.toLowerCase()}.',
      );
    }
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    final all = snapshot.data!
        .where((profile) => profile['id'] != currentUserId)
        .map((profile) => _recipientFromProfile(kind, profile))
        .toList();
    final split = splitByCircle(all.where(_matches).toList(), circleIds);
    final circleAll = splitByCircle(all, circleIds).circle;
    if (split.circle.isEmpty && split.others.isEmpty && circleAll.isEmpty) {
      return _SheetMessage(
        icon: kind.icon,
        text: _query.isEmpty ? kind.emptyLabel : 'No matches for "$_query".',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      children: [
        // P-6: the ones you already know, one tap away, above the list.
        if (circleAll.isNotEmpty && _query.isEmpty) ...[
          const _ListLabel('From My Circle'),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: circleAll.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) => _CircleChip(
                recipient: circleAll[index],
                icon: kind.icon,
                onTap: () => Navigator.pop(context, circleAll[index]),
              ),
            ),
          ),
          const _ListLabel('Everyone'),
        ],
        if (_query.isNotEmpty)
          for (final recipient in split.circle)
            _tile(context, recipient, inCircle: true),
        for (final recipient in split.others)
          _tile(context, recipient, inCircle: false),
        if (_query.isNotEmpty && split.circle.isEmpty && split.others.isEmpty)
          _SheetMessage(icon: kind.icon, text: 'No matches for "$_query".'),
      ],
    );
  }

  Widget _tile(
    BuildContext context,
    ForwardRecipient recipient, {
    required bool inCircle,
  }) {
    return ListTile(
      key: ValueKey('forward_recipient_${recipient.id}'),
      leading: CircleAvatar(
        backgroundImage: recipient.avatarUrl.isEmpty
            ? null
            : CachedNetworkImageProvider(recipient.avatarUrl),
        child: recipient.avatarUrl.isEmpty ? Icon(kind.icon, size: 20) : null,
      ),
      title: Text(recipient.name),
      subtitle: recipient.detail.isEmpty
          ? null
          : Text(
              recipient.detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: controller.userId.isEmpty
          ? const Icon(Icons.send_outlined)
          : IconButton(
              key: ValueKey('circle_toggle_${recipient.id}'),
              tooltip: inCircle ? 'Remove from My Circle' : 'Add to My Circle',
              icon: Icon(
                inCircle
                    ? Icons.group_remove_outlined
                    : Icons.group_add_outlined,
                color: inCircle ? Theme.of(context).colorScheme.primary : null,
              ),
              onPressed: () => controller.toggleCircle(
                recipient.toCircleMember(kind.circleKind),
                inCircle: inCircle,
              ),
            ),
      onTap: () => Navigator.pop(context, recipient),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AppAuth.instance.currentUser?.uid ?? '';
    final height = MediaQuery.sizeOf(context).height * 0.7;

    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                title ?? 'Send to ${kind.title.toLowerCase()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                key: const ValueKey('forward_recipient_search'),
                onChanged: controller.onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search by name or location',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Obx(() {
                // Read here so typing in the search re-filters the list.
                final _ = controller.query.value;
                return StreamBuilder<List<CircleMember>>(
                  stream: controller.members,
                  builder: (context, circleSnapshot) {
                    final circleIds = {
                      for (final member
                          in circleSnapshot.data ?? const <CircleMember>[])
                        if (member.kind == kind.circleKind) member.id,
                    };
                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: controller.recipients,
                      builder: (context, snapshot) => _buildList(
                        context,
                        snapshot,
                        currentUserId,
                        circleIds,
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListLabel extends StatelessWidget {
  const _ListLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CircleChip extends StatelessWidget {
  const _CircleChip({
    required this.recipient,
    required this.icon,
    required this.onTap,
  });

  final ForwardRecipient recipient;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('circle_chip_${recipient.id}'),
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: recipient.avatarUrl.isEmpty
                  ? null
                  : CachedNetworkImageProvider(recipient.avatarUrl),
              child: recipient.avatarUrl.isEmpty ? Icon(icon) : null,
            ),
            const SizedBox(height: 6),
            Text(
              recipient.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetMessage extends StatelessWidget {
  const _SheetMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: colors.onSurfaceVariant),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
