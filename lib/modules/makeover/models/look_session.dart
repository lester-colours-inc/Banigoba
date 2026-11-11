// The progress of one step-by-step makeover.
//
// September 2026 feedback: a full look is not generated in one long run. Each
// item (hair, clothes, shoes, accessories) is generated on top of the last
// one the user kept, shown straight away, and then kept, redone, skipped or
// undone. Each wait is one quick change, and the user steers as they go.
//
// Pure data: the page owns generation and feeds results in.
import 'package:flutter/foundation.dart';

import 'package:banigoba/modules/provider/models/look_request.dart';

@immutable
class LookSession {
  const LookSession({
    required this.originalUrl,
    required this.parts,
    this.results = const [],
    this.pendingUrl = '',
  });

  /// The image the first step builds on.
  final String originalUrl;

  /// The steps, in order.
  final List<LookPart> parts;

  /// One entry per decided step: the image after it, or '' when skipped.
  final List<String> results;

  /// The image made for the current step, waiting to be kept or redone.
  final String pendingUrl;

  int get stepIndex => results.length;

  bool get isFinished => stepIndex >= parts.length;

  LookPart? get currentPart => isFinished ? null : parts[stepIndex];

  /// The step after the current one, or null on the last step.
  LookPart? get nextPart =>
      stepIndex + 1 < parts.length ? parts[stepIndex + 1] : null;

  /// The image the current step changes.
  String get baseUrl =>
      results.lastWhere((url) => url.isNotEmpty, orElse: () => originalUrl);

  /// What the user sees now: the pending result, or the last kept image.
  String get currentUrl => pendingUrl.isNotEmpty ? pendingUrl : baseUrl;

  bool get hasPending => pendingUrl.isNotEmpty;

  bool get canUndo => stepIndex > 0;

  /// Parts that changed the look, including the pending one.
  List<LookPart> get changedParts => [
    for (var index = 0; index < results.length; index++)
      if (results[index].isNotEmpty) parts[index],
    if (hasPending) ?currentPart,
  ];

  /// Status of the step at [index], for the progress strip.
  LookStepState stateOf(int index) {
    if (index < results.length) {
      return results[index].isEmpty
          ? LookStepState.skipped
          : LookStepState.kept;
    }
    return index == stepIndex ? LookStepState.current : LookStepState.upcoming;
  }

  LookSession withPending(String url) => _copy(pendingUrl: url);

  LookSession clearPending() => _copy(pendingUrl: '');

  /// Keeps the pending image and moves to the next step.
  LookSession keep() {
    if (isFinished || !hasPending) return this;
    return _copy(results: [...results, pendingUrl], pendingUrl: '');
  }

  /// Moves on without styling the current item. A result already made for it
  /// is kept, never thrown away; Back or Try again are how to replace one.
  LookSession skip() {
    if (isFinished) return this;
    return _copy(results: [...results, pendingUrl], pendingUrl: '');
  }

  /// Steps back to the previous item, showing what it produced so it can be
  /// kept again or redone. A skipped step comes back with nothing pending.
  LookSession undo() {
    if (!canUndo) return clearPending();
    return _copy(
      results: results.sublist(0, results.length - 1),
      pendingUrl: results.last,
    );
  }

  /// Moves straight to the step at [index].
  ///
  /// Forward: a result already showing for the current step is kept, and
  /// every other step passed over is skipped. Back: as if undoing to that
  /// step, so its result comes back pending.
  LookSession jumpTo(int index) {
    if (index < 0 || index >= parts.length || index == stepIndex) return this;
    if (index < stepIndex) {
      var session = this;
      while (session.stepIndex > index) {
        session = session.undo();
      }
      return session;
    }
    return _copy(
      results: [
        ...results,
        hasPending ? pendingUrl : '',
        for (var skipped = stepIndex + 1; skipped < index; skipped++) '',
      ],
      pendingUrl: '',
    );
  }

  /// Ends the run now: keeps whatever is pending and skips the rest.
  LookSession finish() {
    if (isFinished) return this;
    return _copy(
      results: [
        ...results,
        if (hasPending) pendingUrl,
        for (
          var index = stepIndex + (hasPending ? 1 : 0);
          index < parts.length;
          index++
        )
          '',
      ],
      pendingUrl: '',
    );
  }

  LookSession _copy({List<String>? results, String? pendingUrl}) => LookSession(
    originalUrl: originalUrl,
    parts: parts,
    results: List.unmodifiable(results ?? this.results),
    pendingUrl: pendingUrl ?? this.pendingUrl,
  );
}

enum LookStepState { kept, skipped, current, upcoming }
