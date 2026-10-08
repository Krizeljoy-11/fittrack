import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fittrack/core/constants/app_routes.dart';
import 'package:fittrack/main.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/routine.dart';
import 'package:fittrack/screens/routines/routine_detail_screen.dart';

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
      ],
    );
  });

  tearDown(() {
    auth.dispose();
    repo.dispose();
  });

  Routine storedRoutine() {
    return Routine(
      id: 'r1',
      name: 'Push Day',
      description: 'Chest and triceps',
      difficulty: RoutineDifficulty.intermediate,
      exercises: const <RoutineExercise>[
        RoutineExercise(
          exerciseId: 'e1',
          exerciseName: 'Bench Press',
          sets: 3,
          reps: 10,
          restSeconds: 90,
        ),
        RoutineExercise(
          exerciseId: 'e2',
          exerciseName: 'Overhead Press',
          sets: 4,
          durationSeconds: 45,
          restSeconds: 60,
        ),
      ],
    );
  }

  Future<void> openDetail(WidgetTester tester) async {
    repo.store['test-uid'] = <Routine>[storedRoutine()];

    await tester.pumpWidget(
      MyApp(
        authService: auth,
        routineRepository: repo,
        exerciseRepository: catalogRepo,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Push Day'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the routine header and exercise list', (tester) async {
    await openDetail(tester);

    expect(find.text('Routine details'), findsOneWidget);
    expect(find.text('Intermediate'), findsOneWidget);
    expect(find.text('Chest and triceps'), findsOneWidget);
    expect(find.text('2 exercise(s) · 7 working set(s)'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Overhead Press'), findsOneWidget);
    expect(find.textContaining('3 set(s) · 10 rep(s) · 90 s rest'),
        findsOneWidget);
    expect(find.textContaining('4 set(s) · 45 s work'), findsOneWidget);
  });

  testWidgets('shows a friendly state when the routine is gone', (tester) async {
    await tester.pumpWidget(
      MyApp(
        authService: auth,
        routineRepository: repo,
        exerciseRepository: catalogRepo,
      ),
    );
    await tester.pumpAndSettle();

    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pushNamed(AppRoutes.routineDetail, arguments: 'missing');
    await tester.pumpAndSettle();

    expect(find.text('Routine not found'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
  });

  testWidgets('edit action opens the routine editor', (tester) async {
    await openDetail(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Edit routine'));
    await tester.pumpAndSettle();

    expect(find.text('Edit routine'), findsNWidgets(1));
    expect(find.text('Save routine'), findsOneWidget);
  });

  testWidgets('deleting asks for confirmation and cancels cleanly',
      (tester) async {
    await openDetail(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Delete routine'));
    await tester.pumpAndSettle();

    expect(find.text('Delete routine?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(RoutineDetailScreen), findsOneWidget);
    expect(repo.deleted, isEmpty);
  });

  testWidgets('deleting removes the routine and returns to the list',
      (tester) async {
    await openDetail(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Delete routine'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repo.deleted, <String>['r1']);
    expect(find.byType(RoutineDetailScreen), findsNothing);
    expect(find.text('Routine deleted.'), findsOneWidget);
    expect(find.text('No routines yet'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('a failed delete keeps the detail screen open', (tester) async {
    await openDetail(tester);
    repo.failWrite = true;

    await tester.tap(find.widgetWithText(OutlinedButton, 'Delete routine'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.byType(RoutineDetailScreen), findsOneWidget);
    expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
    expect(repo.deleted, isEmpty);
  });
}
