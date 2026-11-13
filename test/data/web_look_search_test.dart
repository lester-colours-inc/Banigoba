import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:banigoba/modules/makeover/controllers/web_look_search_state.dart';
import 'package:banigoba/modules/makeover/services/web_look_search.dart';
import 'package:banigoba/modules/makeover/widgets/web_look_results.dart';

const _look = WebLook(
  imageUrl: 'https://cdn.example.com/a.jpg',
  thumbnailUrl: 'https://imgs.search.brave.com/a',
  title: 'Street style',
  source: 'example.com',
);

class _FakeSearch implements WebLookSearch {
  final List<String> asked = [];
  List<WebLook> answer = const [_look];
  Object? failure;
  String? kept = 'https://storage.example.com/ref.jpg';
  Completer<List<WebLook>>? hold;

  @override
  Future<List<WebLook>> search(String query) async {
    asked.add(query);
    if (hold case final completer?) return completer.future;
    if (failure case final error?) throw error;
    return answer;
  }

  @override
  Future<String?> keep(WebLook look) async => kept;
}

void main() {
  group('parseWebLooks', () {
    test('reads looks and keeps only HTTPS pictures', () {
      final looks = parseWebLooks({
        'looks': [
          {
            'imageUrl': 'https://cdn.example.com/a.jpg',
            'thumbnailUrl': 'https://imgs.search.brave.com/a',
            'title': 'Street style',
            'source': 'example.com',
          },
          {'imageUrl': 'http://cdn.example.com/b.jpg'},
          'junk',
        ],
      });
      expect(looks, [_look]);
      expect(looks.single.source, 'example.com');
    });

    test('uses the picture as thumbnail when the thumbnail is unusable', () {
      final looks = parseWebLooks({
        'looks': [
          {'imageUrl': 'https://cdn.example.com/a.jpg', 'thumbnailUrl': ''},
        ],
      });
      expect(looks.single.thumbnailUrl, 'https://cdn.example.com/a.jpg');
    });

    test('returns nothing for an unexpected answer', () {
      expect(parseWebLooks(null), isEmpty);
      expect(parseWebLooks({'looks': 'nope'}), isEmpty);
    });
  });

  test('idolLookQuery asks for the named idol outfits', () {
    expect(idolLookQuery('  Winky D '), 'Winky D outfit');
    expect(idolLookQuery('  '), '');
  });

  group('WebLookSearchState', () {
    late _FakeSearch fake;
    late WebLookSearchState state;

    setUp(() {
      fake = _FakeSearch();
      state = WebLookSearchState(fake, debounce: Duration.zero);
    });

    tearDown(() => state.dispose());

    test('finds looks for the words', () async {
      await state.searchNow(' Winky D ');
      expect(fake.asked, ['Winky D']);
      expect(state.looks, [_look]);
      expect(state.isSearching.value, isFalse);
    });

    test('does not search for fewer than two letters', () async {
      await state.searchNow('a');
      expect(fake.asked, isEmpty);
      expect(state.looks, isEmpty);
    });

    test('shows the server message when the search fails', () async {
      fake.failure = const WebLookSearchException(
        'Web search is not set up yet.',
      );
      await state.searchNow('Winky D');
      expect(state.error.value, 'Web search is not set up yet.');
      expect(state.looks, isEmpty);
    });

    test('keeps only the latest answer', () async {
      final slow = Completer<List<WebLook>>();
      fake.hold = slow;
      final first = state.searchNow('first');
      fake.hold = null;
      fake.answer = const [];
      await state.searchNow('second');
      slow.complete(const [_look]);
      await first;
      expect(state.looks, isEmpty);
    });

    test('keep returns the copy, or explains when it cannot be used', () async {
      expect(await state.keep(_look), 'https://storage.example.com/ref.jpg');
      fake.kept = null;
      expect(await state.keep(_look), isNull);
      expect(state.error.value, contains("couldn't use that picture"));
      expect(state.keeping.value, isNull);
    });
  });

  testWidgets('tapping a web look returns the kept copy', (tester) async {
    final fake = _FakeSearch();
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              picked = await showWebLookSearch(
                context,
                initialQuery: 'Winky D outfit',
                search: fake,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(fake.asked, ['Winky D outfit']);
    expect(find.text(kWebLookNote), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('web_look_${_look.imageUrl}')));
    await tester.pumpAndSettle();
    expect(picked, 'https://storage.example.com/ref.jpg');
  });
}
