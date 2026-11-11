// Architectural guard.
//
// BNG SRS 001 prohibits public counters on affirmations (AFF-003,
// SRS-DEC-010). That is a product commitment, not a styling preference, and
// the easiest way to lose it is for someone to add a counter field months
// from now because it is the obvious way to build a feed.
//
// Like counts are the one deliberate exception (decided 2026-11-11): a look
// shows how many people liked it, kept by the database from post_likes, while
// who liked it stays private. Affirmations are still never counted in public.
//
// This test fails the build if a banned identifier reappears anywhere in
// lib/. If you are here because it went red: the qualitative path is
// AffirmationService, which keeps affirmations in their own collection and
// never aggregates them onto the content document.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Identifiers that would rebuild a popularity score. `likeCount` is allowed
/// (see above); a public list of who liked a look is not.
const List<String> _bannedIdentifiers = [
  'likedBy',
  'toggleLike',
  'affirmationCount',
  'affirmationScore',
  'affirmationIndex',
];

/// Files permitted to reference the legacy `likes` subcollection, and why.
const Map<String, String> _legacyCleanupAllowList = {
  'lib/data/services/post_service.dart':
      'deletePost still clears the legacy likes subcollection so old '
      'documents do not leave orphans behind',
};

Iterable<File> _dartSourcesIn(String path) {
  final directory = Directory(path);
  if (!directory.existsSync()) return const [];
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
}

void main() {
  group('no popularity counters in lib/', () {
    test('no banned reaction-counter identifier appears', () {
      final offences = <String>[];

      for (final file in _dartSourcesIn('lib')) {
        final contents = file.readAsStringSync();
        final lines = contents.split('\n');

        for (var index = 0; index < lines.length; index += 1) {
          for (final identifier in _bannedIdentifiers) {
            if (lines[index].contains(identifier)) {
              offences.add('${file.path}:${index + 1} contains "$identifier"');
            }
          }
        }
      }

      expect(
        offences,
        isEmpty,
        reason:
            'Reaction counters are prohibited on consumer surfaces. Use '
            'AffirmationService instead.\n${offences.join('\n')}',
      );
    });

    test('only the documented file touches the legacy likes subcollection', () {
      final offenders = <String>[];

      for (final file in _dartSourcesIn('lib')) {
        if (!file.readAsStringSync().contains("collection('likes')")) continue;

        final relativePath = file.path.replaceAll(r'\', '/');
        if (!_legacyCleanupAllowList.containsKey(relativePath)) {
          offenders.add(relativePath);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'The legacy likes subcollection is read-only and scheduled for '
            'removal. New code must not depend on it.\n'
            '${offenders.join('\n')}',
      );
    });

    test('the affirmation row renders no numeral', () {
      final source = File(
        'lib/ui/widgets/affirmation_row.dart',
      ).readAsStringSync();

      // The public feed row shows which expressions were received, never how
      // many. senderCount belongs to the owner's private sheet only.
      final publicSection = source.split(
        'The owner\'s private view of affirmations',
      );
      expect(
        publicSection.first.contains('senderCount'),
        isFalse,
        reason: 'AffirmationRow must not surface a per-expression count',
      );
    });
  });
}
