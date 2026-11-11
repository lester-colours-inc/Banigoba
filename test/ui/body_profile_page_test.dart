import 'dart:typed_data';

import 'package:banigoba/modules/profile_details/models/body_profile.dart';
import 'package:banigoba/modules/profile_details/services/body_profile_service.dart';
import 'package:banigoba/modules/profile_details/views/body_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';

class _FakeStore implements BodyProfileStore {
  _FakeStore([this.stored = const BodyProfile()]);

  BodyProfile stored;
  final List<BodyProfile> saves = [];
  final List<String> deleted = [];
  int uploads = 0;

  @override
  Future<BodyProfile> load() async => stored;

  @override
  Future<void> save(BodyProfile profile) async {
    saves.add(profile);
    stored = profile;
  }

  @override
  Future<String> uploadPhoto(BodyPhoto photo, Uint8List bytes) async {
    uploads++;
    return 'https://example.com/${photo.name}-$uploads.jpg';
  }

  @override
  Future<void> deletePhoto(String url) async => deleted.add(url);
}

Future<void> _open(WidgetTester tester, _FakeStore store) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ToastificationWrapper(
      child: MaterialApp(
        home: BodyProfilePage(
          store: store,
          pickImage: (_, _) async => Uint8List(100),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _field(String key) => find.byKey(ValueKey(key));

void main() {
  testWidgets('shows saved details', (tester) async {
    await _open(
      tester,
      _FakeStore(
        const BodyProfile(
          clothingSize: 'M',
          shoeSize: '8',
          measurements: {BodyMeasurement.height: 172},
        ),
      ),
    );

    expect(find.text('172'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(
      tester.widget<ChoiceChip>(_field('clothing_size_M')).selected,
      isTrue,
    );
    expect(find.text('3 of 10 added'), findsOneWidget);
  });

  testWidgets('saves sizes and measurements', (tester) async {
    final store = _FakeStore();
    await _open(tester, store);

    await tester.ensureVisible(_field('clothing_size_L'));
    await tester.tap(_field('clothing_size_L'));
    await tester.enterText(_field('shoe_size'), '9,5');
    await tester.enterText(_field('measurement_height'), '180');
    await tester.enterText(_field('measurement_waist'), '84');
    await tester.enterText(_field('profile_notes'), 'Long arms');
    await tester.pump();
    expect(find.text('4 of 10 added'), findsOneWidget);

    await tester.ensureVisible(_field('save_profile_details'));
    await tester.tap(_field('save_profile_details'));
    await tester.pumpAndSettle();

    final saved = store.saves.single;
    expect(saved.clothingSize, 'L');
    expect(saved.shoeSize, '9.5');
    expect(saved[BodyMeasurement.height], 180);
    expect(saved[BodyMeasurement.waist], 84);
    expect(saved.notes, 'Long arms');
  });

  testWidgets('does not save an impossible measurement', (tester) async {
    final store = _FakeStore();
    await _open(tester, store);

    await tester.enterText(_field('measurement_height'), '17');
    await tester.tap(_field('save_profile_details'));
    await tester.pumpAndSettle();

    expect(store.saves, isEmpty);
    expect(find.text('Between 50 and 250 cm'), findsOneWidget);
  });

  testWidgets('saves a new photo straight away and keeps form edits unsaved', (
    tester,
  ) async {
    final store = _FakeStore(
      const BodyProfile(facePhotoUrl: 'https://example.com/old-face.jpg'),
    );
    await _open(tester, store);

    await tester.enterText(_field('measurement_height'), '170');
    await tester.tap(_field('photo_face'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    final saved = store.saves.single;
    expect(saved.facePhotoUrl, 'https://example.com/face-1.jpg');
    expect(saved[BodyMeasurement.height], isNull);
    expect(store.deleted, ['https://example.com/old-face.jpg']);
  });

  testWidgets('offers a hand photo alongside face and full body', (
    tester,
  ) async {
    await _open(
      tester,
      _FakeStore(
        const BodyProfile(handPhotoUrl: 'https://example.com/hand.jpg'),
      ),
    );

    expect(_field('photo_face'), findsOneWidget);
    expect(_field('photo_full_body'), findsOneWidget);
    expect(_field('photo_hand'), findsOneWidget);
    expect(find.text('1 of 10 added'), findsOneWidget);
  });

  testWidgets('asks before discarding unsaved changes', (tester) async {
    final store = _FakeStore();
    await tester.pumpWidget(
      ToastificationWrapper(
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => BodyProfilePage(store: store),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(_field('measurement_weight'), '70');
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
    expect(store.saves, isEmpty);
  });
}
