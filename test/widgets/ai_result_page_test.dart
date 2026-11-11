// What a "your look is ready" notification opens.
import 'package:banigoba/ui/widgets/ai_result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _before = 'https://example.com/me.jpg';
const _after = 'https://example.com/look.jpg';

Future<NavigatorState> _pumpHost(WidgetTester tester) async {
  final key = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(navigatorKey: key, home: const SizedBox()),
  );
  return key.currentState!;
}

void main() {
  group('aiResultOf', () {
    test('reads the result and the photo it started from', () {
      final result = aiResultOf({
        'status': 'succeeded',
        'imageUrl': _after,
        'beforeUrl': _before,
      });
      expect(result?.after, _after);
      expect(result?.before, _before);
    });

    test('nothing to show for a failed job or a missing picture', () {
      expect(aiResultOf(null), isNull);
      expect(aiResultOf({'status': 'failed', 'imageUrl': _after}), isNull);
      expect(aiResultOf({'status': 'succeeded', 'imageUrl': ''}), isNull);
    });
  });

  testWidgets('a finished look opens on the before and after', (tester) async {
    final navigator = await _pumpHost(tester);

    final opened = openAiResult(navigator, {
      'status': 'succeeded',
      'kind': 'makeover',
      'imageUrl': _after,
      'beforeUrl': _before,
    });
    await tester.pumpAndSettle();

    expect(opened, isTrue);
    expect(find.text('Your makeover'), findsOneWidget);
    expect(find.byKey(const ValueKey('ai_result_compare')), findsOneWidget);
    expect(find.text('BEFORE'), findsOneWidget);
    expect(find.text('AFTER'), findsOneWidget);
  });

  testWidgets('without a before photo it shows just the look', (tester) async {
    final navigator = await _pumpHost(tester);

    openAiResult(navigator, {'status': 'succeeded', 'imageUrl': _after});
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('ai_result_compare')), findsNothing);
    expect(find.byKey(const ValueKey('ai_result_only')), findsOneWidget);
  });

  testWidgets('a failed job opens nothing', (tester) async {
    final navigator = await _pumpHost(tester);

    final opened = openAiResult(navigator, {'status': 'failed'});
    await tester.pumpAndSettle();

    expect(opened, isFalse);
    expect(find.byType(AiResultPage), findsNothing);
  });
}
