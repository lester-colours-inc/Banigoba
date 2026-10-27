// Verifies the private-email lookup key and how visible posts are merged.
import 'package:banigoba/data/models/post.dart';
import 'package:banigoba/data/services/account_privacy_service.dart';
import 'package:banigoba/data/services/visible_posts.dart';
import 'package:flutter_test/flutter_test.dart';

Post _post(String id, DateTime createdAt) => Post(
  id: id,
  authorId: 'a',
  caption: '',
  commentCount: 0,
  createdAt: createdAt,
  imageURL: '',
);

void main() {
  group('emailLookupKey', () {
    test('matches the migration script for the same address', () {
      // Same value as functions/scripts/migrate_private_emails.js computes.
      expect(
        emailLookupKey('tariro@example.com'),
        '83f79960fc548d117c57f8c04591b1c56a1ecddc0a378ca7e1249e4afb6d9bbb',
      );
    });

    test('ignores case and surrounding spaces', () {
      expect(
        emailLookupKey(' Tariro@Example.com '),
        emailLookupKey('tariro@example.com'),
      );
    });

    test('does not contain the address', () {
      expect(emailLookupKey('tariro@example.com'), isNot(contains('tariro')));
    });
  });

  test('looksLikeEmail only accepts a whole address', () {
    expect(looksLikeEmail('tariro@example.com'), isTrue);
    expect(looksLikeEmail('tariro@'), isFalse);
    expect(looksLikeEmail('tariro'), isFalse);
    expect(looksLikeEmail('a b@c.d'), isFalse);
  });

  test('visible posts are merged once each, newest first', () {
    final older = _post('1', DateTime(2026, 10, 1));
    final newer = _post('2', DateTime(2026, 10, 2));
    final merged = mergeVisiblePosts([
      [older],
      [newer, older],
    ]);
    expect(merged.map((post) => post.id), ['2', '1']);
  });
}
