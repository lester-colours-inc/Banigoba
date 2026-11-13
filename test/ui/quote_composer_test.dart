import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:banigoba/modules/social/models/post.dart';
import 'package:banigoba/modules/social/views/quote_composer_page.dart';
import 'package:banigoba/modules/social/widgets/quoted_look_card.dart';

const _preview = QuotedLookPreview(
  authorName: 'Thandi',
  timeLabel: '1d',
  text: 'Sunday best',
);

Future<QuoteDraft?> _open(WidgetTester tester) async {
  QuoteDraft? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await showQuoteComposer(
            context,
            preview: _preview,
            audience: PostVisibility.followers,
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('shows the quoted look as a card under the comment field', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('Add a comment…'), findsOneWidget);
    expect(find.byKey(const ValueKey('quoted_look_card')), findsOneWidget);
    expect(find.text('Thandi'), findsOneWidget);
    expect(find.text(' · 1d'), findsOneWidget);
    expect(find.text('Sunday best'), findsOneWidget);
    expect(find.text('Your followers can see this'), findsOneWidget);
  });

  testWidgets('Post stays disabled until something is typed', (tester) async {
    await _open(tester);

    FilledButton post() =>
        tester.widget<FilledButton>(find.byKey(const ValueKey('quote_post')));
    expect(post().onPressed, isNull);

    await tester.enterText(find.byKey(const ValueKey('quote_field')), '   ');
    await tester.pump();
    expect(post().onPressed, isNull);

    await tester.enterText(find.byKey(const ValueKey('quote_field')), 'Love');
    await tester.pump();
    expect(post().onPressed, isNotNull);
  });

  testWidgets('Post returns the trimmed words and chosen audience', (
    tester,
  ) async {
    QuoteDraft? draft;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                draft = await showQuoteComposer(context, preview: _preview),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('quote_audience')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('share_audience_friends')));
    await tester.pumpAndSettle();
    expect(find.text('Your friends can see this'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('quote_field')),
      '  So good  ',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('quote_post')));
    await tester.pumpAndSettle();

    expect(draft?.text, 'So good');
    expect(draft?.audience, PostVisibility.friends);
  });

  testWidgets('closing returns nothing', (tester) async {
    await _open(tester);
    await tester.tap(find.byKey(const ValueKey('quote_close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quote_composer')), findsNothing);
  });
}
