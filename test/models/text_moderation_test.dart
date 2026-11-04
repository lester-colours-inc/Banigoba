// Verifies how comments and affirmation notes are kept kind (C-3).
import 'package:banigoba/data/models/text_moderation.dart';
import 'package:flutter_test/flutter_test.dart';

ModerationReason? _why(String text, {int max = kMaxCommentLength}) =>
    moderateText(text, maxLength: max).reason;

void main() {
  group('kind comments go through', () {
    test('ordinary praise is allowed and trimmed', () {
      final result = moderateText('  Love the colours, so elegant!  ');
      expect(result.isAllowed, isTrue);
      expect(result.text, 'Love the colours, so elegant!');
    });

    test('a few capitals and exclamation marks are fine', () {
      expect(moderateText('WOW this is stunning!!').isAllowed, isTrue);
    });

    test('words that merely contain an unkind word are fine', () {
      expect(
        moderateText('Such a classic, I am a big fan of the cut').isAllowed,
        isTrue,
      );
      expect(moderateText('Beautiful, you look amazing').isAllowed, isTrue);
    });
  });

  group('refusals', () {
    test('nothing, or too much', () {
      expect(_why('   '), ModerationReason.empty);
      expect(_why('a' * 501), ModerationReason.tooLong);
      expect(
        _why('a' * 141, max: kMaxAffirmationNoteLength),
        ModerationReason.tooLong,
      );
    });

    test('links, domains and emails', () {
      expect(_why('buy now https://spam.example'), ModerationReason.link);
      expect(_why('see www.shop.co'), ModerationReason.link);
      expect(_why('find me on shoes4u.com'), ModerationReason.link);
      expect(_why('mail me at a.b@c.zw'), ModerationReason.link);
    });

    test('shouting', () {
      expect(
        _why('THIS IS THE WORST THING EVER SEEN'),
        ModerationReason.shouting,
      );
    });

    test('repetition', () {
      expect(_why('nooooooooooo way'), ModerationReason.repetition);
      expect(_why('buy buy buy buy buy now'), ModerationReason.repetition);
    });

    test('unkind words, however they are dressed up', () {
      expect(_why('you are so ugly'), ModerationReason.unkind);
      expect(_why('UGLY!!'), ModerationReason.unkind);
      expect(_why('what a l0ser'), ModerationReason.unkind);
      expect(_why('uuuugly outfit'), ModerationReason.unkind);
      expect(_why('st.u.p.i.d choice'), ModerationReason.unkind);
    });

    test('unkind phrases, including body shaming and threats', () {
      expect(_why('That dress makes you look fat'), ModerationReason.unkind);
      expect(_why('you are too fat for this'), ModerationReason.unkind);
      expect(_why('go die'), ModerationReason.unkind);
      expect(_why('Kill yourself'), ModerationReason.unkind);
    });
  });

  test('every refusal has a friendly message', () {
    for (final reason in ModerationReason.values) {
      expect(reason.message, isNotEmpty);
      expect(reason.message.toLowerCase(), isNot(contains('banned')));
    }
    expect(
      const ModerationException(ModerationReason.unkind).message,
      ModerationReason.unkind.message,
    );
  });

  test('cleaning undoes look-alike symbols and stretched letters', () {
    expect(cleanForMatching('UGLY!!!'), 'ugly');
    expect(cleanForMatching('l0ser'), 'loser');
    expect(cleanForMatching('uuuugly'), 'ugly');
  });
}
