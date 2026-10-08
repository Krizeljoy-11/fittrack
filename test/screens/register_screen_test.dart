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

  Future<void> openRegister(WidgetTester tester) async {
    await tester.pumpWidget(MyApp(authService: fake));
    await tester.pump();
    await tester.tap(find.text('Create one'));
    await tester.pumpAndSettle();
  }

  Future<void> fillForm(
    WidgetTester tester, {
    String email = 'newbie@example.com',
    String password = 'password123',
    String confirm = 'password123',
  }) async {
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.enterText(find.byType(TextFormField).at(2), confirm);
    await tester.pump();
  }

  testWidgets('renders the three registration fields', (tester) async {
    await openRegister(tester);

    expect(find.text('Join FitTrack'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text('Create account'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Create account'),
      findsOneWidget,
    );
    expect(find.text('Already have an account?'), findsOneWidget);
  });

  testWidgets('validates an empty form without calling the service',
      (tester) async {
    await openRegister(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();

    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
    expect(find.text('Please confirm your password.'), findsOneWidget);
    expect(fake.registerEmails, isEmpty);
  });

  testWidgets('rejects mismatched passwords', (tester) async {
    await openRegister(tester);
    await fillForm(tester, confirm: 'password456');

    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();

    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(fake.registerEmails, isEmpty);
  });

  testWidgets('shows the Firebase error returned by the service',
      (tester) async {
    fake.failRegister = true;
    await openRegister(tester);
    await fillForm(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('An account already exists with that email.'),
      findsOneWidget,
    );
    expect(fake.registerEmails, hasLength(1));
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('creates the account and lands in the shell', (tester) async {
    await openRegister(tester);
    await fillForm(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();
    await tester.pump();

    expect(fake.registerEmails, <String>['newbie@example.com']);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);
  });

  testWidgets('returns to sign-in without registering', (tester) async {
    await openRegister(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(fake.registerEmails, isEmpty);
  });
}
