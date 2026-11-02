// Streams a provider's orders and requests into one list and records the
// answer to a request (see provider_inbox.dart).
import 'dart:async';

import '../../core/supabase/supabase_config.dart';
import '../supabase/rows.dart';

import '../models/provider_inbox.dart';
import '../models/provider_roles.dart';
import 'notification_service.dart';
import 'order_service.dart' show orderMap;

class ProviderInboxService {
  Stream<List<InboxItem>> _source({
    required String table,
    required String column,
    required String userId,
    required Map<String, dynamic> Function(Map<String, dynamic> row) read,
    required InboxItem Function(
      String id,
      Map<String, dynamic> data,
      DateTime? createdAt,
    )
    build,
  }) {
    return supabase
        .from(table)
        .stream(primaryKey: ['id'])
        .eq(column, userId)
        .map(
          (rows) => [
            for (final row in rows)
              build(
                row['id'].toString(),
                read(row),
                asDateTime(row['created_at']),
              ),
          ],
        );
  }

  /// Everything addressed to [userId] for the roles they hold, merged. A role
  /// that fails to load (for example, no access yet) is left out rather than
  /// blanking the others.
  Stream<List<InboxItem>> watch(String userId, List<ProviderRole> roles) {
    final sources = <Stream<List<InboxItem>>>[
      if (roles.contains(ProviderRole.shop))
        _source(
          table: 'orders',
          column: 'seller_id',
          userId: userId,
          read: orderMap,
          build: (id, data, at) => InboxItem.fromOrder(id, data, createdAt: at),
        ),
      if (roles.contains(ProviderRole.designer))
        _source(
          table: 'design_requests',
          column: 'designer_id',
          userId: userId,
          read: flattenRow,
          build: (id, data, at) =>
              InboxItem.fromDesignRequest(id, data, createdAt: at),
        ),
      if (roles.contains(ProviderRole.salon))
        _source(
          table: 'agent_requests',
          column: 'agent_id',
          userId: userId,
          read: flattenRow,
          build: (id, data, at) =>
              InboxItem.fromAgentRequest(id, data, createdAt: at),
        ),
    ];
    return _merge(sources);
  }

  Stream<List<InboxItem>> _merge(List<Stream<List<InboxItem>>> sources) {
    late final StreamController<List<InboxItem>> controller;
    final subscriptions = <StreamSubscription<List<InboxItem>>>[];
    final latest = List<List<InboxItem>>.filled(sources.length, const []);
    controller = StreamController<List<InboxItem>>(
      onListen: () {
        if (sources.isEmpty) controller.add(const []);
        for (var i = 0; i < sources.length; i += 1) {
          subscriptions.add(
            sources[i].listen((items) {
              latest[i] = items;
              controller.add(mergeInbox(latest));
            }, onError: (Object _) => controller.add(mergeInbox(latest))),
          );
        }
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );
    return controller.stream;
  }

  /// Accepts, declines or completes a design or hair request, and tells the
  /// customer.
  Future<void> respond({
    required InboxItem item,
    required String status,
    required String providerName,
  }) async {
    final collection = switch (item.kind) {
      InboxKind.design => 'design_requests',
      InboxKind.hair => 'agent_requests',
      InboxKind.order => throw ArgumentError('Orders are answered in Orders.'),
    };
    await supabase.from(collection).update({'status': status}).eq('id', item.id);

    if (item.customerId.isEmpty || item.status == status) return;
    final what = item.kind == InboxKind.design ? 'design' : 'hair';
    final word = switch (status) {
      'accepted' => 'accepted',
      'declined' => 'declined',
      'completed' => 'marked as completed',
      _ => 'updated',
    };
    await NotificationService().addNotification(
      receiverId: item.customerId,
      title: '${item.kind.label} ${word.split(' ').first}',
      body: '$providerName $word your ${item.title} $what request.',
      type: item.kind == InboxKind.design
          ? 'designer_request_status'
          : 'agent_request_status',
      extraData: {'requestId': item.id, 'requestStatus': status},
    );
  }
}
