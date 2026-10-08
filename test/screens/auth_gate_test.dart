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

  testWidgets('shows the login screen when there is no session', (tester) async {
    await tester.pumpWidget(MyApp(authService: fake));
    await tester.pump();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('shows the shell when a user is already signed in',
      (tester) async {
    fake.emitUser(FakeUser());
    await tester.pumpWidget(MyApp(authService: fake));
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);

    // Profile is the fifth tab, so bring it onstage before asserting identity.
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('tester@example.com'), findsOneWidget);
    expect(find.text('Test User'), findsOneWidget);
  });

  testWidgets('switches to the shell when a session appears', (tester) async {
    await tester.pumpWidget(MyApp(authService: fake));
    await tester.pump();
    expect(find.text('Welcome back'), findsOneWidget);

    fake.emitUser(FakeUser());
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);
  });

  testWidgets('returns to login when the session ends', (tester) async {
    fake.emitUser(FakeUser());
    await tester.pumpWidget(MyApp(authService: fake));
    await tester.pump();
    expect(find.byType(NavigationBar), findsOneWidget);

    fake.emitUser(null);
    await tester.pump();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
