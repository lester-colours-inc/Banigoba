// Reads the affirmation library and records affirmation interactions.
//
// Two deliberate design choices, both required by BNG SRS 001:
//
//   1. No counter is written onto the target document. Affirmations live in
//      their own top-level collection and are counted only when a specific
//      caller asks — the recipient, privately, or operations in aggregate.
//      A denormalised total on the post is precisely what turned the previous
//      like implementation into a public scoreboard (AFF-003, SRS-DEC-010).
//
//   2. Cultural library entries are withheld unless a curator has approved
//      them AND provenance is present. The client cannot serve heritage
//      content that nobody signed off.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../affirmations/affirmation_library.dart';
import '../models/affirmation.dart';
import 'notification_service.dart';

class AffirmationService {
  AffirmationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    NotificationService? notifications,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _notifications = notifications ?? NotificationService();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final NotificationService _notifications;

  static const String affirmationsCollection = 'affirmations';
  static const String libraryCollection = 'affirmation_library';

  String get _currentUserId => _auth.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> get _affirmations =>
      _db.collection(affirmationsCollection);

  /// Deterministic document id, so sending the same affirmation twice is a
  /// no-op rather than a duplicate. Also makes the legacy-like backfill
  /// idempotent.
  static String documentIdFor({
    required AffirmationTargetType targetType,
    required String targetId,
    required String senderId,
    required String definitionId,
  }) {
    final definitionKey = definitionId.replaceAll('/', '_');
    return '${targetType.id}__${targetId}__${senderId}__$definitionKey';
  }

  // ── Library ─────────────────────────────────────────────────────────────

  /// Every affirmation the signed-in user may send right now.
  ///
  /// Universal entries always resolve. Cultural entries are appended only
  /// when a curator approved them and provenance is recorded; a failure to
  /// read the curator collection degrades to the universal set rather than
  /// blocking the composer.
  Future<List<AffirmationDefinition>> availableDefinitions() async {
    final cultural = await _servableCuratedDefinitions();
    return [...kUniversalAffirmations, ...cultural];
  }

  Future<List<AffirmationDefinition>> _servableCuratedDefinitions() async {
    try {
      final snapshot = await _db
          .collection(libraryCollection)
          .where('reviewState', isEqualTo: AffirmationReviewState.approved.id)
          .get();

      return snapshot.docs
          .map(AffirmationDefinition.fromFirestore)
          .where((definition) => definition.isServable)
          .toList();
    } on FirebaseException catch (error) {
      debugPrint('Affirmation library unavailable: ${error.code}');
      return const [];
    }
  }

  /// Resolves a stored affirmation's library entry, falling back to the
  /// universal set when the entry was revised or retired.
  AffirmationDefinition definitionForOrFallback(String definitionId) {
    return universalAffirmationById(definitionId) ?? kFallbackAffirmation;
  }

  // ── Sending ─────────────────────────────────────────────────────────────

  /// Records an affirmation from the signed-in user.
  ///
  /// Throws [StateError] when nobody is signed in, the definition is not
  /// servable, or the user is affirming their own look.
  Future<void> send({
    required AffirmationTargetType targetType,
    required String targetId,
    required String targetOwnerId,
    required AffirmationDefinition definition,
    String personalMessage = '',
  }) async {
    final senderId = _currentUserId;
    if (senderId.isEmpty) {
      throw StateError('Sign in to send an affirmation.');
    }
    if (!definition.isServable) {
      throw StateError('That affirmation is not available yet.');
    }
    if (targetId.isEmpty || targetOwnerId.isEmpty) {
      throw StateError('This look cannot be affirmed.');
    }
    if (targetOwnerId == senderId) {
      throw StateError('You cannot affirm your own look.');
    }

    final senderName = await _resolveSenderName(senderId);
    final docId = documentIdFor(
      targetType: targetType,
      targetId: targetId,
      senderId: senderId,
      definitionId: definition.id,
    );

    await _affirmations.doc(docId).set({
      'senderId': senderId,
      'senderName': senderName,
      'targetType': targetType.id,
      'targetId': targetId,
      'targetOwnerId': targetOwnerId,
      'definitionId': definition.id,
      'emoji': definition.emoji,
      'shortLabel': definition.shortLabel,
      'text': definition.text,
      'category': definition.category.id,
      'language': definition.language,
      'meaning': definition.meaning,
      'personalMessage': personalMessage.trim(),
      'moderationState': 'clear',
      'migratedFromLike': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _notifyRecipient(
      recipientId: targetOwnerId,
      senderName: senderName,
      definition: definition,
      targetId: targetId,
      targetType: targetType,
    );
  }

  /// Removes the signed-in user's own affirmation.
  Future<void> withdraw({
    required AffirmationTargetType targetType,
    required String targetId,
    required String definitionId,
  }) async {
    final senderId = _currentUserId;
    if (senderId.isEmpty) return;

    await _affirmations
        .doc(
          documentIdFor(
            targetType: targetType,
            targetId: targetId,
            senderId: senderId,
            definitionId: definitionId,
          ),
        )
        .delete();
  }

  /// Deletes every affirmation attached to a target. Called when the owner
  /// deletes the look, so affirmations do not outlive what they were about.
  Future<void> deleteAllForTarget({
    required AffirmationTargetType targetType,
    required String targetId,
  }) async {
    final snapshot = await _affirmations
        .where('targetType', isEqualTo: targetType.id)
        .where('targetId', isEqualTo: targetId)
        .get();
    if (snapshot.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ── Reading ─────────────────────────────────────────────────────────────

  /// Affirmations attached to one target, newest first.
  Stream<List<Affirmation>> watchForTarget({
    required AffirmationTargetType targetType,
    required String targetId,
  }) {
    if (targetId.isEmpty) return Stream.value(const []);

    return _affirmations
        .where('targetType', isEqualTo: targetType.id)
        .where('targetId', isEqualTo: targetId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(Affirmation.fromFirestore)
                  .where((affirmation) => affirmation.isVisible)
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  /// The distinct expressions a target has received, in first-received order.
  ///
  /// This is what the feed renders. It deliberately exposes *which* kinds of
  /// affirmation a look received and not how many, so no screen can be read
  /// as a score.
  Stream<List<AffirmationFacet>> watchFacetsForTarget({
    required AffirmationTargetType targetType,
    required String targetId,
  }) {
    return watchForTarget(
      targetType: targetType,
      targetId: targetId,
    ).map(affirmationFacetsOf);
  }

  /// Definition ids the signed-in user has already sent to a target.
  Stream<Set<String>> watchOwnSent({
    required AffirmationTargetType targetType,
    required String targetId,
  }) {
    final senderId = _currentUserId;
    if (senderId.isEmpty || targetId.isEmpty) {
      return Stream.value(const <String>{});
    }

    return _affirmations
        .where('targetType', isEqualTo: targetType.id)
        .where('targetId', isEqualTo: targetId)
        .where('senderId', isEqualTo: senderId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => (doc.data()['definitionId'] ?? '').toString())
              .where((id) => id.isNotEmpty)
              .toSet(),
        );
  }

  /// Ids of the posts the signed-in user has affirmed, for "Looks I
  /// affirmed" in the look-you-love picker (M-10).
  Stream<Set<String>> watchAffirmedPostIds() {
    final senderId = _currentUserId;
    if (senderId.isEmpty) return Stream.value(const <String>{});
    return _affirmations
        .where('senderId', isEqualTo: senderId)
        .where('targetType', isEqualTo: AffirmationTargetType.post.id)
        .snapshots()
        .map(
          (snapshot) => {
            for (final doc in snapshot.docs)
              if ((doc.data()['targetId'] ?? '').toString() case final id
                  when id.isNotEmpty)
                id,
          },
        );
  }

  /// Private summary for the recipient's own eyes.
  ///
  /// Permitted by the spec as a private, purpose-specific signal. Must never
  /// be rendered on a public surface.
  Stream<List<Affirmation>> watchReceivedPrivately(String ownerId) {
    if (ownerId.isEmpty) return Stream.value(const []);

    return _affirmations
        .where('targetOwnerId', isEqualTo: ownerId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(Affirmation.fromFirestore)
                  .where((affirmation) => affirmation.isVisible)
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  // ── Internals ───────────────────────────────────────────────────────────

  Future<String> _resolveSenderName(String senderId) async {
    final fallback =
        _auth.currentUser?.displayName ??
        _auth.currentUser?.email?.split('@').first ??
        'Someone';
    try {
      final user = await _db.collection('users').doc(senderId).get();
      final displayName = user.data()?['displayName'];
      if (displayName is String && displayName.trim().isNotEmpty) {
        return displayName.trim();
      }
    } on FirebaseException catch (error) {
      debugPrint('Unable to resolve sender name: ${error.code}');
    }
    return fallback;
  }

  Future<void> _notifyRecipient({
    required String recipientId,
    required String senderName,
    required AffirmationDefinition definition,
    required String targetId,
    required AffirmationTargetType targetType,
  }) async {
    try {
      await _notifications.addNotification(
        receiverId: recipientId,
        title: 'New affirmation',
        body: '$senderName affirmed your look: ${definition.shortLabel}',
        type: 'affirmation',
        extraData: {
          'fromId': _currentUserId,
          'fromName': senderName,
          'targetId': targetId,
          'targetType': targetType.id,
          'definitionId': definition.id,
        },
      );
    } on FirebaseException catch (error) {
      // A missed notification must not fail the affirmation itself.
      debugPrint('Unable to notify affirmation recipient: ${error.code}');
    }
  }
}

/// One distinct expression a target received, with how many senders used it.
///
/// [senderCount] exists for the recipient's private view and for operational
/// aggregates. Public surfaces render [emoji] and [shortLabel] only.
class AffirmationFacet {
  const AffirmationFacet({
    required this.definitionId,
    required this.emoji,
    required this.shortLabel,
    required this.category,
    required this.senderCount,
  });

  final String definitionId;
  final String emoji;
  final String shortLabel;
  final AffirmationCategory category;
  final int senderCount;
}

/// How many affirmations a look received in all. A private signal: show it
/// only to the look's owner, never on public surfaces (BNG SRS 001, AFF-003;
/// October 2026 review, H-4).
int privateReceivedTotal(List<AffirmationFacet> facets) =>
    facets.fold(0, (total, facet) => total + facet.senderCount);

/// Collapses affirmations into distinct expressions, preserving the order in
/// which each expression was first received.
List<AffirmationFacet> affirmationFacetsOf(List<Affirmation> affirmations) {
  final ordered = [...affirmations]
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  final counts = <String, int>{};
  final seen = <String, Affirmation>{};
  for (final affirmation in ordered) {
    final key = affirmation.definitionId;
    if (key.isEmpty) continue;
    counts[key] = (counts[key] ?? 0) + 1;
    seen.putIfAbsent(key, () => affirmation);
  }

  return seen.entries
      .map(
        (entry) => AffirmationFacet(
          definitionId: entry.key,
          emoji: entry.value.emoji,
          shortLabel: entry.value.shortLabel,
          category: entry.value.category,
          senderCount: counts[entry.key] ?? 0,
        ),
      )
      .toList();
}
