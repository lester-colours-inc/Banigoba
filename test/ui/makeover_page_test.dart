import 'dart:typed_data';

import 'package:banigoba/data/models/look_request.dart';
import 'package:banigoba/data/models/weather.dart';
import 'package:banigoba/data/services/look_generation_service.dart';
import 'package:banigoba/data/style/style_catalogue.dart';
import 'package:banigoba/ui/screens/makeover/makeover_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGenerator implements LookImageGenerator {
  final List<String> prompts = [];

  @override
  bool get isConfigured => true;

  @override
  Future<Uint8List> generate({
    required String photoUrl,
    required String prompt,
  }) async {
    prompts.add(prompt);
    return Uint8List.fromList([1]);
  }
}

Future<_FakeGenerator> _pumpPage(
  WidgetTester tester, {
  String photoUrl = 'https://example.com/me.jpg',
  LookScope scope = LookScope.fullLook,
  Future<Weather?> Function()? loadWeather,
}) async {
  final generator = _FakeGenerator();
  // Tall enough that every option in the editor is built.
  tester.view.physicalSize = const Size(1080, 4800);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: MakeoverPage(
        initialPhotoUrl: photoUrl,
        initialScope: scope,
        loadWeather: loadWeather,
        generationService: LookGenerationService(
          generator: generator,
          upload: (_, _) async => 'https://example.com/look.jpg',
          currentUserId: () => 'user-1',
        ),
      ),
    ),
  );
  return generator;
}

ButtonStyleButton _generateButton(WidgetTester tester) => tester
    .widget<ButtonStyleButton>(find.byKey(const ValueKey('makeover_generate')));

void main() {
  testWidgets('shows the photo step first and no product catalogue', (
    tester,
  ) async {
    await _pumpPage(tester);

    final photoTop = tester.getTopLeft(find.text('1. Your photo')).dy;
    final howTop = tester.getTopLeft(find.text('3. How?')).dy;
    expect(photoTop, lessThan(howTop));
    expect(find.textContaining('Choose items'), findsNothing);
    for (final method in ['Describe it', 'Style icon', 'Weather', 'Trending']) {
      expect(find.text(method), findsOneWidget);
    }
  });

  testWidgets('Create my look stays disabled until the idea is complete', (
    tester,
  ) async {
    await _pumpPage(tester);
    expect(_generateButton(tester).onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('look_describe_field')),
      'I want a low haircut',
    );
    await tester.pump();
    expect(_generateButton(tester).onPressed, isNotNull);
  });

  testWidgets('needs a photo before generating', (tester) async {
    await _pumpPage(tester, photoUrl: '');
    await tester.enterText(
      find.byKey(const ValueKey('look_describe_field')),
      'braids',
    );
    await tester.pump();

    expect(_generateButton(tester).onPressed, isNull);
    expect(find.text('Add your photo to continue'), findsOneWidget);
  });

  testWidgets('generates one look and shows save and try-another', (
    tester,
  ) async {
    final generator = await _pumpPage(tester);
    await tester.enterText(
      find.byKey(const ValueKey('look_describe_field')),
      'I want a low haircut',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('makeover_generate')));
    await tester.pumpAndSettle();

    expect(generator.prompts, hasLength(1));
    expect(find.byKey(const ValueKey('makeover_save')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('makeover_try_another')));
    await tester.pumpAndSettle();
    expect(generator.prompts, hasLength(2));
  });

  testWidgets('style icon generates from the chosen archetype', (tester) async {
    final generator = await _pumpPage(tester);
    final archetype = styleArchetypes.first;

    await tester.tap(find.byKey(const ValueKey('look_method_styleIcon')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('look_option_${archetype.name}')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('makeover_generate')));
    await tester.pumpAndSettle();

    expect(generator.prompts.single, contains(archetype.promptHint));
  });

  testWidgets('trending hides hair trends when only the outfit changes', (
    tester,
  ) async {
    await _pumpPage(tester, scope: LookScope.outfit);

    await tester.tap(find.byKey(const ValueKey('look_method_trending')));
    await tester.pumpAndSettle();

    for (final trend in curatedTrends) {
      expect(
        find.byKey(ValueKey('look_option_${trend.name}')),
        trend.isHair ? findsNothing : findsOneWidget,
        reason: trend.name,
      );
    }
  });

  testWidgets('weather loads when chosen and feeds the prompt', (tester) async {
    final generator = await _pumpPage(
      tester,
      loadWeather: () async => Weather(
        temperatureC: 28,
        condition: 'Sunny',
        iconUrl: '',
        locationName: 'Harare',
      ),
    );

    await tester.tap(find.byKey(const ValueKey('look_method_weather')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Harare'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('makeover_generate')));
    await tester.pumpAndSettle();
    expect(generator.prompts.single, contains('28°C, sunny'));
  });
}
