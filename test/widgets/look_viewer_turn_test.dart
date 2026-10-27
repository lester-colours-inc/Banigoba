// Verifies a saved look with angles opens in the turn-around viewer.
import 'package:banigoba/data/services/turn_around_service.dart';
import 'package:banigoba/ui/widgets/look_viewer_page.dart';
import 'package:banigoba/ui/widgets/turn_around_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a look with angles can be turned', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: LookViewerPage(
          imageUrl: 'front.png',
          turnViews: {TurnView.front: 'front.png', TurnView.back: 'back.png'},
        ),
      ),
    );

    expect(find.byType(TurnAroundViewer), findsOneWidget);
    expect(find.byKey(const ValueKey('look_viewer_image')), findsNothing);
  });

  testWidgets('a look without angles stays a zoomable picture', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LookViewerPage(imageUrl: '')),
    );

    expect(find.byType(TurnAroundViewer), findsNothing);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });
}
