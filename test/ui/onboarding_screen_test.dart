// The intro slides market the app before login. They must never ask for
// permissions or preferences, which come after the account exists.
import 'package:banigoba/ui/screens/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app() {
  return MaterialApp(
    initialRoute: '/intro',
    routes: {
      '/intro': (_) => const OnboardingScreen(),
      '/': (_) => const Scaffold(body: Text('login')),
    },
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('slides market the app and ask for nothing', () {
    expect(onboardingSlides, isNotEmpty);
    for (final slide in onboardingSlides) {
      final copy = '${slide.title} ${slide.body}'.toLowerCase();
      expect(copy, isNot(contains('permission')));
      expect(copy, isNot(contains('allow')));
    }
  });

  testWidgets('Next walks through every slide, then Get Started finishes', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    for (var index = 0; index < onboardingSlides.length; index += 1) {
      expect(find.text(onboardingSlides[index].title), findsOneWidget);
      final isLast = index == onboardingSlides.length - 1;
      expect(find.text(isLast ? 'Get Started' : 'Next'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('onboarding_next')));
      await tester.pumpAndSettle();
    }

    expect(find.text('login'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(OnboardingScreen.doneKey), isTrue);
  });

  testWidgets('Skip finishes the intro from the first slide', (tester) async {
    await tester.pumpWidget(_app());

    await tester.tap(find.byKey(const ValueKey('onboarding_skip')));
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(OnboardingScreen.doneKey), isTrue);
  });
}
