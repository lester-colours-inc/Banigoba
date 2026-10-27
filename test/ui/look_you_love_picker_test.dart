// Verifies which looks each "look you love" source offers (M-10, P-9).
import 'package:banigoba/data/models/post.dart';
import 'package:banigoba/ui/screens/makeover/widgets/look_you_love_picker.dart';
import 'package:flutter_test/flutter_test.dart';

Post _post(
  String id,
  String author, {
  PostVisibility visibility = PostVisibility.public,
  String caption = '',
  PostKind kind = PostKind.look,
}) => Post(
  id: id,
  authorId: author,
  caption: caption,
  commentCount: 0,
  createdAt: DateTime(2026, 10, 21),
  imageURL: 'https://example.com/$id.png',
  visibility: visibility,
  kind: kind,
);

final _data = LookLoveData(
  posts: [
    _post('rudo1', 'rudo', caption: 'Wedding guest in ankara'),
    _post('farai1', 'farai', visibility: PostVisibility.followers),
    _post('zoe1', 'zoe', caption: 'Street style'),
    _post('mine', 'me'),
    _post('dress', 'rudo', kind: PostKind.dressUp),
  ],
  following: {'rudo', 'farai'},
  twins: {'zoe'},
  affirmed: {'zoe1'},
  saved: const [
    PickableLook(id: 's1', imageUrl: 'a', category: 'Church'),
    PickableLook(id: 's2', imageUrl: 'b', category: 'Work'),
    PickableLook(id: 's3', imageUrl: 'c'),
  ],
);

List<String> _ids(
  LookLoveSource source, {
  String category = '',
  String query = '',
  Map<String, String> names = const {},
}) => looksFor(
  source,
  _data,
  viewerId: 'me',
  category: category,
  query: query,
  authorNames: names,
).map((look) => look.id).toList();

void main() {
  test('following shows looks from people I follow, not mine or dress-ups', () {
    expect(_ids(LookLoveSource.following), ['rudo1', 'farai1']);
  });

  test('twins, affirmed and community each pick their own looks', () {
    expect(_ids(LookLoveSource.twins), ['zoe1']);
    expect(_ids(LookLoveSource.affirmed), ['zoe1']);
    expect(_ids(LookLoveSource.community), ['rudo1', 'zoe1']);
  });

  test('saved looks filter by category', () {
    expect(_ids(LookLoveSource.saved), ['s1', 's2', 's3']);
    expect(_ids(LookLoveSource.saved, category: 'Work'), ['s2']);
    expect(savedCategories(_data.saved), ['Church', 'Work']);
  });

  test('search matches caption, category and author @username', () {
    expect(_ids(LookLoveSource.following, query: 'ankara'), ['rudo1']);
    expect(_ids(LookLoveSource.saved, query: 'church'), ['s1']);
    expect(
      _ids(
        LookLoveSource.community,
        query: '@zoe.s',
        names: {'zoe': 'Zoe M @zoe.style'},
      ),
      ['zoe1'],
    );
  });
}
