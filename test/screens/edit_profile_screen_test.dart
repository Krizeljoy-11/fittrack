import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fittrack/main.dart';
import 'package:fittrack/models/app_user.dart';
import 'package:fittrack/models/fitness_goal.dart';
import 'package:fittrack/screens/profile/edit_profile_screen.dart';

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

  /// Signs in, opens the Profile tab and pushes the Edit Profile screen.
  ///
  /// The surface is made tall enough to show the whole form, and [tapVisible]
  /// scrolls before tapping, so tests never depend on the button falling in
  /// the default 800x600 window.
  Future<void> openEditor(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MyApp(authService: auth, profileRepository: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Edit Profile'));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pump();
  }

  AppUser storedProfile() {
    return AppUser(
      uid: 'test-uid',
      email: 'tester@example.com',
      displayName: 'Ada Lifts',
      height: 175,
      weight: 68,
      fitnessGoal: FitnessGoal.endurance,
      createdAt: DateTime(2020, 1, 1),
      updatedAt: DateTime(2020, 1, 1),
    );
  }

  Finder onScreen(Finder finder) => find.descendant(
        of: find.byType(EditProfileScreen),
        matching: finder,
      );

  testWidgets('prefills the editable fields and shows a read-only email',
      (tester) async {
    repo.store['test-uid'] = storedProfile();

    await openEditor(tester);

    // Email is displayed, not editable: three fields only.
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(onScreen(find.text('Ada Lifts')), findsOneWidget);
    expect(onScreen(find.text('175')), findsOneWidget);
    expect(onScreen(find.text('68')), findsOneWidget);
    expect(onScreen(find.text('tester@example.com')), findsOneWidget);
    expect(onScreen(find.text('Endurance')), findsOneWidget);
    expect(onScreen(find.text('Save changes')), findsOneWidget);
  });

  testWidgets('requires a display name and a fitness goal before saving',
      (tester) async {
    repo.store['test-uid'] = AppUser(
      uid: 'test-uid',
      email: 'tester@example.com',
    );

    await openEditor(tester);
    await tester.enterText(find.byType(TextFormField).at(0), '');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Save changes'));

    expect(find.text('Display name is required.'), findsOneWidget);
    expect(find.text('Choose a fitness goal to continue.'), findsOneWidget);
    expect(repo.updated, isEmpty);
    expect(repo.created, isEmpty);
  });

  testWidgets('validates numeric height and weight input', (tester) async {
    repo.store['test-uid'] = storedProfile();

    await openEditor(tester);
    await tester.enterText(find.byType(TextFormField).at(1), 'tall');
    await tester.enterText(find.byType(TextFormField).at(2), '900');
    await tester.pump();

    expect(find.text('Height must be a number.'), findsOneWidget);
    expect(find.text('Weight must be at most 400.0.'), findsOneWidget);
    expect(repo.updated, isEmpty);
  });

  testWidgets('saves the edited profile and returns to the shell',
      (tester) async {
    repo.store['test-uid'] = storedProfile();

    await openEditor(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'Ada Lifts Jr');
    await tester.enterText(find.byType(TextFormField).at(1), '176');
    await tester.enterText(find.byType(TextFormField).at(2), '69.5');
    await tester.tap(find.text('Strength'));
    await tester.pump();

    await tapVisible(tester, find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(repo.updated, hasLength(1));
    final AppUser written = repo.updated.single;
    expect(written.uid, 'test-uid');
    expect(written.email, 'tester@example.com');
    expect(written.displayName, 'Ada Lifts Jr');
    expect(written.height, 176);
    expect(written.weight, 69.5);
    expect(written.fitnessGoal, FitnessGoal.strength);
    expect(written.createdAt, DateTime(2020, 1, 1));

    expect(find.text('Profile updated.'), findsOneWidget);
    expect(find.byType(EditProfileScreen), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);

    // Let the SnackBar dismiss so no timer outlives the test.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('keeps the screen open and reports a save failure',
      (tester) async {
    repo.store['test-uid'] = storedProfile();

    await openEditor(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'Broken Save');
    repo.failWrite = true;

    await tapVisible(tester, find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
    expect(repo.updated, isEmpty);
    expect(find.text('Profile updated.'), findsNothing);
  });

  testWidgets('signing in without a profile still opens a usable form',
      (tester) async {
    // No stored document: the first load seeds it from the auth record.
    await openEditor(tester);

    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(onScreen(find.text('tester@example.com')), findsOneWidget);
    expect(repo.created, hasLength(1));

    await tester.enterText(find.byType(TextFormField).at(0), 'Fresh Start');
    await tester.tap(find.text('General Fitness'));
    await tester.pump();
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Profile updated.'), findsOneWidget);
    expect(repo.updated, hasLength(1));
    expect(repo.updated.single.displayName, 'Fresh Start');
    expect(repo.updated.single.fitnessGoal, FitnessGoal.generalFitness);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
