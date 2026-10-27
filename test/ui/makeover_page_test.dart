import 'dart:typed_data';

import 'package:banigoba/data/models/body_profile.dart';
import 'package:banigoba/data/models/look_request.dart';
import 'package:banigoba/data/models/weather.dart';
import 'package:banigoba/data/services/look_generation_service.dart';
import 'package:banigoba/data/style/style_catalogue.dart';
import 'package:banigoba/ui/screens/makeover/makeover_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _photo = 'https://example.com/me.jpg';

class _FakeGenerator implements LookImageGenerator {
  final List<String> prompts = [];
  final List<String> photoUrls = [];
  final List<List<String>> references = [];

  @override
  bool get isConfigured => true;

  @override
  Future<Uint8List> generate({
    required String photoUrl,
    required String prompt,
    List<String> referenceImageUrls = const [],
  }) async {
    prompts.add(prompt);
    photoUrls.add(photoUrl);
    references.add(referenceImageUrls);
    return Uint8List.fromList([1]);
  }
}

Future<_FakeGenerator> _pumpPage(
  WidgetTester tester, {
  String photoUrl = _photo,
  LookScope? scope = LookScope.fullLook,
  Future<Weather?> Function()? loadWeather,
  String? editingPostId,
  String? initialTwinUrl,
  String? initialIdolName,
}) async {
  final generator = _FakeGenerator();
  var uploads = 0;
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
        editingPostId: editingPostId,
        initialTwinUrl: initialTwinUrl,
        initialIdolName: initialIdolName,
        loadBodyProfile: () async => const BodyProfile(),
        generationService: LookGenerationService(
          generator: generator,
          // A distinct URL per result, so each step's base can be checked.
          upload: (_, _) async => 'https://example.com/look-${++uploads}.jpg',
          currentUserId: () => 'user-1',
        ),
      ),
    ),
  );
  return generator;
}

ButtonStyleButton _generateButton(WidgetTester tester) =>
    tester.widget<ButtonStyleButton>(
      find.descendant(
        of: find.byKey(const ValueKey('makeover_generate')),
        matching: find.byWidgetPredicate(
          (widget) => widget is ButtonStyleButton,
        ),
      ),
    );

Future<void> _describeAndCreate(WidgetTester tester, String text) async {
  await tester.enterText(
    find.byKey(const ValueKey('look_describe_field')),
    text,
  );
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('makeover_generate')));
  await tester.pumpAndSettle();
}

/// Option B, then one of its sources.
Future<void> _chooseLookYouLove(WidgetTester tester, String key) async {
  await _tapKey(tester, 'look_option_love');
  await _tapKey(tester, key);
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('photo, then describe-or-a-look-you-love, then what changes', (
    tester,
  ) async {
    await _pumpPage(tester);

    double top(Finder finder) => tester.getTopLeft(finder).dy;
    final photoTop = top(find.byKey(const ValueKey('makeover_upload_photo')));
    final howTop = top(find.text('How do you want to create your look?'));
    final describeTop = top(find.byKey(const ValueKey('look_describe_field')));
    final changeTop = top(find.text('What should change?'));
    expect(photoTop, lessThan(howTop));
    expect(howTop, lessThan(describeTop));
    expect(describeTop, lessThan(changeTop));

    expect(find.text('Describe it'), findsOneWidget);
    expect(find.text('Use a look you love'), findsOneWidget);
    // Option B's sources only show once it is chosen.
    expect(find.text('Style idol'), findsNothing);
    expect(find.textContaining('Choose items'), findsNothing);
    expect(find.textContaining('One item at a time'), findsOneWidget);
    expect(find.text('My New Look'), findsOneWidget);
    expect(find.text('Generate my look'), findsOneWidget);
    expect(find.byKey(const ValueKey('makeover_menu')), findsOneWidget);
    expect(find.byKey(const ValueKey('makeover_back')), findsOneWidget);
  });

  testWidgets('a look you love offers twin, idol, trending and weather', (
    tester,
  ) async {
    await _pumpPage(tester);
    await _tapKey(tester, 'look_option_love');

    for (final method in ['Style twin', 'Style idol', 'Trending', 'Weather']) {
      expect(find.text(method), findsOneWidget, reason: method);
    }
    expect(find.byKey(const ValueKey('look_describe_field')), findsNothing);
    // Style twin is the first choice.
    expect(find.text('Seen a look you love?'), findsOneWidget);
  });

  testWidgets('nothing is pre-selected: generate waits for what changes', (
    tester,
  ) async {
    await _pumpPage(tester, scope: null);
    await tester.enterText(
      find.byKey(const ValueKey('look_describe_field')),
      'A white linen shirt',
    );
    await tester.pump();

    expect(_generateButton(tester).onPressed, isNull);
    expect(find.text('Choose what should change'), findsOneWidget);

    await _tapKey(tester, 'look_scope_outfit');
    expect(_generateButton(tester).onPressed, isNotNull);
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

  testWidgets('a full look is built one item at a time', (tester) async {
    final generator = await _pumpPage(tester);
    await _describeAndCreate(tester, 'Smart casual for a Friday');

    // Only the first item has been generated.
    expect(generator.prompts, hasLength(1));
    expect(generator.prompts.single, contains('Change only the hair'));
    expect(generator.photoUrls.single, _photo);
    expect(find.text('Keep & next: Clothes'), findsOneWidget);

    await _tapKey(tester, 'look_step_keep');

    // The next item waits until the user asks for it.
    expect(generator.prompts, hasLength(1));
    expect(find.text('Style my clothes'), findsOneWidget);

    await _tapKey(tester, 'look_step_generate');

    // It builds on top of the kept hair.
    expect(generator.prompts, hasLength(2));
    expect(generator.prompts.last, contains('Change only the clothes'));
    expect(generator.photoUrls.last, 'https://example.com/look-1.jpg');
    expect(find.text('Keep & next: Shoes'), findsOneWidget);
  });

  testWidgets('skip moves on keeping any result, try again redoes the item', (
    tester,
  ) async {
    final generator = await _pumpPage(tester);
    await _describeAndCreate(tester, 'Smart casual');

    await _tapKey(tester, 'look_step_try_again');
    expect(generator.prompts, hasLength(2));
    expect(generator.photoUrls, [_photo, _photo]);

    await _tapKey(tester, 'look_step_skip');
    // Skipping does not start the next item by itself.
    expect(generator.prompts, hasLength(2));

    await _tapKey(tester, 'look_step_generate');
    expect(generator.prompts.last, contains('Change only the clothes'));
    // The hair result made before skipping is kept, so clothes build on it.
    expect(generator.photoUrls.last, 'https://example.com/look-2.jpg');
    expect(
      find.byKey(const ValueKey('look_progress_hair_kept')),
      findsOneWidget,
    );
  });

  testWidgets('tapping a later step skips straight to it', (tester) async {
    final generator = await _pumpPage(tester);
    await _describeAndCreate(tester, 'Smart casual');

    await _tapKey(tester, 'look_progress_shoes_upcoming');

    expect(find.text('Step 3 of 4'), findsOneWidget);
    expect(generator.prompts, hasLength(1));

    await _tapKey(tester, 'look_step_generate');
    expect(generator.prompts.last, contains('Change only the shoes'));
    // The hair result that was showing is kept; clothes were skipped.
    expect(generator.photoUrls.last, 'https://example.com/look-1.jpg');
    expect(
      find.byKey(const ValueKey('look_progress_outfit_skipped')),
      findsOneWidget,
    );

    await _tapKey(tester, 'look_progress_hair_kept');
    expect(find.text('Step 1 of 4'), findsOneWidget);
    expect(generator.prompts, hasLength(2));
  });

  testWidgets('back returns to the previous item and its result', (
    tester,
  ) async {
    final generator = await _pumpPage(tester);
    await _describeAndCreate(tester, 'Smart casual');
    await _tapKey(tester, 'look_step_keep');
    expect(find.text('Step 2 of 4'), findsOneWidget);

    await _tapKey(tester, 'look_step_undo');

    expect(find.text('Step 1 of 4'), findsOneWidget);
    expect(find.text('Keep & next: Clothes'), findsOneWidget);
    // Only the hair was generated; going back adds nothing new.
    expect(generator.prompts, hasLength(1));
  });

  testWidgets('Done finishes early and offers save, find pieces and edit', (
    tester,
  ) async {
    await _pumpPage(tester);
    await _describeAndCreate(tester, 'Smart casual');
    await _tapKey(tester, 'makeover_finish_now');

    expect(find.text('Your look'), findsOneWidget);
    expect(find.text('Changed: Hair'), findsOneWidget);
    for (final key in [
      'makeover_save',
      'makeover_find_pieces',
      'makeover_edit',
      'makeover_new_idea',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
    }

    await _tapKey(tester, 'makeover_find_pieces');
    expect(find.text('Find these pieces'), findsOneWidget);
    expect(find.byKey(const ValueKey('find_piece_Hair')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('find_piece_Have it made')),
      findsOneWidget,
    );
  });

  testWidgets('edit changes one item on top of the finished look', (
    tester,
  ) async {
    final generator = await _pumpPage(tester, scope: LookScope.hair);
    await _describeAndCreate(tester, 'Low cut');
    await _tapKey(tester, 'look_step_keep');
    expect(find.text('Your look'), findsOneWidget);

    await _tapKey(tester, 'makeover_edit');
    await _tapKey(tester, 'look_edit_part_shoes');
    await tester.enterText(
      find.byKey(const ValueKey('look_edit_note')),
      'white sneakers',
    );
    await tester.pump();
    await _tapKey(tester, 'look_edit_apply');

    expect(generator.prompts.last, contains('Change only the shoes'));
    expect(generator.prompts.last, contains('"white sneakers"'));
    expect(generator.photoUrls.last, 'https://example.com/look-1.jpg');

    await _tapKey(tester, 'look_step_keep');
    expect(find.text('Changed: Hair · Shoes'), findsOneWidget);
  });

  testWidgets('style idol styles after the person named', (tester) async {
    final generator = await _pumpPage(tester, scope: LookScope.outfit);

    await _chooseLookYouLove(tester, 'look_method_idol');
    await tester.enterText(
      find.byKey(const ValueKey('look_idol_field')),
      'Winky D',
    );
    await tester.pump();
    await _tapKey(tester, 'makeover_generate');

    expect(generator.prompts.single, contains('Winky D'));
  });

  testWidgets('style idol also accepts a vibe instead of a name', (
    tester,
  ) async {
    final generator = await _pumpPage(tester);
    final archetype = styleArchetypes.first;

    await _chooseLookYouLove(tester, 'look_method_idol');
    await _tapKey(tester, 'look_option_${archetype.name}');
    await _tapKey(tester, 'makeover_generate');

    expect(generator.prompts.single, contains(archetype.promptHint));
  });

  testWidgets('style twin copies the chosen look onto the user', (
    tester,
  ) async {
    const twin = 'https://example.com/friend.jpg';
    final generator = await _pumpPage(
      tester,
      scope: LookScope.outfit,
      initialTwinUrl: twin,
    );

    expect(_generateButton(tester).onPressed, isNotNull);
    await _tapKey(tester, 'makeover_generate');

    expect(generator.references.single, [twin]);
    expect(generator.prompts.single, contains('from the second image'));
  });

  testWidgets('editing a saved look cannot swap the photo', (tester) async {
    await _pumpPage(tester, editingPostId: 'post-1');

    expect(find.text('Edit look'), findsOneWidget);
    expect(find.text('Editing your look'), findsOneWidget);
    expect(find.byKey(const ValueKey('makeover_upload_photo')), findsNothing);
  });

  testWidgets('trending hides hair trends when only the outfit changes', (
    tester,
  ) async {
    await _pumpPage(tester, scope: LookScope.outfit);

    await _chooseLookYouLove(tester, 'look_method_trending');

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

    await _chooseLookYouLove(tester, 'look_method_weather');
    expect(find.textContaining('Harare'), findsOneWidget);

    await _tapKey(tester, 'makeover_generate');
    expect(generator.prompts.single, contains('28°C, sunny'));
  });

  testWidgets('"Style me like" opens on Style idol with the name filled in', (
    tester,
  ) async {
    await _pumpPage(tester, initialIdolName: 'Michelle Obama');

    expect(find.text('Style idol'), findsOneWidget);
    expect(find.text('Michelle Obama'), findsOneWidget);
  });
}
