import 'package:banigoba/ui/widgets/brand_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _phone = Size(390, 844);

Future<void> _pumpSplash(WidgetTester tester) async {
  tester.view
    ..physicalSize = _phone * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: BrandSplash()));
}

Rect _logo(WidgetTester tester) =>
    tester.getRect(find.byKey(const ValueKey('brand_splash_logo')));

double _spinnerOpacity(WidgetTester tester) => tester
    .widget<FadeTransition>(find.byKey(const ValueKey('brand_splash_spinner')))
    .opacity
    .value;

void main() {
  setUp(debugResetBrandSplash);

  testWidgets('matches the native splash frame', (tester) async {
    await _pumpSplash(tester);

    final scaffold = tester.widget<Scaffold>(
      find.byKey(const ValueKey('brand_splash')),
    );
    expect(scaffold.backgroundColor, kBrandSplashNavy);

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
