// Verifies the Fashion Twins / Idols / Hairstyles list helpers.
import 'package:banigoba/modules/style_lists/services/style_lists_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an idol typed twice keeps one entry', () {
    expect(idolIdFor('Michelle Obama'), 'michelle-obama');
    expect(idolIdFor('  michelle   OBAMA! '), 'michelle-obama');
    expect(idolIdFor('!!!'), isEmpty);
  });

  test('entries sort newest first, unsaved ones on top', () {
    final sorted = sortNewestFirst([
      StyleListEntry(id: 'old', name: 'a', addedAt: DateTime(2026, 1, 1)),
      const StyleListEntry(id: 'pending', name: 'b'),
      StyleListEntry(id: 'new', name: 'c', addedAt: DateTime(2026, 10, 1)),
    ]);
    expect(sorted.map((e) => e.id), ['pending', 'new', 'old']);
  });

  test('a twin keeps their @username and picture', () {
    const twin = StyleListEntry(
      id: 'u1',
      name: 'Rudo',
      username: 'rudo.style',
      imageUrl: 'https://example.com/r.jpg',
    );
    final map = twin.toMap();
    expect(map['username'], 'rudo.style');
    expect(map['imageUrl'], 'https://example.com/r.jpg');
    expect(StyleListEntry.fromMap('u1', map).name, 'Rudo');
  });

  test('a hairstyle without a note stores no empty fields', () {
    const style = StyleListEntry(id: '', name: '', imageUrl: 'x');
    expect(style.toMap().containsKey('username'), isFalse);
  });
}
