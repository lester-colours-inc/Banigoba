// Verifies the auth screens expose every supported sign-in route.
//
// These tests do not talk to live Google/Facebook/Apple/Firebase providers.
// Instead, the screens receive a fake AuthService so taps can prove that each
// button routes to the correct provider method.
import 'package:banigoba/data/services/auth_service.dart';
import 'package:banigoba/ui/screens/auth/email_signin_screen.dart';
import 'package:banigoba/ui/screens/auth/email_signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sign-in authentication methods', () {
    // Email/password is handled directly by FirebaseAuth in the screen. This
    // validation test keeps the empty-form path runnable without Firebase init.
    testWidgets('email sign-in validates empty credentials', (tester) async {
      await _pumpAuthScreen(tester, EmailSignInScreen());

      await _tapVisible(tester, find.text('SIGN IN'));
      await tester.pump();

      expect(find.text('Enter your email and password'), findsOneWidget);
    });

    testWidgets('email sign-in rejects invalid email values', (tester) async {
      final auth = _RecordingAuthService();
      await _pumpAuthScreen(tester, EmailSignInScreen(authService: auth));

      await tester.enterText(find.byType(TextField).at(0), 'not-an-email');
      await tester.enterText(find.byType(TextField).at(1), 'correct-horse');
      await _tapVisible(tester, find.text('SIGN IN'));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(auth.emailSignIns, isEmpty);
    });

    testWidgets('email sign-in accepts valid email and password values', (
      tester,
    ) async {
      final auth = _RecordingAuthService();
      await _pumpAuthScreen(tester, EmailSignInScreen(authService: auth));

      await tester.enterText(
        find.byType(TextField).at(0),
        '  user@example.com  ',
      );
      await tester.enterText(find.byType(TextField).at(1), 'correct-horse');
      await _tapVisible(tester, find.text('SIGN IN'));
      await tester.pumpAndSettle();

      expect(auth.emailSignIns, [
        _EmailAttempt(email: 'user@example.com', password: 'correct-horse'),
      ]);
    });

    for (final provider in ['Google', 'Facebook', 'Apple']) {
      // Each provider button should call the matching AuthService method; the
      // fake below records the call instead of opening a real OAuth flow.
      testWidgets('$provider sign-in button calls AuthService', (tester) async {
        final auth = _RecordingAuthService();
        await _pumpAuthScreen(tester, EmailSignInScreen(authService: auth));

        await _tapVisible(tester, find.byTooltip(provider));
        await tester.pumpAndSettle();

        expect(auth.calls, [provider]);
      });
    }
  });

  group('sign-up authentication methods', () {
    // Sign-up validates local form state before trying to create a Firebase
    // user, so this remains a fast widget test.
    testWidgets('email sign-up validates empty account details', (
      tester,
    ) async {
      await _pumpAuthScreen(tester, EmailSignUpScreen());

      await _tapVisible(tester, find.text('SIGN UP'));
      await tester.pump();

      expect(find.text('Complete all account details'), findsOneWidget);
    });

    testWidgets('email sign-up rejects invalid account values', (tester) async {
      final auth = _RecordingAuthService();
      await _pumpAuthScreen(tester, EmailSignUpScreen(authService: auth));

      await tester.enterText(find.byType(TextField).at(0), 'Natasha');
      await tester.enterText(find.byType(TextField).at(1), 'bad-email');
      await tester.enterText(find.byType(TextField).at(2), 'secret1');
      await tester.enterText(find.byType(TextField).at(3), 'secret1');
      await _tapVisible(tester, find.text('SIGN UP'));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(auth.emailRegistrations, isEmpty);
    });

    testWidgets('email sign-up rejects short passwords', (tester) async {
      final auth = _RecordingAuthService();
      await _pumpAuthScreen(tester, EmailSignUpScreen(authService: auth));

      await tester.enterText(find.byType(TextField).at(0), 'Natasha');
      await tester.enterText(find.byType(TextField).at(1), 'user@example.com');
      await tester.enterText(find.byType(TextField).at(2), '12345');
      await tester.enterText(find.byType(TextField).at(3), '12345');
      await _tapVisible(tester, find.text('SIGN UP'));
      await tester.pump();

      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
      expect(auth.emailRegistrations, isEmpty);
    });

    testWidgets('email sign-up rejects password confirmation mismatch', (
      tester,
    ) async {
      final auth = _RecordingAuthService();
      await _pumpAuthScreen(tester, EmailSignUpScreen(authService: auth));

      await tester.enterText(find.byType(TextField).at(0), 'Natasha');
      await tester.enterText(find.byType(TextField).at(1), 'user@example.com');
      await tester.enterText(find.byType(TextField).at(2), 'secret1');
      await tester.enterText(find.byType(TextField).at(3), 'secret2');
      await tester.tap(find.byType(Checkbox));
      await _tapVisible(tester, find.text('SIGN UP'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(auth.emailRegistrations, isEmpty);
    });

    testWidgets('email sign-up accepts valid account values', (tester) async {
      final auth = _RecordingAuthService();
      await _pumpAuthScreen(tester, EmailSignUpScreen(authService: auth));

      await tester.enterText(find.byType(TextField).at(0), '  Natasha  ');
      await tester.enterText(
        find.byType(TextField).at(1),
        '  user@example.com  ',
      );
      await tester.enterText(find.byType(TextField).at(2), 'secret1');
      await tester.enterText(find.byType(TextField).at(3), 'secret1');
      await tester.tap(find.byType(Checkbox));
      await _tapVisible(tester, find.text('SIGN UP'));
      await tester.pumpAndSettle();

      expect(auth.emailRegistrations, [
        _EmailRegistration(
          name: 'Natasha',
          email: 'user@example.com',
          password: 'secret1',
        ),
      ]);
    });

    for (final provider in ['Google', 'Facebook', 'Apple']) {
      testWidgets('$provider sign-up button calls AuthService', (tester) async {
        final auth = _RecordingAuthService();
        await _pumpAuthScreen(tester, EmailSignUpScreen(authService: auth));

        await _tapVisible(tester, find.byTooltip(provider));
        await tester.pumpAndSettle();

        expect(auth.calls, [provider]);
      });
    }
  });
}

Future<void> _pumpAuthScreen(WidgetTester tester, Widget screen) async {
  // The auth pages are vertically rich. Use a stable viewport so buttons are
  // reachable and overflow assertions catch genuine layout regressions.
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 1200);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });

  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pump();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  // Some controls sit below the first fold; scroll them into view before tap.
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

class _RecordingAuthService extends AuthService {
  // Minimal fake used to assert provider routing without provider SDK calls.
  final calls = <String>[];
  final emailSignIns = <_EmailAttempt>[];
  final emailRegistrations = <_EmailRegistration>[];

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    emailSignIns.add(_EmailAttempt(email: email, password: password));
  }

  @override
  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    emailRegistrations.add(
      _EmailRegistration(name: name, email: email, password: password),
    );
  }

  @override
  Future<UserCredential?> signInWithGoogle() async {
    calls.add('Google');
    return null;
  }

  @override
  Future<UserCredential?> signInWithFacebook() async {
    calls.add('Facebook');
    return null;
  }

  @override
  Future<UserCredential?> signInWithApple() async {
    calls.add('Apple');
    return null;
  }
}

class _EmailAttempt {
  const _EmailAttempt({required this.email, required this.password});

  final String email;
  final String password;

  @override
  bool operator ==(Object other) {
    return other is _EmailAttempt &&
        other.email == email &&
        other.password == password;
  }

  @override
  int get hashCode => Object.hash(email, password);

  @override
  String toString() => 'EmailAttempt(email: $email, password: $password)';
}

class _EmailRegistration {
  const _EmailRegistration({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  @override
  bool operator ==(Object other) {
    return other is _EmailRegistration &&
        other.name == name &&
        other.email == email &&
        other.password == password;
  }

  @override
  int get hashCode => Object.hash(name, email, password);

  @override
  String toString() {
    return 'EmailRegistration(name: $name, email: $email, password: $password)';
  }
}
