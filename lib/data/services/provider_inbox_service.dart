// Streams a provider's orders and requests into one list and records the
// answer to a request (see provider_inbox.dart).
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/provider_inbox.dart';
import '../models/provider_roles.dart';
import 'notification_service.dart';

class ProviderInboxService {
  ProviderInboxService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DateTime? _when(Object? stamp) => stamp is Timestamp ? stamp.toDate() : null;

  Stream<List<InboxItem>> _source({
    required String collection,
    required String field,
    required String userId,
    required InboxItem Function(
      String id,
      Map<String, dynamic> data,
      DateTime? createdAt,
    )
    build,
  }) {
    return _db
        .collection(collection)
        .where(field, isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs)
              build(doc.id, doc.data(), _when(doc.data()['createdAt'])),
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
          collection: 'orders',
          field: 'sellerId',
          userId: userId,
          build: (id, data, at) => InboxItem.fromOrder(id, data, createdAt: at),
        ),
      if (roles.contains(ProviderRole.designer))
        _source(
          collection: 'design_requests',
          field: 'designerId',
          userId: userId,
          build: (id, data, at) =>
              InboxItem.fromDesignRequest(id, data, createdAt: at),
        ),
      if (roles.contains(ProviderRole.salon))
        _source(
          collection: 'agent_requests',
          field: 'agentId',
          userId: userId,
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
    await _db.collection(collection).doc(item.id).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

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
