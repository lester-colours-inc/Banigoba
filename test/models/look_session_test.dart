import 'package:banigoba/modules/provider/models/look_request.dart';
import 'package:banigoba/modules/makeover/models/look_session.dart';
import 'package:flutter_test/flutter_test.dart';

const _original = 'original.jpg';

LookSession _fullLook() =>
    LookSession(originalUrl: _original, parts: LookScope.fullLook.parts);

void main() {
  test('starts on the first item, building on the original photo', () {
    final session = _fullLook();

    expect(session.currentPart, LookPart.hair);
    expect(session.nextPart, LookPart.outfit);
    expect(session.baseUrl, _original);
    expect(session.currentUrl, _original);
    expect(session.canUndo, isFalse);
    expect(session.hasPending, isFalse);
  });

  test('each kept item becomes the base of the next', () {
    final session = _fullLook().withPending('hair.jpg').keep();

    expect(session.currentPart, LookPart.outfit);
    expect(session.baseUrl, 'hair.jpg');
    expect(session.hasPending, isFalse);
    expect(session.changedParts, [LookPart.hair]);
  });

  test('keep does nothing until there is a result', () {
    final session = _fullLook();
    expect(session.keep().stepIndex, 0);
  });

  test('skipping an item with a result keeps that result', () {
    final session = _fullLook().withPending('hair.jpg').skip();

    expect(session.currentPart, LookPart.outfit);
    expect(session.baseUrl, 'hair.jpg');
    expect(session.stateOf(0), LookStepState.kept);
  });

  test('a skipped item leaves the base unchanged', () {
    final session = _fullLook().withPending('hair.jpg').keep().skip();

    expect(session.currentPart, LookPart.shoes);
    expect(session.baseUrl, 'hair.jpg');
    expect(session.stateOf(0), LookStepState.kept);
    expect(session.stateOf(1), LookStepState.skipped);
    expect(session.stateOf(2), LookStepState.current);
    expect(session.stateOf(3), LookStepState.upcoming);
  });

  test('undo returns to the previous item with its result pending', () {
    final session = _fullLook()
        .withPending('hair.jpg')
        .keep()
        .withPending('clothes.jpg')
        .undo();

    expect(session.currentPart, LookPart.hair);
    expect(session.pendingUrl, 'hair.jpg');
    expect(session.baseUrl, _original);
  });

  test('undo to a skipped item brings nothing back to keep', () {
    final session = _fullLook().skip().undo();

    expect(session.currentPart, LookPart.hair);
    expect(session.hasPending, isFalse);
  });

  test('finishing early keeps the pending result and skips the rest', () {
    final session = _fullLook()
        .withPending('hair.jpg')
        .keep()
        .withPending('clothes.jpg')
        .finish();

    expect(session.isFinished, isTrue);
    expect(session.baseUrl, 'clothes.jpg');
    expect(session.changedParts, [LookPart.hair, LookPart.outfit]);
    expect(session.results, hasLength(LookScope.fullLook.parts.length));
  });

  test('keeping the last item finishes the run', () {
    final session = LookSession(
      originalUrl: _original,
      parts: const [LookPart.hair],
    ).withPending('hair.jpg').keep();

    expect(session.isFinished, isTrue);
    expect(session.currentPart, isNull);
    expect(session.baseUrl, 'hair.jpg');
  });

  test('skipping everything changes nothing', () {
    var session = _fullLook();
    while (!session.isFinished) {
      session = session.skip();
    }

    expect(session.changedParts, isEmpty);
    expect(session.baseUrl, _original);
  });

  group('jumpTo', () {
    test('forward skips the steps in between', () {
      final session = _fullLook().jumpTo(2);

      expect(session.currentPart, LookPart.shoes);
      expect(session.stateOf(0), LookStepState.skipped);
      expect(session.stateOf(1), LookStepState.skipped);
      expect(session.baseUrl, _original);
    });

    test('forward keeps a result already showing for the current step', () {
      final session = _fullLook().withPending('hair.jpg').jumpTo(3);

      expect(session.currentPart, LookPart.accessories);
      expect(session.stateOf(0), LookStepState.kept);
      expect(session.stateOf(1), LookStepState.skipped);
      expect(session.baseUrl, 'hair.jpg');
    });

    test('back returns to an earlier step with its result pending', () {
      final session = _fullLook()
          .withPending('hair.jpg')
          .keep()
          .withPending('clothes.jpg')
          .keep()
          .jumpTo(0);

      expect(session.currentPart, LookPart.hair);
      expect(session.pendingUrl, 'hair.jpg');
      expect(session.baseUrl, _original);
    });

    test('ignores the current step and out-of-range steps', () {
      final session = _fullLook().withPending('hair.jpg');

      expect(session.jumpTo(0), same(session));
      expect(session.jumpTo(4), same(session));
      expect(session.jumpTo(-1), same(session));
    });
  });
}
