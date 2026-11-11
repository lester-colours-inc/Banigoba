// The affirmation library.
//
// Universal affirmations ship as code constants: they carry no heritage
// meaning, need no provenance, and must keep working offline and in every
// market. They are exactly the examples enumerated in BNG SRS 001 — nothing
// here is invented praise language.
//
// Cultural affirmations (praise names, proverbs, blessings, praise poetry,
// songs, local slang) are deliberately NOT defined here. They are
// curator-managed records in the `affirmation_library` table,
// each requiring language, meaning, provenance, contributor rights and review
// before it may be served. That collection starts empty; until a curator
// fills it, users see the universal set only. See AffirmationService.
import 'package:banigoba/modules/social/models/affirmation.dart';

/// Universal affirmations available in every market without curator review.
const List<AffirmationDefinition> kUniversalAffirmations = [
  // ── Beauty and presence ────────────────────────────────────────────────
  // Spec note: intensity restraint. These describe presence, not a ranking.
  AffirmationDefinition(
    id: 'universal.beautiful',
    text: 'Beautiful',
    shortLabel: 'Beautiful',
    category: AffirmationCategory.beautyAndPresence,
    emoji: '✨',
    reviewState: AffirmationReviewState.approved,
  ),
  AffirmationDefinition(
    id: 'universal.radiant',
    text: 'Radiant',
    shortLabel: 'Radiant',
    category: AffirmationCategory.beautyAndPresence,
    emoji: '🌟',
    reviewState: AffirmationReviewState.approved,
  ),
  AffirmationDefinition(
    id: 'universal.elegant',
    text: 'Elegant',
    shortLabel: 'Elegant',
    category: AffirmationCategory.beautyAndPresence,
    emoji: '🕊️',
    reviewState: AffirmationReviewState.approved,
  ),
  AffirmationDefinition(
    id: 'universal.stunning',
    text: 'Stunning',
    shortLabel: 'Stunning',
    category: AffirmationCategory.beautyAndPresence,
    emoji: '💫',
    reviewState: AffirmationReviewState.approved,
  ),
  AffirmationDefinition(
    id: 'universal.graceful',
    text: 'Graceful',
    shortLabel: 'Graceful',
    category: AffirmationCategory.beautyAndPresence,
    emoji: '🪶',
    reviewState: AffirmationReviewState.approved,
  ),

  // ── Character and bearing ──────────────────────────────────────────────
  // Spec note: avoid unsupported claims and coercive or sexualised use.
  AffirmationDefinition(
    id: 'universal.strong',
    text: 'Strong',
    shortLabel: 'Strong',
    category: AffirmationCategory.characterAndBearing,
    emoji: '🛡️',
    reviewState: AffirmationReviewState.approved,
  ),
  AffirmationDefinition(
    id: 'universal.confident',
    text: 'Confident',
    shortLabel: 'Confident',
    category: AffirmationCategory.characterAndBearing,
    emoji: '🔥',
    reviewState: AffirmationReviewState.approved,
  ),
  AffirmationDefinition(
    id: 'universal.dignified',
    text: 'Dignified',
    shortLabel: 'Dignified',
    category: AffirmationCategory.characterAndBearing,
    emoji: '🏛️',
    reviewState: AffirmationReviewState.approved,
  ),
  AffirmationDefinition(
    id: 'universal.powerful',
    text: 'Powerful',
    shortLabel: 'Powerful',
    category: AffirmationCategory.characterAndBearing,
    emoji: '⚡',
    reviewState: AffirmationReviewState.approved,
  ),
  AffirmationDefinition(
    id: 'universal.regal',
    text: 'Regal',
    shortLabel: 'Regal',
    category: AffirmationCategory.characterAndBearing,
    emoji: '👑',
    reviewState: AffirmationReviewState.approved,
  ),

  // ── Style and originality ──────────────────────────────────────────────
  // Spec note: link to the look or element being affirmed.
  AffirmationDefinition(
    id: 'universal.sharp',
    text: 'Sharp',
    shortLabel: 'Sharp',
    category: AffirmationCategory.styleAndOriginality,
    emoji: '🔷',
    reviewState: AffirmationReviewState.approved,
  ),
  AffirmationDefinition(
    id: 'universal.classy',
    text: 'Classy',
    shortLabel: 'Classy',
    category: AffirmationCategory.styleAndOriginality,
    emoji: '🥂',
    reviewState: AffirmationReviewState.approved,
  ),
  AffirmationDefinition(
    id: 'universal.creative',
    text: 'Creative',
    shortLabel: 'Creative',
    category: AffirmationCategory.styleAndOriginality,
    emoji: '🎨',
    reviewState: AffirmationReviewState.approved,
  ),
  AffirmationDefinition(
    id: 'universal.original',
    text: 'Original',
    shortLabel: 'Original',
    category: AffirmationCategory.styleAndOriginality,
    emoji: '🧩',
    reviewState: AffirmationReviewState.approved,
  ),
  AffirmationDefinition(
    id: 'universal.timeless',
    text: 'Timeless',
    shortLabel: 'Timeless',
    category: AffirmationCategory.styleAndOriginality,
    emoji: '⏳',
    reviewState: AffirmationReviewState.approved,
  ),
];

/// Definition used when converting legacy like records, and as the fallback
/// when a stored affirmation references a library entry that has since been
/// retired.
const AffirmationDefinition kFallbackAffirmation = AffirmationDefinition(
  id: 'universal.beautiful',
  text: 'Beautiful',
  shortLabel: 'Beautiful',
  category: AffirmationCategory.beautyAndPresence,
  emoji: '✨',
  reviewState: AffirmationReviewState.approved,
);

/// Looks up a universal entry by id.
AffirmationDefinition? universalAffirmationById(String id) {
  for (final definition in kUniversalAffirmations) {
    if (definition.id == id) return definition;
  }
  return null;
}

/// Universal entries grouped by category, preserving declaration order.
Map<AffirmationCategory, List<AffirmationDefinition>>
groupAffirmationsByCategory(List<AffirmationDefinition> definitions) {
  final grouped = <AffirmationCategory, List<AffirmationDefinition>>{};
  for (final definition in definitions) {
    grouped.putIfAbsent(definition.category, () => []).add(definition);
  }
  return grouped;
}
