import 'package:banigoba/ui/widgets/brand_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _phone = Size(390, 844);

Future<void> _pumpSplash(
  WidgetTester tester, {
  bool reduceMotion = false,
}) async {
  tester.view
    ..physicalSize = _phone * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: _phone,
          devicePixelRatio: 3,
          disableAnimations: reduceMotion,
        ),
        child: const BrandSplash(),
      ),
    ),
  );
}

Rect _logo(WidgetTester tester) =>
    tester.getRect(find.byKey(const ValueKey('brand_splash_logo')));

double _spinnerOpacity(WidgetTester tester) => tester
    .widget<FadeTransition>(find.byKey(const ValueKey('brand_splash_spinner')))
    .opacity
    .value;

double _gOpacity(WidgetTester tester) => tester
    .widget<FadeTransition>(find.byKey(const ValueKey('brand_splash_g')))
    .opacity
    .value;

/// The part of "for looking good" that is visible so far.
String _typedSoFar(WidgetTester tester) {
  final text = tester.widget<Text>(
    find.byKey(const ValueKey('brand_splash_line')),
  );
  final root = text.textSpan! as TextSpan;
  return (root.children!.first as TextSpan).text!;
}

void main() {
  setUp(debugResetBrandSplash);

  testWidgets('matches the native splash frame: wordmark on white', (
    tester,
  ) async {
    await _pumpSplash(tester);

    final scaffold = tester.widget<Scaffold>(
      find.byKey(const ValueKey('brand_splash')),
    );
    expect(scaffold.backgroundColor, kBrandSplashBackground);
    expect(kBrandSplashBackground, Colors.white);

    // Drawn where and as large as the native splash draws it: the 1152 px
    // image at 4x, centred.
    final logo = _logo(tester);
    expect(logo.size, const Size(288, 288));
    expect(logo.center, _phone.center(Offset.zero));

    expect(_spinnerOpacity(tester), 0);
    expect(
      find.bySemanticsLabel('Banigoba. $kBrandPayoffLine'),
      findsOneWidget,
    );
    expect(kBrandPayoffLine, 'g for looking good');
  });

  testWidgets('the g appears, then "for looking good" types in', (
    tester,
  ) async {
    await _pumpSplash(tester);

    expect(_gOpacity(tester), 0);
    expect(_typedSoFar(tester), isEmpty);

    await tester.pump(const Duration(milliseconds: 1000));
    expect(_gOpacity(tester), 1);

    await tester.pump(const Duration(milliseconds: 500));
    final partway = _typedSoFar(tester);
    expect(partway, isNotEmpty);
    expect('for looking good'.startsWith(partway), isTrue);
    expect(partway.length, lessThan('for looking good'.length));

    await tester.pump(const Duration(milliseconds: 800));
    expect(_typedSoFar(tester), 'for looking good');
  });

  testWidgets('the payoff line sits under the wordmark', (tester) async {
    await _pumpSplash(tester);

    final line = tester.getRect(
      find.byKey(const ValueKey('brand_splash_line')),
    );
    // The wordmark ends 31 px below the middle of the logo box.
    final wordmarkBottom = _phone.height / 2 + (175 - 144);
    expect(line.top, greaterThan(wordmarkBottom));
    expect(line.center.dx, closeTo(_phone.width / 2, 24));
  });

  testWidgets('with reduced motion the finished line shows at once', (
    tester,
  ) async {
    await _pumpSplash(tester, reduceMotion: true);

    expect(_gOpacity(tester), 1);
    expect(_typedSoFar(tester), 'for looking good');
  });

  testWidgets('shows the spinner only once the brand moment has played', (
    tester,
  ) async {
    await _pumpSplash(tester);
    await tester.pump(kBrandSplashMinimum - const Duration(milliseconds: 100));
    expect(_spinnerOpacity(tester), 0);

    await tester.pump(const Duration(milliseconds: 400));
    expect(_spinnerOpacity(tester), 1);
  });

  test('the splash is held for the minimum from the first call', () {
    final first = brandSplashTimeRemaining();
    expect(first, lessThanOrEqualTo(kBrandSplashMinimum));
    expect(
      first,
      greaterThan(kBrandSplashMinimum - const Duration(seconds: 1)),
    );
    expect(brandSplashTimeRemaining(), lessThanOrEqualTo(first));
  });
}
