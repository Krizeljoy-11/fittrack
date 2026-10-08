import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fittrack/main.dart';

import '../fakes/auth_fakes.dart';

void main() {
  late FakeAuthService fake;

  setUp(() {
    fake = FakeAuthService();
  });

  tearDown(() {
    fake.dispose();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(MyApp(authService: fake));
    await tester.pump();
  }

  Future<void> enterCredentials(
    WidgetTester tester, {
    String email = 'tester@example.com',
    String password = 'password123',
  }) async {
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.pump();
  }

  testWidgets('renders the sign-in form and its entry points', (tester) async {
    await pumpApp(tester);

    expect(find.text('FitTrack'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Create one'), findsOneWidget);
  });

  testWidgets('shows the Firebase configuration notice when unconfigured',
      (tester) async {
    fake.configured = false;
    await pumpApp(tester);

    expect(
      find.textContaining('Firebase is not configured yet'),
      findsOneWidget,
    );
  });

  testWidgets('validates an empty form and does not call the service',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
    expect(fake.signInEmails, isEmpty);
  });

  testWidgets('rejects a malformed email before submitting', (tester) async {
    await pumpApp(tester);
    await enterCredentials(tester, email: 'not-an-email');

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(fake.signInEmails, isEmpty);
  });

  testWidgets('shows an error banner when authentication fails',
      (tester) async {
    fake.failSignIn = true;
    await pumpApp(tester);
    await enterCredentials(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    expect(fake.signInEmails, hasLength(1));
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('signs in with valid credentials and opens the shell',
      (tester) async {
    await pumpApp(tester);
    await enterCredentials(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    await tester.pump();

    expect(fake.signInEmails, <String>['tester@example.com']);
    expect(find.text('Welcome back'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('toggles password visibility', (tester) async {
    await pumpApp(tester);

    TextField passwordField =
        tester.widget<TextField>(find.byType(TextField).at(1));
    expect(passwordField.obscureText, isTrue);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    passwordField = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(passwordField.obscureText, isFalse);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('navigates to the register and reset screens', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Create one'));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset password'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Send reset link'), findsOneWidget);
  });
}
