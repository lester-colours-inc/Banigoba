// Verifies the steps a coordinated makeover asks the server to make.
import 'package:banigoba/data/models/makeover_job.dart';
import 'package:banigoba/data/services/ai_job_service.dart';
import 'package:banigoba/data/services/coordinated_makeover_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _source = 'https://example.test/source.jpg';

MakeoverJob _job(
  MakeoverIntent intent, {
  Map<MakeoverDomain, MakeoverStage> stages = const {},
}) => MakeoverJob(
  id: 'job-1',
  userId: 'user-1',
  sourceImageUrl: _source,
  intent: intent,
  stages: stages,
);

const _shirt = {
  'name': 'Linen shirt',
  'category': 'tops',
  'imageUrl': 'https://example.test/shirt.jpg',
};
const _shoes = {
  'name': 'White sneakers',
  'category': 'shoes',
  'imageUrl': 'https://example.test/shoes.jpg',
};

void main() {
  test('hair then each garment, each building on the last', () {
    final plan = CoordinatedMakeoverService.planSteps(
      _job(
        const MakeoverIntent(hairPrompt: 'braids', garments: [_shoes, _shirt]),
      ),
    );

    expect(plan.failures, isEmpty);
    expect(plan.steps, hasLength(3));
    expect(plan.stageSteps, {
      MakeoverDomain.hair: [0],
      MakeoverDomain.clothing: [1, 2],
    });
    expect(plan.steps[0].images, [const AiImageUrl(_source)]);
    expect(plan.steps[0].prompt, contains('braids'));
    expect(plan.steps[0].count, 1);
    // Base layer (the shirt) before the shoes.
    expect(plan.steps[1].images, [
      const AiStepImage(0),
      const AiImageUrl('https://example.test/shirt.jpg'),
    ]);
    expect(plan.steps[2].images.first, const AiStepImage(1));
    // Only the final step makes alternatives.
    expect(plan.steps[1].count, 1);
    expect(plan.steps[2].count, CoordinatedMakeoverService.alternativesPerJob);
  });

  test('refining clothing reuses the hair already made', () {
    final plan = CoordinatedMakeoverService.planSteps(
      _job(
        const MakeoverIntent(hairPrompt: 'braids', garments: [_shirt]),
        stages: const {
          MakeoverDomain.hair: MakeoverStage(
            domain: MakeoverDomain.hair,
            status: MakeoverStageStatus.succeeded,
            outputImageUrls: ['https://example.test/hair.jpg'],
          ),
        },
      ),
    );

    expect(plan.stageSteps.keys, [MakeoverDomain.clothing]);
    expect(
      plan.steps.single.images.first,
      const AiImageUrl('https://example.test/hair.jpg'),
    );
  });

  test('garments without pictures fail clothing but hair still runs', () {
    final plan = CoordinatedMakeoverService.planSteps(
      _job(
        const MakeoverIntent(
          hairPrompt: 'braids',
          garments: [
            {'name': 'Mystery', 'category': 'tops'},
          ],
        ),
      ),
    );

    expect(plan.stageSteps.keys, [MakeoverDomain.hair]);
    expect(plan.failures.keys, [MakeoverDomain.clothing]);
  });

  test('nothing requested means nothing to make', () {
    final plan = CoordinatedMakeoverService.planSteps(
      _job(const MakeoverIntent()),
    );
    expect(plan.steps, isEmpty);
  });
}
