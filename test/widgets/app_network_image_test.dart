import 'package:banigoba/ui/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('the loader shows download progress once it is known', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const ImageLoader(progress: 0.4)));

    final ring = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(ring.value, 0.4);
  });

  testWidgets('a missing image shows the custom fallback', (tester) async {
    await tester.pumpWidget(
      _host(const AppNetworkImage('  ', fallback: Text('no picture'))),
    );

    expect(find.text('no picture'), findsOneWidget);
  });

  testWidgets('a missing image shows the fallback icon by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const AppNetworkImage('', fallbackIcon: Icons.person_outline)),
    );

    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });
}
