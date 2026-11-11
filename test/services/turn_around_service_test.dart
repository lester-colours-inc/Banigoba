// Verifies the turn-around prompts and the job that makes the angles.
import 'package:banigoba/modules/makeover/services/ai_job_service.dart';
import 'package:banigoba/modules/makeover/services/turn_around_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_ai_image_jobs.dart';

List<String> _urls(AiImageStep step) => [
  for (final image in step.images)
    if (image case AiImageUrl(:final url)) url,
];

void main() {
  keepingAngles();
  group('turnAroundPrompt', () {
    test('describes each angle and the attached images', () {
      final back = turnAroundPrompt(TurnView.back, garmentCount: 2);
      expect(back, contains('from directly behind'));
      expect(back, contains('The next 2 image(s)'));
      expect(
        turnAroundPrompt(TurnView.right, garmentCount: 0),
        isNot(contains('image(s) are the garments')),
      );
      expect(
        turnAroundPrompt(TurnView.left, garmentCount: 1),
        contains('left side'),
      );
    });

    test('a shop\'s back photo is used for the back instead of guessing', () {
      final prompt = turnAroundPrompt(
        TurnView.back,
        garmentCount: 1,
        backCount: 1,
      );
      expect(prompt, contains('show the BACK of those garments'));
      expect(prompt, contains('use them exactly'));
      expect(
        turnAroundPrompt(TurnView.back, garmentCount: 1),
        isNot(contains('BACK')),
      );
    });

    test('keeps the person and outfit and admits unseen backs are guessed', () {
      final prompt = turnAroundPrompt(TurnView.back, garmentCount: 1);
      expect(prompt, contains('exactly this person'));
      expect(prompt, contains('not visible in the references'));
    });
  });

  group('TurnAroundService.run', () {
    test('asks for right, back and left and keeps the front', () async {
      final jobs = FakeAiImageJobs();
      final seen = <TurnView>[];
      final views = await TurnAroundService(jobs: jobs).run(
        frontUrl: 'https://x/front.png',
        avatarUrl: 'https://x/avatar.png',
        garmentUrls: ['https://x/g1.png', '', 'https://x/g2.png'],
        onView: (view, _) => seen.add(view),
      );

      final request = jobs.requests.single;
      expect(request.kind, AiJobKind.turnAround);
      expect(seen, [TurnView.right, TurnView.back, TurnView.left]);
      expect(views.keys, TurnView.values);
      expect(views[TurnView.front], 'https://x/front.png');
      expect(views[TurnView.back], 'https://x/step-1-0.png');
      expect(request.steps[0].prompt, contains('right side'));
      expect(request.steps[1].prompt, contains('directly behind'));
      expect(request.steps[2].prompt, contains('left side'));
      // The angles do not build on each other, so the server runs them
      // side by side.
      for (final step in request.steps) {
        expect(step.images.whereType<AiStepImage>(), isEmpty);
      }
    });

    test('sends the front, the photo, then up to three garments', () async {
      final jobs = FakeAiImageJobs();
      await TurnAroundService(jobs: jobs).run(
        frontUrl: 'front',
        avatarUrl: 'avatar',
        garmentUrls: ['a', 'b', 'c', 'd', 'e'],
      );
      expect(_urls(jobs.requests.single.steps.first), [
        'front',
        'avatar',
        'a',
        'b',
        'c',
      ]);
    });

    test('sends the shops\' back photos after the garments', () async {
      final jobs = FakeAiImageJobs();
      await TurnAroundService(jobs: jobs).run(
        frontUrl: 'front',
        avatarUrl: 'avatar',
        garmentUrls: ['a'],
        garmentBackUrls: ['', 'a-back'],
      );
      final step = jobs.requests.single.steps.first;
      expect(_urls(step), ['front', 'avatar', 'a', 'a-back']);
      expect(step.prompt, contains('The last 1 image(s) show the BACK'));
    });

    test('keeps the angles already made when a later one fails', () async {
      final seen = <TurnView>[];
      await expectLater(
        TurnAroundService(jobs: FakeAiImageJobs(failOnStep: 1)).run(
          frontUrl: 'front',
          avatarUrl: 'avatar',
          onView: (view, _) => seen.add(view),
        ),
        throwsA(isA<AiJobException>()),
      );
      expect(seen, [TurnView.right]);
    });
  });
}

void keepingAngles() {
  group('keeping the angles with a saved look', () {
    test('only the generated angles are stored, by name', () {
      expect(
        turnViewsToMap({
          TurnView.front: 'front',
          TurnView.right: 'r',
          TurnView.back: 'b',
        }),
        {'right': 'r', 'back': 'b'},
      );
      expect(turnViewsToMap({TurnView.front: 'front'}), isEmpty);
    });

    test('reads them back with the look as the front', () {
      final views = parseTurnViews({
        'right': 'r',
        'back': 'b',
        'left': '',
        'up': 'x',
      }, frontUrl: 'front');
      expect(views, {
        TurnView.front: 'front',
        TurnView.right: 'r',
        TurnView.back: 'b',
      });
    });

    test('a look with nothing stored is just the front', () {
      expect(parseTurnViews(null, frontUrl: 'f'), {TurnView.front: 'f'});
      expect(parseTurnViews('junk', frontUrl: 'f'), {TurnView.front: 'f'});
    });
  });
}
