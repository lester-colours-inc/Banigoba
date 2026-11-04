// Verifies how the guided first five minutes tracks progress (O-1).
import 'package:banigoba/data/models/first_run_guide.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a new person starts at the photo step', () {
    const progress = GuideProgress();

    expect(progress.next, GuideStep.photo);
    expect(progress.doneCount, 0);
    expect(progress.isComplete, isFalse);
  });

  test('the next step is the first one not done, in order', () {
    expect(const GuideProgress(photoDone: true).next, GuideStep.style);
    expect(
      const GuideProgress(photoDone: true, styleDone: true).next,
      GuideStep.wardrobe,
    );
    // Doing a later step first does not hide the earlier one.
    expect(const GuideProgress(styleDone: true).next, GuideStep.photo);
  });

  test('the wardrobe step needs the goal number of pieces', () {
    const some = GuideProgress(wardrobeCount: 2);
    expect(some.isDone(GuideStep.wardrobe), isFalse);
    expect(some.progressLabel(GuideStep.wardrobe), '2 of $kGuideWardrobeGoal');

    const enough = GuideProgress(wardrobeCount: kGuideWardrobeGoal);
    expect(enough.isDone(GuideStep.wardrobe), isTrue);
    expect(enough.progressLabel(GuideStep.wardrobe), isNull);
    expect(const GuideProgress().progressLabel(GuideStep.wardrobe), isNull);
  });

  test('everything done is complete', () {
    const all = GuideProgress(
      photoDone: true,
      styleDone: true,
      wardrobeCount: kGuideWardrobeGoal,
      makeoverTried: true,
    );

    expect(all.isComplete, isTrue);
    expect(all.next, isNull);
    expect(all.doneCount, GuideStep.values.length);
  });

  test('the welcome affirmation is kind and the same for the same person', () {
    final first = welcomeAffirmation('user-1');
    expect(first.text, isNotEmpty);
    expect(welcomeAffirmation('user-1').id, first.id);
  });
}
