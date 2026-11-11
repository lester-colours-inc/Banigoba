// The guided first five minutes (review item O-1): a new person adds a photo,
// picks their style, adds a few pieces from their wardrobe and then sees a
// makeover, so the app shows its value straight away. Every step is optional
// and can be skipped; this keeps track of how far they got.
import 'package:flutter/foundation.dart';

import 'package:banigoba/modules/social/models/affirmation_library.dart';
import 'package:banigoba/modules/social/models/affirmation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'first_run_guide.freezed.dart';

/// The steps, in the order they are offered.
enum GuideStep {
  photo('Add your photo', 'A photo of you, so the makeover starts from you.'),
  style('Pick your style', 'Tell us the looks you love. Takes ten seconds.'),
  wardrobe(
    'Add pieces you own',
    'Photograph a few of your clothes. We fill in the details.',
  ),
  makeover('See your first makeover', 'Try a new look on your own photo.');

  const GuideStep(this.title, this.subtitle);

  final String title;
  final String subtitle;
}

/// How many wardrobe pieces the guide asks for.
const int kGuideWardrobeGoal = 3;

@freezed
abstract class GuideProgress with _$GuideProgress {
  const GuideProgress._();

  const factory GuideProgress({
    @Default(false) bool photoDone,
    @Default(false) bool styleDone,
    @Default(0) int wardrobeCount,
    @Default(false) bool makeoverTried,
  }) = _GuideProgress;

  bool isDone(GuideStep step) => switch (step) {
    GuideStep.photo => photoDone,
    GuideStep.style => styleDone,
    GuideStep.wardrobe => wardrobeCount >= kGuideWardrobeGoal,
    GuideStep.makeover => makeoverTried,
  };

  /// The first step not finished yet, or null when all are.
  GuideStep? get next {
    for (final step in GuideStep.values) {
      if (!isDone(step)) return step;
    }
    return null;
  }

  /// A step's progress label, e.g. "2 of 3" for the wardrobe, else null.
  String? progressLabel(GuideStep step) =>
      step == GuideStep.wardrobe && wardrobeCount > 0 && !isDone(step)
      ? '$wardrobeCount of $kGuideWardrobeGoal'
      : null;

  /// How many of the steps are done.
  int get doneCount => GuideStep.values.where(isDone).length;

  bool get isComplete => next == null;
}

/// A kind word to end the guide with, from the universal affirmations: always
/// the same one for the same person, never a score.
AffirmationDefinition welcomeAffirmation(String userId) {
  final options = kUniversalAffirmations;
  final seed = userId.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  return options[seed % options.length];
}
