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
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/app_auth.dart';
import '../../core/supabase/supabase_config.dart';

import '../affirmations/affirmation_library.dart';
import '../models/affirmation.dart';
import 'notification_service.dart';

class AffirmationService {
  AffirmationService({NotificationService? notifications})
    : _notifications = notifications ?? NotificationService();

  final NotificationService _notifications;

  String get _currentUserId => AppAuth.instance.currentUser?.uid ?? '';

  SupabaseQueryBuilder get _affirmations => supabase.from('affirmations');

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
      final rows = await supabase
          .from('affirmation_library')
          .select()
          .eq('review_state', AffirmationReviewState.approved.id);

      return rows
          .map(AffirmationDefinition.fromRow)
          .where((definition) => definition.isServable)
          .toList();
    } on PostgrestException catch (error) {
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

    // Same id for the same affirmation, so sending twice changes nothing.
    await _affirmations.upsert({
      'id': docId,
      'sender_id': senderId,
      'sender_name': senderName,
      'target_type': targetType.id,
      'target_id': targetId,
      'target_owner_id': targetOwnerId,
      'definition_id': definition.id,
      'emoji': definition.emoji,
      'short_label': definition.shortLabel,
      'text': definition.text,
      'category': definition.category.id,
      'language': definition.language,
      'meaning': definition.meaning,
      'personal_message': personalMessage.trim(),
    }, ignoreDuplicates: true);

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

    await _affirmations.delete().eq(
      'id',
      documentIdFor(
        targetType: targetType,
        targetId: targetId,
        senderId: senderId,
        definitionId: definitionId,
      ),
    );
  }

  /// Deletes every affirmation attached to a target. Called when the owner
  /// deletes the look, so affirmations do not outlive what they were about.
  Future<void> deleteAllForTarget({
    required AffirmationTargetType targetType,
    required String targetId,
  }) async {
    await _affirmations
        .delete()
        .eq('target_type', targetType.id)
        .eq('target_id', targetId);
  }

  // ── Reading ─────────────────────────────────────────────────────────────

  /// Affirmations attached to one target, newest first.
  Stream<List<Affirmation>> watchForTarget({
    required AffirmationTargetType targetType,
    required String targetId,
  }) {
    if (targetId.isEmpty) return Stream.value(const []);

    return _affirmations
        .stream(primaryKey: ['id'])
        .eq('target_id', targetId)
        .map(
          (rows) =>
              rows
                  .where((row) => row['target_type'] == targetType.id)
                  .map(Affirmation.fromRow)
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
        .stream(primaryKey: ['id'])
        .eq('target_id', targetId)
        .map(
          (rows) => rows
              .where(
                (row) =>
                    row['target_type'] == targetType.id &&
                    row['sender_id'] == senderId,
              )
              .map((row) => (row['definition_id'] ?? '').toString())
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
        .stream(primaryKey: ['id'])
        .eq('sender_id', senderId)
        .map(
          (rows) => {
            for (final row in rows)
              if (row['target_type'] == AffirmationTargetType.post.id &&
                  (row['target_id'] ?? '').toString().isNotEmpty)
                row['target_id'].toString(),
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
        .stream(primaryKey: ['id'])
        .eq('target_owner_id', ownerId)
        .map(
          (rows) =>
              rows
                  .map(Affirmation.fromRow)
                  .where((affirmation) => affirmation.isVisible)
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  // ── Internals ───────────────────────────────────────────────────────────

  Future<String> _resolveSenderName(String senderId) async {
    final current = AppAuth.instance.currentUser;
    final fallback =
        current?.displayName ?? current?.email?.split('@').first ?? 'Someone';
    try {
      final user = await supabase
          .from('profiles')
          .select('display_name')
          .eq('id', senderId)
          .maybeSingle();
      final displayName = user?['display_name'];
      if (displayName is String && displayName.trim().isNotEmpty) {
        return displayName.trim();
      }
    } on PostgrestException catch (error) {
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
    } on PostgrestException catch (error) {
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
