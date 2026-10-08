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

  Future<void> openReset(WidgetTester tester) async {
    await tester.pumpWidget(MyApp(authService: fake));
    await tester.pump();
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the reset form', (tester) async {
    await openReset(tester);

    expect(find.text('Reset password'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Send reset link'),
      findsOneWidget,
    );
    expect(find.text('Back to sign in'), findsOneWidget);
  });

  testWidgets('validates an empty form without calling the service',
      (tester) async {
    await openReset(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Send reset link'));
    await tester.pump();

    expect(find.text('Email is required.'), findsOneWidget);
    expect(fake.resetEmails, isEmpty);
  });

  testWidgets('confirms a sent link and records the email', (tester) async {
    await openReset(tester);
    await tester.enterText(find.byType(TextFormField), 'tester@example.com');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Send reset link'));
    await tester.pump();
    await tester.pump();

    expect(fake.resetEmails, <String>['tester@example.com']);
    expect(
      find.textContaining('Reset link sent. Check your inbox and spam folder.'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(FilledButton, 'Send again'),
      findsOneWidget,
    );
    expect(find.text('Email is required.'), findsNothing);
  });

  testWidgets('shows the Firebase error when the reset fails', (tester) async {
    fake.failReset = true;
    await openReset(tester);
    await tester.enterText(find.byType(TextFormField), 'missing@example.com');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Send reset link'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Email or password is incorrect.'),
      findsOneWidget,
    );
    expect(find.textContaining('Reset link sent.'), findsNothing);
  });

  testWidgets('returns to sign-in', (tester) async {
    await openReset(tester);

    await tester.tap(find.text('Back to sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });
}
