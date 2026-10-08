import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fittrack/main.dart';
import 'package:fittrack/models/app_user.dart';
import 'package:fittrack/models/fitness_goal.dart';

import '../fakes/auth_fakes.dart';
import '../fakes/profile_fakes.dart';

void main() {
  late FakeAuthService auth;
  late FakeUserRepository repo;

  setUp(() {
    auth = FakeAuthService()..emitUser(FakeUser());
    repo = FakeUserRepository();
  });

  tearDown(() {
    auth.dispose();
  });

  Future<void> openProfile(WidgetTester tester) async {
    await tester.pumpWidget(MyApp(authService: auth, profileRepository: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the loaded profile header and vitals', (tester) async {
    repo.store['test-uid'] = AppUser(
      uid: 'test-uid',
      email: 'tester@example.com',
      displayName: 'Ada Lifts',
      height: 175,
      weight: 68.5,
      fitnessGoal: FitnessGoal.strength,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    await openProfile(tester);

    expect(find.text('Ada Lifts'), findsOneWidget);
    expect(find.text('tester@example.com'), findsOneWidget);
    expect(find.text('Strength'), findsOneWidget);
    expect(find.text('175 cm'), findsOneWidget);
    expect(find.text('68.5 kg'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Edit Profile'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Sign out'), findsOneWidget);
    expect(repo.getCalls, <String>['test-uid']);
  });

  testWidgets('shows placeholders until the vitals are filled in',
      (tester) async {
    repo.store['test-uid'] = AppUser(
      uid: 'test-uid',
      email: 'tester@example.com',
    );

    await openProfile(tester);

    // Falls back to the Firebase Auth display name when the profile has none.
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('Not set'), findsNWidgets(2));
    expect(find.text('tester@example.com'), findsOneWidget);
  });

  testWidgets('surfaces a load failure as an error banner', (tester) async {
    repo.failGet = true;

    await openProfile(tester);

    expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Edit Profile'), findsOneWidget);
  });

  testWidgets('explains when Firebase is not configured', (tester) async {
    repo.configured = false;

    await openProfile(tester);

    expect(
      find.textContaining('Firebase is not configured yet'),
      findsOneWidget,
    );
    expect(find.text('Test User'), findsOneWidget);
    expect(repo.getCalls, isEmpty);
  });

  testWidgets('opens the Edit Profile screen', (tester) async {
    repo.store['test-uid'] = AppUser(
      uid: 'test-uid',
      email: 'tester@example.com',
      displayName: 'Ada Lifts',
      fitnessGoal: FitnessGoal.endurance,
    );

    await openProfile(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Edit Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Save changes'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
  });

  testWidgets('keeps the sign-out confirmation flow', (tester) async {
    await openProfile(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign out?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(auth.signOutCalls, 0);
  });
}
