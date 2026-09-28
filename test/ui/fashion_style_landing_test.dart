// Verifies the Fashion Style landing entry points stay visible and tappable.
import 'package:banigoba/ui/screens/main/my_fashion_style_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows and taps the fashion landing action buttons', (
    tester,
  ) async {
    var startedMakeover = false;
    var selectedOccasion = '';
    var openedPlanAhead = false;
    var openedShoppingIntelligence = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FashionStyleLandingActions(
              selectedStylePreference: 'casual',
              onStartMakeover: () => startedMakeover = true,
              onStyleOccasionSelected: (value) => selectedOccasion = value,
              onPlanAhead: () => openedPlanAhead = true,
              onShoppingIntelligence: () => openedShoppingIntelligence = true,
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('fashion_start_makeover_button')),
      findsOneWidget,
    );
    expect(find.text('Start Your\nAI Makeover'), findsOneWidget);
    expect(
      find.byKey(const Key('fashion_style_by_occasion_section')),
      findsOneWidget,
    );
    expect(find.text('Style By Occasion'), findsOneWidget);
    expect(find.byKey(const Key('fashion_plan_ahead_button')), findsOneWidget);
    expect(
      find.byKey(const Key('fashion_shopping_intelligence_button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('fashion_start_makeover_button')));
    expect(startedMakeover, isTrue);

    await tester.tap(find.byKey(const Key('fashion_occasion_corporate')));
    expect(selectedOccasion, 'corporate');

    await tester.ensureVisible(
      find.byKey(const Key('fashion_plan_ahead_button')),
    );
    await tester.tap(find.byKey(const Key('fashion_plan_ahead_button')));
    expect(openedPlanAhead, isTrue);

    await tester.ensureVisible(
      find.byKey(const Key('fashion_shopping_intelligence_button')),
    );
    await tester.tap(
      find.byKey(const Key('fashion_shopping_intelligence_button')),
    );
    expect(openedShoppingIntelligence, isTrue);
  });

  testWidgets('does not select an occasion when callback is disabled', (
    tester,
  ) async {
    var selectedOccasion = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FashionStyleLandingActions(
              selectedStylePreference: 'casual',
              onStartMakeover: () {},
              onStyleOccasionSelected: null,
              onPlanAhead: () {},
              onShoppingIntelligence: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('fashion_occasion_corporate')));
    expect(selectedOccasion, isEmpty);
  });

  testWidgets('events tab is exposed from the fashion landing tabs', (
    tester,
  ) async {
    var selectedTab = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FashionLandingTabs(
            selectedIndex: 0,
            onSelected: (index) => selectedTab = index,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('fashion_events_tab')), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);

    await tester.tap(find.byKey(const Key('fashion_events_tab')));
    expect(selectedTab, 2);
  });

  testWidgets('invalid selected tab keeps all tab buttons visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FashionLandingTabs(selectedIndex: -1, onSelected: (_) {}),
        ),
      ),
    );

    expect(find.byKey(const Key('fashion_makeover_tab')), findsOneWidget);
    expect(find.byKey(const Key('fashion_community_tab')), findsOneWidget);
    expect(find.byKey(const Key('fashion_events_tab')), findsOneWidget);
  });
}
