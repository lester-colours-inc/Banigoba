// Guards the "one journey, separable engines" contract: a skipped domain is
// not a failure, a failed domain does not erase a successful one, and the
// pipeline never silently substitutes a degraded result.
import 'package:banigoba/modules/makeover/models/makeover_job.dart';
import 'package:banigoba/modules/makeover/services/coordinated_makeover_service.dart';
import 'package:flutter_test/flutter_test.dart';

MakeoverJob _job({
  required MakeoverIntent intent,
  required Map<MakeoverDomain, MakeoverStage> stages,
  List<MakeoverAlternative> alternatives = const [],
}) {
  return MakeoverJob(
    id: 'job-1',
    userId: 'user-1',
    sourceImageUrl: 'https://example.test/source.jpg',
    intent: intent,
    stages: stages,
    alternatives: alternatives,
  );
}

MakeoverStage _stage(
  MakeoverDomain domain,
  MakeoverStageStatus status, {
  List<String> outputs = const [],
}) {
  return MakeoverStage(
    domain: domain,
    status: status,
    outputImageUrls: outputs,
  );
}

const _garment = {
  'id': 'p1',
  'name': 'Linen shirt',
  'category': 'tops',
  'imageUrl': 'https://example.test/shirt.jpg',
};

void main() {
  group('MakeoverIntent', () {
    test('an empty brief requests nothing', () {
      const intent = MakeoverIntent();
      expect(intent.isEmpty, isTrue);
      expect(intent.requestedDomains, isEmpty);
    });

    test('a hair goal alone requests hair only', () {
      const intent = MakeoverIntent(hairPrompt: 'short fade');
      expect(intent.wantsHair, isTrue);
      expect(intent.wantsClothing, isFalse);
      expect(intent.requestedDomains, [MakeoverDomain.hair]);
    });

    test('garments alone request clothing only', () {
      const intent = MakeoverIntent(garments: [_garment]);
      expect(intent.wantsClothing, isTrue);
      expect(intent.wantsHair, isFalse);
      expect(intent.requestedDomains, [MakeoverDomain.clothing]);
    });

    test('both together request hair first, then clothing', () {
      const intent = MakeoverIntent(hairPrompt: 'braids', garments: [_garment]);

      expect(intent.requestedDomains, [
        MakeoverDomain.hair,
        MakeoverDomain.clothing,
      ]);
    });

    test('whitespace is not a hair request', () {
      const intent = MakeoverIntent(hairPrompt: '   ');
      expect(intent.wantsHair, isFalse);
      expect(intent.isEmpty, isTrue);
    });

    test('survives a round trip through a map', () {
      const intent = MakeoverIntent(
        occasion: 'Wedding',
        desiredFeeling: 'celebratory',
        hairPrompt: 'braids',
        garments: [_garment],
        modestyPreference: 'covered shoulders',
        exclusions: ['leather', 'neon'],
      );

      final restored = MakeoverIntent.fromMap(intent.toMap());

      expect(restored.occasion, 'Wedding');
      expect(restored.desiredFeeling, 'celebratory');
      expect(restored.hairPrompt, 'braids');
      expect(restored.garments.single['name'], 'Linen shirt');
      expect(restored.modestyPreference, 'covered shoulders');
      expect(restored.exclusions, ['leather', 'neon']);
      expect(restored.requestedDomains, intent.requestedDomains);
    });
  });

  group('MakeoverJob state', () {
    test('a skipped domain is not counted as a failure', () {
      final job = _job(
        intent: const MakeoverIntent(hairPrompt: 'braids'),
        stages: {
          MakeoverDomain.hair: _stage(
            MakeoverDomain.hair,
            MakeoverStageStatus.succeeded,
            outputs: const ['https://example.test/hair.png'],
          ),
          MakeoverDomain.clothing: _stage(
            MakeoverDomain.clothing,
            MakeoverStageStatus.skipped,
          ),
        },
      );

      expect(job.hasFailure, isFalse);
      expect(job.isComplete, isTrue);
      expect(job.isPartial, isFalse);
      expect(job.activeStages, hasLength(1));
    });

    test('is incomplete while a stage is still running', () {
      final job = _job(
        intent: const MakeoverIntent(
          hairPrompt: 'braids',
          garments: [_garment],
        ),
        stages: {
          MakeoverDomain.hair: _stage(
            MakeoverDomain.hair,
            MakeoverStageStatus.succeeded,
            outputs: const ['https://example.test/hair.png'],
          ),
          MakeoverDomain.clothing: _stage(
            MakeoverDomain.clothing,
            MakeoverStageStatus.running,
          ),
        },
      );

      expect(job.isRunning, isTrue);
      expect(job.isComplete, isFalse);
    });

    test('reports a partial result when one domain fails and one succeeds', () {
      final job = _job(
        intent: const MakeoverIntent(
          hairPrompt: 'braids',
          garments: [_garment],
        ),
        stages: {
          MakeoverDomain.hair: _stage(
            MakeoverDomain.hair,
            MakeoverStageStatus.succeeded,
            outputs: const ['https://example.test/hair.png'],
          ),
          MakeoverDomain.clothing: _stage(
            MakeoverDomain.clothing,
            MakeoverStageStatus.failed,
          ),
        },
      );

      expect(job.hasFailure, isTrue);
      expect(job.isPartial, isTrue);
      expect(job.isComplete, isFalse);
    });

    test('a total failure is not a partial result', () {
      final job = _job(
        intent: const MakeoverIntent(hairPrompt: 'braids'),
        stages: {
          MakeoverDomain.hair: _stage(
            MakeoverDomain.hair,
            MakeoverStageStatus.failed,
          ),
          MakeoverDomain.clothing: _stage(
            MakeoverDomain.clothing,
            MakeoverStageStatus.skipped,
          ),
        },
      );

      expect(job.hasFailure, isTrue);
      expect(job.isPartial, isFalse);
      expect(job.isComplete, isFalse);
    });

    test('an unknown domain resolves to a skipped stage', () {
      final job = _job(
        intent: const MakeoverIntent(hairPrompt: 'braids'),
        stages: const {},
      );

      expect(
        job.stageFor(MakeoverDomain.clothing).status,
        MakeoverStageStatus.skipped,
      );
      expect(job.stageFor(MakeoverDomain.clothing).isRequested, isFalse);
    });

    test('alternatives are labelled A, B, C', () {
      expect(
        const MakeoverAlternative(index: 0, imageUrl: 'a').label,
        'Look A',
      );
      expect(
        const MakeoverAlternative(index: 1, imageUrl: 'b').label,
        'Look B',
      );
      expect(
        const MakeoverAlternative(index: 2, imageUrl: 'c').label,
        'Look C',
      );
    });
  });

  group('MakeoverStage', () {
    test('copyWith preserves the domain', () {
      final stage = _stage(
        MakeoverDomain.hair,
        MakeoverStageStatus.queued,
      ).copyWith(status: MakeoverStageStatus.running);

      expect(stage.domain, MakeoverDomain.hair);
      expect(stage.status, MakeoverStageStatus.running);
    });

    test('primaryOutput is empty rather than throwing when there is none', () {
      expect(
        _stage(MakeoverDomain.hair, MakeoverStageStatus.queued).primaryOutput,
        isEmpty,
      );
    });

    test('survives a round trip through a map', () {
      final stage = _stage(
        MakeoverDomain.clothing,
        MakeoverStageStatus.succeeded,
        outputs: const ['https://example.test/a.png'],
      );

      final restored = MakeoverStage.fromMap(
        stage.toMap(),
        domain: MakeoverDomain.clothing,
      );

      expect(restored.status, MakeoverStageStatus.succeeded);
      expect(restored.outputImageUrls, ['https://example.test/a.png']);
    });
  });

  group('garment prompt', () {
    test('names the item and keeps the rest of the look unchanged', () {
      final prompt = CoordinatedMakeoverService.buildGarmentPrompt({
        'name': 'Navy blazer',
      });

      expect(prompt, contains('Navy blazer'));
      expect(prompt, contains('every other piece of clothing unchanged'));
    });

    test('still reads without an item name', () {
      final prompt = CoordinatedMakeoverService.buildGarmentPrompt({});

      expect(prompt, contains('the item'));
    });
  });

  group('hair prompt', () {
    test('carries the user instruction', () {
      final prompt = CoordinatedMakeoverService.buildHairPrompt(
        const MakeoverIntent(hairPrompt: 'shoulder-length braids'),
      );

      expect(prompt, contains('shoulder-length braids'));
    });

    test('always forbids changes to identity', () {
      final prompt = CoordinatedMakeoverService.buildHairPrompt(
        const MakeoverIntent(hairPrompt: 'fade'),
      );

      expect(prompt.toLowerCase(), contains('preserve the face'));
      expect(prompt.toLowerCase(), contains('skin tone'));
      expect(prompt.toLowerCase(), contains('body shape'));
    });

    test('scopes the edit to hair so clothing is left alone', () {
      final prompt = CoordinatedMakeoverService.buildHairPrompt(
        const MakeoverIntent(hairPrompt: 'fade'),
      );

      expect(prompt, contains('Change only the hair'));
      expect(prompt, contains('Do not alter clothing'));
    });

    test('includes stated constraints and exclusions', () {
      final prompt = CoordinatedMakeoverService.buildHairPrompt(
        const MakeoverIntent(
          hairPrompt: 'braids',
          occasion: 'a wedding',
          modestyPreference: 'head covered',
          exclusions: ['bleach', 'extensions'],
        ),
      );

      expect(prompt, contains('a wedding'));
      expect(prompt, contains('head covered'));
      expect(prompt, contains('bleach, extensions'));
    });
  });

  test('at least two alternatives are requested (AI-003)', () {
    expect(
      CoordinatedMakeoverService.alternativesPerJob,
      greaterThanOrEqualTo(2),
    );
  });
}
