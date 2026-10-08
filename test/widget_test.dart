// FitTrack root smoke tests.
//
// The Phase 0 root view was intentionally replaced by the Phase 1 AuthGate,
// so the first test now asserts the sign-in screen instead. The auth-provider
// test below is unchanged from Phase 0.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fittrack/main.dart';
import 'package:fittrack/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots into the sign-in screen when Firebase is unconfigured',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('FitTrack'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.textContaining('Firebase is not configured yet'),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsNothing);
  });

  test('AuthProvider fails gracefully when Firebase is not configured', () async {
    final AuthProvider auth = AuthProvider();

    expect(auth.isConfigured, isFalse);
    expect(auth.isSignedIn, isFalse);

    final bool ok = await auth.signIn(
      email: 'someone@example.com',
      password: 'hunter2hunter2',
    );

    expect(ok, isFalse);
    expect(auth.isBusy, isFalse);
    expect(auth.errorMessage, isNotNull);

    auth.dispose();
  });
}
