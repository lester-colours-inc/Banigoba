// Verifies who may see a post, and which friends' dress-ups show today.
import 'package:banigoba/data/models/post.dart';
import 'package:banigoba/ui/screens/main/widgets/friends_dress_ups.dart';
import 'package:flutter_test/flutter_test.dart';

Post _post({
  String id = 'p1',
  String authorId = 'rudo',
  PostVisibility visibility = PostVisibility.public,
  PostKind kind = PostKind.look,
  DateTime? createdAt,
}) {
  return Post(
    id: id,
    authorId: authorId,
    caption: '',
    commentCount: 0,
    createdAt: createdAt ?? DateTime(2026, 10, 14, 8),
    imageURL: 'https://example.com/$id.png',
    visibility: visibility,
    kind: kind,
  );
}

bool _sees(
  Post post, {
  Set<String> following = const {},
  Set<String> friends = const {},
}) => post.isVisibleTo('me', following: following, friends: friends);

void main() {
  group('isVisibleTo', () {
    test('owners always see their own posts, even private ones', () {
      expect(
        _sees(_post(authorId: 'me', visibility: PostVisibility.private)),
        isTrue,
      );
    });

    test('public posts are seen by everyone', () {
      expect(_sees(_post()), isTrue);
    });

    test('friends posts are seen only by friends', () {
      final post = _post(visibility: PostVisibility.friends);
      expect(_sees(post), isFalse);
      expect(_sees(post, following: {'rudo'}), isFalse);
      expect(_sees(post, friends: {'rudo'}), isTrue);
    });

    test('followers posts are seen by followers', () {
      final post = _post(visibility: PostVisibility.followers);
      expect(_sees(post), isFalse);
      expect(_sees(post, following: {'rudo'}), isTrue);
    });

    test('nobody else sees a private post', () {
      expect(
        _sees(
          _post(visibility: PostVisibility.private),
          following: {'rudo'},
          friends: {'rudo'},
        ),
        isFalse,
      );
    });
  });

  group('PostKind', () {
    test('defaults to a look, and reads a dress-up', () {
      expect(PostKind.fromValue(null), PostKind.look);
      expect(PostKind.fromValue('dressUp'), PostKind.dressUp);
    });

    test('only a dress-up writes its kind', () {
      expect(_post().toFirestore().containsKey('kind'), isFalse);
      expect(_post(kind: PostKind.dressUp).toFirestore()['kind'], 'dressUp');
    });
  });

  group('friendsDressUps', () {
    final now = DateTime(2026, 10, 14, 12);

    List<String> ids(List<Post> posts) => friendsDressUps(
      posts,
      viewerId: 'me',
      following: const {},
      friends: const {'rudo', 'tariro'},
      now: now,
    ).map((post) => post.id).toList();

    test('shows friends\' recent dress-ups, newest first', () {
      expect(
        ids([
          _post(
            id: 'early',
            kind: PostKind.dressUp,
            visibility: PostVisibility.friends,
            createdAt: DateTime(2026, 10, 14, 7),
          ),
          _post(
            id: 'late',
            authorId: 'tariro',
            kind: PostKind.dressUp,
            visibility: PostVisibility.friends,
            createdAt: DateTime(2026, 10, 14, 9),
          ),
        ]),
        ['late', 'early'],
      );
    });

    test('leaves out looks, my own, old ones and ones I may not see', () {
      expect(
        ids([
          _post(id: 'look'),
          _post(id: 'mine', authorId: 'me', kind: PostKind.dressUp),
          _post(
            id: 'old',
            kind: PostKind.dressUp,
            createdAt: DateTime(2026, 10, 12),
          ),
          _post(
            id: 'stranger',
            authorId: 'farai',
            kind: PostKind.dressUp,
            visibility: PostVisibility.friends,
          ),
        ]),
        isEmpty,
      );
    });
  });
}
