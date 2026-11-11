// Keeping what people write kind (review item C-3): free-text comments and the
// personal note on an affirmation are checked before they are sent, so
// harassment, body shaming and spam never reach another person.
//
// The rules are deliberately plain and explainable: a short list of unkind
// words and phrases, links, shouting and repetition. Each refusal says why in
// a friendly sentence, and the person can rewrite and send again. The list is
// a starting point for curators to grow, not a promise to catch everything.
import 'package:flutter/foundation.dart';

/// The longest comment and the longest note on an affirmation.
const int kMaxCommentLength = 500;
const int kMaxAffirmationNoteLength = 140;

enum ModerationReason {
  empty('Write something first.'),
  tooLong('That is a bit long. Try shortening it.'),
  link(
    'Links are not allowed in comments. Tell people what you like about the look instead.',
  ),
  shouting('Try writing in normal letters, without all the capitals.'),
  repetition('Try saying it without the repeats.'),
  unkind('Let us keep Banigoba kind. Try saying what you like about the look.');

  const ModerationReason(this.message);

  /// A friendly sentence to show the person.
  final String message;
}

@immutable
class ModerationResult {
  const ModerationResult.allowed(this.text) : reason = null;
  const ModerationResult.refused(this.reason) : text = '';

  /// The text to send, trimmed, when allowed.
  final String text;
  final ModerationReason? reason;

  bool get isAllowed => reason == null;
}

/// Thrown by services when text is refused, carrying the friendly message.
class ModerationException implements Exception {
  const ModerationException(this.reason);

  final ModerationReason reason;

  String get message => reason.message;

  @override
  String toString() => message;
}

/// Words that are unkind on their own, matched as whole words.
const Set<String> kUnkindWords = {
  'ugly',
  'hideous',
  'disgusting',
  'gross',
  'repulsive',
  'fatso',
  'loser',
  'stupid',
  'idiot',
  'moron',
  'dumb',
  'worthless',
  'trash',
  'garbage',
  'pathetic',
  'slut',
  'whore',
  'bitch',
  'bastard',
  'retard',
};

/// Phrases that are unkind (matched inside the cleaned text).
const List<String> kUnkindPhrases = [
  'kill yourself',
  'go die',
  'hope you die',
  'you should die',
  'fat cow',
  'so fat',
  'too fat',
  'look fat',
  'looks fat',
  'you are fat',
  'youre fat',
  'you look terrible',
  'you look awful',
  'you look disgusting',
  'nobody likes you',
  'no one likes you',
  'shut up',
  'ugly face',
  'what a mess',
];

/// Undoes the usual tricks for slipping a word past a filter: capitals,
/// look-alike symbols and stretched letters.
@visibleForTesting
String cleanForMatching(String input) {
  const swaps = {
    '@': 'a',
    '0': 'o',
    '1': 'i',
    '3': 'e',
    '\$': 's',
    '5': 's',
    '4': 'a',
    '7': 't',
  };
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(swaps[char] ?? char);
  }
  var text = buffer.toString();
  text = text.replaceAll(RegExp(r'[^a-z\s]'), '');
  // "uuuugly" -> "ugly": three or more of a letter become one.
  text = text.replaceAllMapped(RegExp(r'([a-z])\1{2,}'), (m) => m[1]!);
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

final RegExp _link = RegExp(
  r'(https?:\/\/|www\.|\b[a-z0-9-]+\.(com|net|org|co|io|app|me|ly|zw)\b|[\w.+-]+@[\w-]+\.[\w.]+)',
  caseSensitive: false,
);

ModerationResult _refuse(ModerationReason reason) =>
    ModerationResult.refused(reason);

/// Checks [input] for sending as a comment, or as an affirmation note when
/// [maxLength] is [kMaxAffirmationNoteLength].
ModerationResult moderateText(
  String input, {
  int maxLength = kMaxCommentLength,
}) {
  final text = input.trim();
  if (text.isEmpty) return _refuse(ModerationReason.empty);
  if (text.length > maxLength) return _refuse(ModerationReason.tooLong);
  if (_link.hasMatch(text)) return _refuse(ModerationReason.link);

  final letters = text.replaceAll(RegExp(r'[^A-Za-z]'), '');
  if (letters.length >= 12) {
    final upper = letters.replaceAll(RegExp(r'[^A-Z]'), '').length;
    if (upper / letters.length > 0.7) {
      return _refuse(ModerationReason.shouting);
    }
  }

  // The same character many times, or the same word over and over.
  if (RegExp(r'(.)\1{6,}').hasMatch(text)) {
    return _refuse(ModerationReason.repetition);
  }
  final words = text.toLowerCase().split(RegExp(r'\s+'));
  if (words.length >= 4) {
    final counts = <String, int>{};
    for (final word in words) {
      counts[word] = (counts[word] ?? 0) + 1;
    }
    if (counts.values.any(
      (count) => count >= 4 && count / words.length > 0.5,
    )) {
      return _refuse(ModerationReason.repetition);
    }
  }

  final cleaned = cleanForMatching(text);
  final spaced = ' $cleaned ';
  for (final word in kUnkindWords) {
    if (spaced.contains(' $word ')) return _refuse(ModerationReason.unkind);
  }
  for (final phrase in kUnkindPhrases) {
    if (spaced.contains(' $phrase ')) return _refuse(ModerationReason.unkind);
  }
  return ModerationResult.allowed(text);
}
