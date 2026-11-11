// The App Store safety screens: Terms must be ticked before continuing, and
// reporting asks for a reason before sending.
import 'package:banigoba/modules/settings/services/safety_service.dart';
import 'package:banigoba/modules/onboarding/views/terms_screen.dart';
import 'package:banigoba/modules/social/widgets/safety_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';

void main() {
  group('TermsScreen', () {
    testWidgets('Continue stays disabled until the person agrees', (
      tester,
    ) async {
      var accepted = 0;
      await tester.pumpWidget(
        ToastificationWrapper(
          child: MaterialApp(
            home: TermsScreen(onAccept: () async => accepted++),
          ),
        ),
      );

      final button = find.byKey(const ValueKey('terms_continue'));
      expect(tester.widget<FilledButton>(button).onPressed, isNull);

      await tester.tap(find.byKey(const ValueKey('terms_agree')));
      await tester.pump();
      await tester.tap(button);
      await tester.pump();

      expect(accepted, 1);
    });

    testWidgets('states the zero-tolerance rule', (tester) async {
      await tester.pumpWidget(
        ToastificationWrapper(
          child: MaterialApp(home: TermsScreen(onAccept: () async {})),
        ),
      );
      expect(find.textContaining('no tolerance'), findsOneWidget);
    });
  });

  group('showReportSheet', () {
    testWidgets('sends the chosen reason and thanks the reporter', (
      tester,
    ) async {
      ReportReason? sent;
      await tester.pumpWidget(
        ToastificationWrapper(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showReportSheet(
                    context,
                    subject: 'look',
                    onReport: (reason) async => sent = reason,
                  ),
                  child: const Text('Report'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();
      expect(find.text('Why are you reporting this look?'), findsOneWidget);

      await tester.tap(find.text(ReportReason.spam.label));
      await tester.pumpAndSettle();

      expect(sent, ReportReason.spam);
      expect(find.textContaining('within 24 hours'), findsOneWidget);
    });

    testWidgets('sends nothing when dismissed', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        ToastificationWrapper(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showReportSheet(
                    context,
                    subject: 'profile',
                    onReport: (_) async => calls++,
                  ),
                  child: const Text('Report'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(calls, 0);
    });
  });
}
