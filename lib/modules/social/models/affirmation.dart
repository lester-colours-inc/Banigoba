// Affirmation domain objects.
//
// Banigoba's social currency is a structured qualitative response, not a
// generic like. Two objects are involved:
//
//   * [AffirmationDefinition] — a library entry describing an expression that
//     may be sent. Universal entries ship as code constants; cultural entries
//     are curator-managed records loaded from the database.
//   * [Affirmation] — one interaction: this person affirmed that look.
//
// Field groups follow the Affirmation Object Contract in BNG SRS 001
// (identity, language, cultural context, usage context, media, governance,
// interaction). Fields the lean MVP does not populate are still modelled so
// curator tooling can fill them without a schema change.
import 'package:banigoba/core/supabase/rows.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'affirmation.freezed.dart';

/// Spec categories for affirmation expressions.
enum AffirmationCategory {
  beautyAndPresence('beauty_and_presence', 'Beauty and presence'),
  characterAndBearing('character_and_bearing', 'Character and bearing'),
  styleAndOriginality('style_and_originality', 'Style and originality'),
  culturalAffirmation('cultural_affirmation', 'Cultural affirmation'),
  performanceAndSound('performance_and_sound', 'Performance and sound'),
  contemporaryExpression('contemporary_expression', 'Contemporary expression');

  const AffirmationCategory(this.id, this.label);

  final String id;
  final String label;

  /// True when entries in this category carry heritage meaning and therefore
  /// require provenance, contributor rights and curator review before use.
  bool get requiresCuratorReview => switch (this) {
    AffirmationCategory.culturalAffirmation ||
    AffirmationCategory.performanceAndSound ||
    AffirmationCategory.contemporaryExpression => true,
    AffirmationCategory.beautyAndPresence ||
    AffirmationCategory.characterAndBearing ||
    AffirmationCategory.styleAndOriginality => false,
  };

  static AffirmationCategory? fromId(String? id) {
    for (final category in AffirmationCategory.values) {
      if (category.id == id) return category;
    }
    return null;
  }
}

/// Governance lifecycle. Only [approved] entries may be served to users.
enum AffirmationReviewState {
  draft('draft'),
  inReview('in_review'),
  approved('approved'),
  retired('retired');

  const AffirmationReviewState(this.id);

  final String id;

  bool get isServable => this == AffirmationReviewState.approved;

  static AffirmationReviewState fromId(String? id) {
    for (final state in AffirmationReviewState.values) {
      if (state.id == id) return state;
    }
    return AffirmationReviewState.draft;
  }
}

/// What an affirmation was sent about.
enum AffirmationTargetType {
  post('post'),
  hairLook('hair_look'),
  makeover('makeover');

  const AffirmationTargetType(this.id);

  final String id;

  static AffirmationTargetType? fromId(String? id) {
    for (final type in AffirmationTargetType.values) {
      if (type.id == id) return type;
    }
    return null;
  }
}

/// Provenance for a cultural expression.
///
/// Empty for universal entries. Required before a cultural entry may reach
/// [AffirmationReviewState.approved].
@freezed
abstract class AffirmationProvenance with _$AffirmationProvenance {
  const AffirmationProvenance._();

  const factory AffirmationProvenance({
    @Default('') String historicalSource,
    @Default('') String contributor,
    @Default('') String contributorRights,
    @Default('') String curator,
    DateTime? reviewedAt,
  }) = _AffirmationProvenance;

  bool get isEmpty =>
      historicalSource.isEmpty &&
      contributor.isEmpty &&
      contributorRights.isEmpty &&
      curator.isEmpty;

  factory AffirmationProvenance.fromMap(Map<String, dynamic> data) {
    final reviewedAt = data['reviewedAt'];
    return AffirmationProvenance(
      historicalSource: (data['historicalSource'] ?? '').toString(),
      contributor: (data['contributor'] ?? '').toString(),
      contributorRights: (data['contributorRights'] ?? '').toString(),
      curator: (data['curator'] ?? '').toString(),
      reviewedAt: asDateTime(reviewedAt),
    );
  }

  Map<String, dynamic> toMap() => {
    'historicalSource': historicalSource,
    'contributor': contributor,
    'contributorRights': contributorRights,
    'curator': curator,
    if (reviewedAt != null) 'reviewedAt': reviewedAt!.toIso8601String(),
  };
}

/// A library entry describing an expression a user may send.
@freezed
abstract class AffirmationDefinition with _$AffirmationDefinition {
  const AffirmationDefinition._();

  const factory AffirmationDefinition({
    // Identity and content.
    required String id,
    required String text,

    /// Accessible text label. Required so custom emoji are never the only
    /// carrier of meaning (NFR-006, and the localisation rules in BNG SRS 001).
    required String shortLabel,
    required AffirmationCategory category,
    required String emoji,

    // Language.
    @Default('en') String language,
    @Default('') String translation,
    @Default('') String transliteration,
    @Default('') String pronunciation,
    @Default('') String meaning,

    // Cultural context.
    @Default('') String country,
    @Default('') String region,
    @Default('') String culture,
    @Default('') String communityScope,

    // Usage context.
    @Default('') String occasion,
    @Default('') String formality,

    // Media.
    @Default('') String audioUrl,
    @Default('') String audioTranscript,
    @Default('') String performer,

    // Governance.
    @Default(AffirmationReviewState.draft) AffirmationReviewState reviewState,
    @Default(AffirmationProvenance()) AffirmationProvenance provenance,
    @Default(1) int version,
    @Default([]) List<String> safetyLabels,
    @Default('') String retirementReason,
  }) = _AffirmationDefinition;

  /// True when this entry may be shown to users.
  ///
  /// Cultural entries additionally require provenance, so an approved record
  /// with an empty provenance block is still withheld.
  bool get isServable {
    if (!reviewState.isServable) return false;
    if (category.requiresCuratorReview && provenance.isEmpty) return false;
    return true;
  }

  /// Whether meaning needs to be surfaced alongside the text. The spec
  /// requires this wherever context is not self-evident.
  bool get needsContextDisclosure =>
      category.requiresCuratorReview &&
      (meaning.isNotEmpty || translation.isNotEmpty);

  /// Builds an entry from an `affirmation_library` row.
  factory AffirmationDefinition.fromRow(Map<String, dynamic> row) {
    final data = row['data'];
    return AffirmationDefinition.fromMap(
      data is Map ? Map<String, dynamic>.from(data) : const {},
      id: (row['id'] ?? '').toString(),
    );
  }

  factory AffirmationDefinition.fromMap(
    Map<String, dynamic> data, {
    required String id,
  }) {
    final rawSafety = data['safetyLabels'];
    final rawProvenance = data['provenance'];
    return AffirmationDefinition(
      id: id,
      text: (data['text'] ?? '').toString(),
      shortLabel: (data['shortLabel'] ?? data['text'] ?? '').toString(),
      category:
          AffirmationCategory.fromId(data['category']?.toString()) ??
          AffirmationCategory.beautyAndPresence,
      emoji: (data['emoji'] ?? '').toString(),
      language: (data['language'] ?? 'en').toString(),
      translation: (data['translation'] ?? '').toString(),
      transliteration: (data['transliteration'] ?? '').toString(),
      pronunciation: (data['pronunciation'] ?? '').toString(),
      meaning: (data['meaning'] ?? '').toString(),
      country: (data['country'] ?? '').toString(),
      region: (data['region'] ?? '').toString(),
      culture: (data['culture'] ?? '').toString(),
      communityScope: (data['communityScope'] ?? '').toString(),
      occasion: (data['occasion'] ?? '').toString(),
      formality: (data['formality'] ?? '').toString(),
      audioUrl: (data['audioUrl'] ?? '').toString(),
      audioTranscript: (data['audioTranscript'] ?? '').toString(),
      performer: (data['performer'] ?? '').toString(),
      reviewState: AffirmationReviewState.fromId(
        data['reviewState']?.toString(),
      ),
      provenance: rawProvenance is Map
          ? AffirmationProvenance.fromMap(
              Map<String, dynamic>.from(rawProvenance),
            )
          : const AffirmationProvenance(),
      version: data['version'] is num ? (data['version'] as num).toInt() : 1,
      safetyLabels: rawSafety is Iterable
          ? rawSafety.map((value) => value.toString()).toList()
          : const [],
      retirementReason: (data['retirementReason'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'text': text,
    'shortLabel': shortLabel,
    'category': category.id,
    'emoji': emoji,
    'language': language,
    'translation': translation,
    'transliteration': transliteration,
    'pronunciation': pronunciation,
    'meaning': meaning,
    'country': country,
    'region': region,
    'culture': culture,
    'communityScope': communityScope,
    'occasion': occasion,
    'formality': formality,
    'audioUrl': audioUrl,
    'audioTranscript': audioTranscript,
    'performer': performer,
    'reviewState': reviewState.id,
    'provenance': provenance.toMap(),
    'version': version,
    'safetyLabels': safetyLabels,
    'retirementReason': retirementReason,
  };
}

/// One affirmation interaction.
@freezed
abstract class Affirmation with _$Affirmation {
  const Affirmation._();

  const factory Affirmation({
    required String id,
    required String senderId,
    required String senderName,
    required AffirmationTargetType targetType,
    required String targetId,
    required String targetOwnerId,

    /// Library entry this affirmation was sent from.
    required String definitionId,

    // Denormalised display fields, so rendering a feed needs no library lookup
    // and history stays readable after a library entry is revised or retired.
    required String emoji,
    required String shortLabel,
    required String text,
    required AffirmationCategory category,
    required DateTime createdAt,
    @Default('en') String language,
    @Default('') String meaning,

    /// Optional user-authored supportive text. Moderated for harassment,
    /// sexualisation, manipulation and spam.
    @Default('') String personalMessage,
    @Default('clear') String moderationState,

    /// Set on records produced by the like-to-affirmation backfill, so the
    /// migration can be identified and reversed.
    @Default(false) bool migratedFromLike,
  }) = _Affirmation;

  bool get isVisible => moderationState != 'removed';

  /// Builds an affirmation from an `affirmations` row (snake_case columns).
  factory Affirmation.fromRow(Map<String, dynamic> row) {
    final data = camelizeRow(row);
    return Affirmation(
      id: (data['id'] ?? '').toString(),
      senderId: (data['senderId'] ?? '').toString(),
      senderName: (data['senderName'] ?? '').toString(),
      targetType:
          AffirmationTargetType.fromId(data['targetType']?.toString()) ??
          AffirmationTargetType.post,
      targetId: (data['targetId'] ?? '').toString(),
      targetOwnerId: (data['targetOwnerId'] ?? '').toString(),
      definitionId: (data['definitionId'] ?? '').toString(),
      emoji: (data['emoji'] ?? '').toString(),
      shortLabel: (data['shortLabel'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      category:
          AffirmationCategory.fromId(data['category']?.toString()) ??
          AffirmationCategory.beautyAndPresence,
      language: (data['language'] ?? 'en').toString(),
      meaning: (data['meaning'] ?? '').toString(),
      personalMessage: (data['personalMessage'] ?? '').toString(),
      moderationState: (data['moderationState'] ?? 'clear').toString(),
      migratedFromLike: data['migratedFromLike'] == true,
      createdAt: asDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }
}
