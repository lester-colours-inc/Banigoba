// Verifies post audiences and the repost / quote fields.
import 'package:banigoba/data/models/post.dart';
import 'package:flutter_test/flutter_test.dart';

Post _post({
  PostVisibility visibility = PostVisibility.public,
  String repostOfId = '',
  String quoteText = '',
}) {
  return Post(
    id: 'p2',
    authorId: 'me',
    caption: 'Sunday best',
    commentCount: 0,
    createdAt: DateTime(2026, 10, 12),
    imageURL: 'https://example.com/look.png',
    visibility: visibility,
    repostOfId: repostOfId,
    repostOfAuthorId: repostOfId.isEmpty ? '' : 'tariro',
    quoteText: quoteText,
  );
}

void main() {
  test('audiences run from only me to public', () {
    expect(PostVisibility.values.map((v) => v.label), [
      'Only me',
      'Friends',
      'Followers',
      'Public',
    ]);
  });

  test('reads followers visibility and falls back to the legacy flag', () {
    expect(
      PostVisibility.fromValue('followers', legacyIsPublic: false),
      PostVisibility.followers,
    );
    expect(
      PostVisibility.fromValue(null, legacyIsPublic: true),
      PostVisibility.public,
    );
  });

  test('a followers post is shared but not public', () {
    final post = _post(visibility: PostVisibility.followers);
    expect(post.isShared, isTrue);
    expect(post.isPublic, isFalse);
    expect(post.toRow()['visibility'], 'followers');
  });

  test('a plain repost is not a quote', () {
    final post = _post(repostOfId: 'p1');
    expect(post.isRepost, isTrue);
    expect(post.isQuote, isFalse);
    expect(post.toRow(), containsPair('repost_of_id', 'p1'));
    expect(post.toRow().containsKey('quote_text'), isFalse);
  });

  test('a repost with words is a quote', () {
    final post = _post(repostOfId: 'p1', quoteText: 'This colour!');
    expect(post.isQuote, isTrue);
    expect(post.toRow(), containsPair('quote_text', 'This colour!'));
  });

  test('an original post carries no repost fields', () {
    final data = _post().toRow();
    expect(data.containsKey('repost_of_id'), isFalse);
    expect(data.containsKey('repost_of_author_id'), isFalse);
  });
}
