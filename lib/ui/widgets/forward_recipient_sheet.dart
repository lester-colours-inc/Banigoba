// Picks who inside Banigoba a look is forwarded to: a hair salon (a verified
// hair agent), a verified boutique, or a verified designer.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum ForwardRecipientKind {
  salon('Hair salons', 'No verified hair salons yet.', Icons.content_cut),
  shop('Shops', 'No verified shops yet.', Icons.storefront_outlined),
  designer(
    'Designers',
    'No verified designers yet.',
    Icons.design_services_outlined,
  );

  const ForwardRecipientKind(this.title, this.emptyLabel, this.icon);

  final String title;
  final String emptyLabel;
  final IconData icon;
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
}

/// Lists the verified recipients of [kind]. Returns null when cancelled.
Future<ForwardRecipient?> showForwardRecipientSheet(
  BuildContext context,
  ForwardRecipientKind kind,
) {
  return showModalBottomSheet<ForwardRecipient>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ForwardRecipientSheet(kind: kind),
  );
}

Query<Map<String, dynamic>> _recipientQuery(ForwardRecipientKind kind) {
  final users = FirebaseFirestore.instance.collection('users');
  return switch (kind) {
    ForwardRecipientKind.salon =>
      users
          .where('agentProfile.active', isEqualTo: true)
          .where('agentProfile.verified', isEqualTo: true)
          .where('agentProfile.type', isEqualTo: 'hair'),
    ForwardRecipientKind.shop => users.where('shop.verified', isEqualTo: true),
    ForwardRecipientKind.designer =>
      users
          .where('designerProfile.active', isEqualTo: true)
          .where('designerProfile.verified', isEqualTo: true),
  };
}

ForwardRecipient _recipientFromDoc(
  ForwardRecipientKind kind,
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data();
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
    id: doc.id,
    name: (profile['name'] ?? data['displayName'] ?? fallbackName).toString(),
    avatarUrl:
        (profile['avatarUrl'] ??
                data['profileImageURL'] ??
                data['profileImageUrl'] ??
                '')
            .toString(),
    detail: (profile['location'] ?? profile['description'] ?? '').toString(),
  );
}

class _ForwardRecipientSheet extends StatefulWidget {
  const _ForwardRecipientSheet({required this.kind});

  final ForwardRecipientKind kind;

  @override
  State<_ForwardRecipientSheet> createState() => _ForwardRecipientSheetState();
}

class _ForwardRecipientSheetState extends State<_ForwardRecipientSheet> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _recipients =
      _recipientQuery(widget.kind).snapshots();
  String _query = '';

  bool _matches(ForwardRecipient recipient) {
    if (_query.isEmpty) return true;
    return recipient.name.toLowerCase().contains(_query) ||
        recipient.detail.toLowerCase().contains(_query);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
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
                'Forward to ${widget.kind.title.toLowerCase()}',
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
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search by name or location',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _recipients,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _SheetMessage(
                      icon: Icons.warning_amber_rounded,
                      text:
                          'Could not load ${widget.kind.title.toLowerCase()}.',
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final recipients = snapshot.data!.docs
                      .where((doc) => doc.id != currentUserId)
                      .map((doc) => _recipientFromDoc(widget.kind, doc))
                      .where(_matches)
                      .toList();
                  if (recipients.isEmpty) {
                    return _SheetMessage(
                      icon: widget.kind.icon,
                      text: _query.isEmpty
                          ? widget.kind.emptyLabel
                          : 'No matches for "$_query".',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                    itemCount: recipients.length,
                    itemBuilder: (context, index) {
                      final recipient = recipients[index];
                      return ListTile(
                        key: ValueKey('forward_recipient_${recipient.id}'),
                        leading: CircleAvatar(
                          backgroundImage: recipient.avatarUrl.isEmpty
                              ? null
                              : CachedNetworkImageProvider(recipient.avatarUrl),
                          child: recipient.avatarUrl.isEmpty
                              ? Icon(widget.kind.icon, size: 20)
                              : null,
                        ),
                        title: Text(recipient.name),
                        subtitle: recipient.detail.isEmpty
                            ? null
                            : Text(
                                recipient.detail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                        trailing: const Icon(Icons.send_outlined),
                        onTap: () => Navigator.pop(context, recipient),
                      );
                    },
                  );
                },
              ),
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
