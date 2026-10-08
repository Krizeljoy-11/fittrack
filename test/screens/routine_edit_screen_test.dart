import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fittrack/main.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/routine.dart';
import 'package:fittrack/screens/routines/routine_edit_screen.dart';

import '../fakes/auth_fakes.dart';
import '../fakes/routine_fakes.dart';

void main() {
  late FakeAuthService auth;
  late FakeRoutineRepository repo;
  late FakeExerciseRepository catalogRepo;

  setUp(() {
    auth = FakeAuthService()..emitUser(FakeUser());
    repo = FakeRoutineRepository();
    catalogRepo = FakeExerciseRepository(
      catalog: const <Exercise>[
        Exercise(id: 'e1', name: 'Bench Press', muscleGroup: 'Chest'),
        Exercise(id: 'e2', name: 'Squat', muscleGroup: 'Legs'),
      ],
    );
  });

  tearDown(() {
    auth.dispose();
    repo.dispose();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MyApp(
        authService: auth,
        routineRepository: repo,
        exerciseRepository: catalogRepo,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openCreate(WidgetTester tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New routine'));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pump();
  }

  /// Picks [exerciseName] from the catalog sheet and confirms the defaults.
  Future<void> addExercise(
    WidgetTester tester,
    String exerciseName, {
    bool confirmSettings = true,
  }) async {
    await tester.tap(find.widgetWithText(TextButton, 'Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(exerciseName));
    await tester.pumpAndSettle();
    if (confirmSettings) {
      await tester.tap(find.widgetWithText(TextButton, 'Done'));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('requires a routine name before saving', (tester) async {
    await openCreate(tester);

    await addExercise(tester, 'Bench Press');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Save routine'));
    await tester.pumpAndSettle();

    expect(find.text('Routine name is required.'), findsOneWidget);
    expect(repo.created, isEmpty);
  });

  testWidgets('requires at least one exercise before saving', (tester) async {
    await openCreate(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'Push Day');

    await tapVisible(tester, find.widgetWithText(FilledButton, 'Save routine'));
    await tester.pumpAndSettle();

    expect(
      find.text('Add at least one exercise to continue.'),
      findsOneWidget,
    );
    expect(repo.created, isEmpty);
  });

  testWidgets('explains when the catalog is empty', (tester) async {
    catalogRepo.catalog.clear();

    await openCreate(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('No exercises yet'), findsOneWidget);
    expect(
      find.textContaining('seeded outside the app'),
      findsOneWidget,
    );
  });

  testWidgets('tunes sets, reps and rest in the exercise dialog', (tester) async {
    await openCreate(tester);
    await addExercise(tester, 'Bench Press', confirmSettings: false);

    final Finder sets = find.widgetWithText(TextFormField, 'Sets');
    expect(find.text('Bench Press'), findsOneWidget);

    await tester.enterText(sets, '5');
    await tester.enterText(find.widgetWithText(TextFormField, 'Reps (optional)'), '8');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Rest in seconds'),
      '90',
    );
    await tester.tap(find.widgetWithText(TextButton, 'Done'));
    await tester.pumpAndSettle();

    expect(find.textContaining('5 set(s)'), findsOneWidget);
    expect(find.textContaining('8 rep(s)'), findsOneWidget);
    expect(find.textContaining('90 s rest'), findsOneWidget);
  });

  testWidgets('removes an added exercise from the list', (tester) async {
    await openCreate(tester);
    await addExercise(tester, 'Bench Press');
    await addExercise(tester, 'Squat');
    expect(find.text('Exercises (2)'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove exercise').first);
    await tester.pumpAndSettle();

    expect(find.text('Exercises (1)'), findsOneWidget);
    expect(find.text('Bench Press'), findsNothing);
    expect(find.text('Squat'), findsOneWidget);
  });

  testWidgets('creates a routine and returns to the list', (tester) async {
    await openCreate(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'Push Day');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Chest and triceps',
    );
    await tester.tap(find.text('Intermediate'));
    await tester.pump();
    await addExercise(tester, 'Bench Press');

    await tapVisible(tester, find.widgetWithText(FilledButton, 'Save routine'));
    await tester.pumpAndSettle();

    expect(repo.created, hasLength(1));
    final Routine written = repo.created.single;
    expect(written.name, 'Push Day');
    expect(written.description, 'Chest and triceps');
    expect(written.difficulty, RoutineDifficulty.intermediate);
    expect(written.exercises, hasLength(1));
    expect(written.exercises.single.exerciseName, 'Bench Press');
    expect(written.exercises.single.order, 0);

    expect(find.text('Routine created.'), findsOneWidget);
    expect(find.byType(RoutineEditScreen), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('prefills the form when editing an existing routine',
      (tester) async {
    repo.store['test-uid'] = <Routine>[
      Routine(
        id: 'r1',
        name: 'Push Day',
        description: 'Chest and triceps',
        difficulty: RoutineDifficulty.advanced,
        exercises: const <RoutineExercise>[
          RoutineExercise(
            exerciseId: 'e1',
            exerciseName: 'Bench Press',
            sets: 4,
            reps: 8,
          ),
        ],
      ),
    ];

    await pumpApp(tester);
    await tester.tap(find.text('Workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Push Day'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Edit routine'));
    await tester.pumpAndSettle();

    expect(find.text('Edit routine'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Push Day'), findsOneWidget);
    expect(find.text('Advanced'), findsOneWidget);
    expect(find.text('Exercises (1)'), findsOneWidget);
    expect(find.textContaining('4 set(s)'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Push Day v2');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Save routine'));
    await tester.pumpAndSettle();

    expect(repo.updated, hasLength(1));
    expect(repo.updated.single.id, 'r1');
    expect(repo.updated.single.name, 'Push Day v2');
    expect(find.text('Routine updated.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('keeps the screen open and reports a save failure',
      (tester) async {
    await openCreate(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'Broken Day');
    await addExercise(tester, 'Bench Press');
    repo.failWrite = true;

    await tapVisible(tester, find.widgetWithText(FilledButton, 'Save routine'));
    await tester.pumpAndSettle();

    expect(find.byType(RoutineEditScreen), findsOneWidget);
    expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
    expect(repo.created, isEmpty);
  });
}
