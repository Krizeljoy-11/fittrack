import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fittrack/main.dart';

import '../fakes/auth_fakes.dart';

void main() {
  late FakeAuthService fake;

  setUp(() {
    fake = FakeAuthService();
    fake.emitUser(FakeUser());
  });

  tearDown(() {
    fake.dispose();
  });

  Future<void> pumpShell(WidgetTester tester) async {
    await tester.pumpWidget(MyApp(authService: fake));
    await tester.pump();
  }

  NavigationBar bar(WidgetTester tester) =>
      tester.widget<NavigationBar>(find.byType(NavigationBar));

  testWidgets('shows all five destinations', (tester) async {
    await pumpShell(tester);

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Workout'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(bar(tester).selectedIndex, 0);
  });

  testWidgets('opens the selected tab and keeps the shell mounted',
      (tester) async {
    await pumpShell(tester);

    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();
    expect(bar(tester).selectedIndex, 2);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(bar(tester).selectedIndex, 4);
    expect(find.text('tester@example.com'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('start index can be requested by a named route', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(bar(tester).selectedIndex, 3);
  });

  testWidgets('signs out after confirmation and returns to login',
      (tester) async {
    await pumpShell(tester);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign out?'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(fake.signOutCalls, 0);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(fake.signOutCalls, 1);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
