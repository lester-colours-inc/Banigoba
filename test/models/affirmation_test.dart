// Guards the rules that keep affirmations from becoming a popularity score,
// and the governance gate on cultural content.
import 'package:banigoba/modules/social/models/affirmation_library.dart';
import 'package:banigoba/modules/social/models/affirmation.dart';
import 'package:banigoba/modules/social/services/affirmation_service.dart';
import 'package:flutter_test/flutter_test.dart';

Affirmation _affirmation({
  required String id,
  required String definitionId,
  required String senderId,
  String shortLabel = 'Beautiful',
  String emoji = '✨',
  DateTime? createdAt,
}) {
  return Affirmation(
    id: id,
    senderId: senderId,
    senderName: 'Sender',
    targetType: AffirmationTargetType.post,
    targetId: 'post-1',
    targetOwnerId: 'owner-1',
    definitionId: definitionId,
    emoji: emoji,
    shortLabel: shortLabel,
    text: shortLabel,
    category: AffirmationCategory.beautyAndPresence,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );
}

void main() {
  group('universal affirmation library', () {
    test('ships only the three non-cultural categories', () {
      final categories = kUniversalAffirmations
          .map((definition) => definition.category)
          .toSet();

      expect(categories, {
        AffirmationCategory.beautyAndPresence,
        AffirmationCategory.characterAndBearing,
        AffirmationCategory.styleAndOriginality,
      });
    });

    test('contains no entry that requires curator review', () {
      for (final definition in kUniversalAffirmations) {
        expect(
          definition.category.requiresCuratorReview,
          isFalse,
          reason: '${definition.id} needs curator review but ships in code',
        );
      }
    });

    test('every universal entry is servable', () {
      for (final definition in kUniversalAffirmations) {
        expect(definition.isServable, isTrue, reason: definition.id);
      }
    });

    test('every entry has an accessible label alongside its emoji', () {
      for (final definition in kUniversalAffirmations) {
        expect(definition.shortLabel, isNotEmpty, reason: definition.id);
        expect(definition.emoji, isNotEmpty, reason: definition.id);
      }
    });

    test('ids are unique', () {
      final ids = kUniversalAffirmations.map((d) => d.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('lookup resolves known ids and rejects unknown ones', () {
      expect(universalAffirmationById('universal.regal')?.text, 'Regal');
      expect(universalAffirmationById('universal.nope'), isNull);
    });
  });

  group('cultural entry governance', () {
    AffirmationDefinition cultural({
      required AffirmationReviewState reviewState,
      AffirmationProvenance provenance = const AffirmationProvenance(),
    }) {
      return AffirmationDefinition(
        id: 'cultural.example',
        text: 'Example',
        shortLabel: 'Example',
        category: AffirmationCategory.culturalAffirmation,
        emoji: '🪘',
        reviewState: reviewState,
        provenance: provenance,
      );
    }

    test('is withheld while in draft', () {
      expect(
        cultural(reviewState: AffirmationReviewState.draft).isServable,
        isFalse,
      );
    });

    test('is withheld while in review', () {
      expect(
        cultural(reviewState: AffirmationReviewState.inReview).isServable,
        isFalse,
      );
    });

    test('is withheld when approved but provenance is empty', () {
      expect(
        cultural(reviewState: AffirmationReviewState.approved).isServable,
        isFalse,
        reason: 'approval alone must not release heritage content',
      );
    });

    test('is servable once approved with provenance', () {
      final definition = cultural(
        reviewState: AffirmationReviewState.approved,
        provenance: const AffirmationProvenance(
          historicalSource: 'Community elders',
          contributor: 'Named contributor',
          contributorRights: 'Granted for platform use',
          curator: 'curator-1',
        ),
      );

      expect(definition.isServable, isTrue);
    });

    test('is withheld again once retired', () {
      final definition = cultural(
        reviewState: AffirmationReviewState.retired,
        provenance: const AffirmationProvenance(contributor: 'Someone'),
      );

      expect(definition.isServable, isFalse);
    });

    test('unknown review states default to draft, not approved', () {
      expect(
        AffirmationReviewState.fromId('something-else'),
        AffirmationReviewState.draft,
      );
      expect(AffirmationReviewState.fromId(null).isServable, isFalse);
    });
  });

  group('affirmationFacetsOf', () {
    test('collapses repeats of the same expression into one facet', () {
      final facets = affirmationFacetsOf([
        _affirmation(
          id: 'a',
          definitionId: 'universal.regal',
          senderId: 'u1',
          shortLabel: 'Regal',
        ),
        _affirmation(
          id: 'b',
          definitionId: 'universal.regal',
          senderId: 'u2',
          shortLabel: 'Regal',
        ),
      ]);

      expect(facets, hasLength(1));
      expect(facets.single.shortLabel, 'Regal');
      expect(facets.single.senderCount, 2);
    });

    test('orders facets by when each expression was first received', () {
      final facets = affirmationFacetsOf([
        _affirmation(
          id: 'late',
          definitionId: 'universal.sharp',
          senderId: 'u2',
          shortLabel: 'Sharp',
          createdAt: DateTime(2026, 3, 1),
        ),
        _affirmation(
          id: 'early',
          definitionId: 'universal.regal',
          senderId: 'u1',
          shortLabel: 'Regal',
          createdAt: DateTime(2026, 1, 1),
        ),
      ]);

      expect(facets.map((f) => f.shortLabel), ['Regal', 'Sharp']);
    });

    test('ignores records with no definition', () {
      final facets = affirmationFacetsOf([
        _affirmation(id: 'a', definitionId: '', senderId: 'u1'),
      ]);

      expect(facets, isEmpty);
    });

    test('returns nothing for no affirmations', () {
      expect(affirmationFacetsOf(const []), isEmpty);
    });
  });

  group('AffirmationService.documentIdFor', () {
    test('is deterministic, so re-sending is idempotent', () {
      String id() => AffirmationService.documentIdFor(
        targetType: AffirmationTargetType.post,
        targetId: 'post-1',
        senderId: 'user-1',
        definitionId: 'universal.regal',
      );

      expect(id(), id());
    });

    test('separates senders, targets, types and expressions', () {
      final base = AffirmationService.documentIdFor(
        targetType: AffirmationTargetType.post,
        targetId: 'post-1',
        senderId: 'user-1',
        definitionId: 'universal.regal',
      );

      expect(
        base,
        isNot(
          AffirmationService.documentIdFor(
            targetType: AffirmationTargetType.post,
            targetId: 'post-1',
            senderId: 'user-2',
            definitionId: 'universal.regal',
          ),
        ),
      );
      expect(
        base,
        isNot(
          AffirmationService.documentIdFor(
            targetType: AffirmationTargetType.hairLook,
            targetId: 'post-1',
            senderId: 'user-1',
            definitionId: 'universal.regal',
          ),
        ),
      );
      expect(
        base,
        isNot(
          AffirmationService.documentIdFor(
            targetType: AffirmationTargetType.post,
            targetId: 'post-1',
            senderId: 'user-1',
            definitionId: 'universal.sharp',
          ),
        ),
      );
    });

    test('never produces a path separator', () {
      final id = AffirmationService.documentIdFor(
        targetType: AffirmationTargetType.post,
        targetId: 'post-1',
        senderId: 'user-1',
        definitionId: 'cultural/with/slashes',
      );

      expect(id.contains('/'), isFalse);
    });
  });

  group('cultural context disclosure', () {
    test('is required when a cultural entry carries meaning', () {
      const definition = AffirmationDefinition(
        id: 'cultural.example',
        text: 'Example',
        shortLabel: 'Example',
        category: AffirmationCategory.culturalAffirmation,
        emoji: '🪘',
        meaning: 'A blessing offered to a respected person',
      );

      expect(definition.needsContextDisclosure, isTrue);
    });

    test('is not required for plain universal words', () {
      expect(
        universalAffirmationById('universal.elegant')?.needsContextDisclosure,
        isFalse,
      );
    });
  });
}
