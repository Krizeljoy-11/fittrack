import 'package:flutter_test/flutter_test.dart';

import 'package:fittrack/main.dart';
import 'package:fittrack/models/routine.dart';

import '../fakes/auth_fakes.dart';
import '../fakes/routine_fakes.dart';

void main() {
  late FakeAuthService auth;
  late FakeRoutineRepository repo;
  late FakeExerciseRepository catalogRepo;

  setUp(() {
    auth = FakeAuthService()..emitUser(FakeUser());
    repo = FakeRoutineRepository();
    catalogRepo = FakeExerciseRepository();
  });

  tearDown(() {
    auth.dispose();
    repo.dispose();
  });

  Future<void> openWorkout(WidgetTester tester) async {
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
  }

  testWidgets('shows the empty state and a create action when there are '
      'no routines', (tester) async {
    await openWorkout(tester);

    expect(find.text('No routines yet'), findsOneWidget);
    expect(find.text('New routine'), findsOneWidget);
  });

  testWidgets('lists the member routines from the live stream',
      (tester) async {
    repo.store['test-uid'] = <Routine>[
      Routine(
        id: 'r1',
        name: 'Push Day',
        description: 'Chest and triceps',
        difficulty: RoutineDifficulty.intermediate,
        exercises: const <RoutineExercise>[
          RoutineExercise(exerciseId: 'e1', exerciseName: 'Bench Press'),
          RoutineExercise(exerciseId: 'e2', exerciseName: 'Overhead Press'),
        ],
      ),
      Routine(
        id: 'r2',
        name: 'Leg Day',
        difficulty: RoutineDifficulty.advanced,
        exercises: const <RoutineExercise>[
          RoutineExercise(exerciseId: 'e3', exerciseName: 'Squat'),
        ],
      ),
    ];

    await openWorkout(tester);

    expect(find.text('Push Day'), findsOneWidget);
    expect(find.text('Leg Day'), findsOneWidget);
    expect(find.text('Intermediate'), findsOneWidget);
    expect(find.text('Advanced'), findsOneWidget);
    expect(find.text('Chest and triceps'), findsOneWidget);
    expect(find.text('2 exercise(s) · 6 set(s)'), findsOneWidget);
    expect(find.text('1 exercise(s) · 3 set(s)'), findsOneWidget);
    expect(repo.watchCalls, <String>['test-uid']);
  });

  testWidgets('opens the routine detail screen from a card', (tester) async {
    repo.store['test-uid'] = <Routine>[
      Routine(
        id: 'r1',
        name: 'Push Day',
        exercises: const <RoutineExercise>[
          RoutineExercise(exerciseId: 'e1', exerciseName: 'Bench Press'),
        ],
      ),
    ];

    await openWorkout(tester);
    await tester.tap(find.text('Push Day'));
    await tester.pumpAndSettle();

    expect(find.text('Routine details'), findsOneWidget);
    expect(find.text('Edit routine'), findsOneWidget);
  });

  testWidgets('the create action opens a blank routine editor', (tester) async {
    await openWorkout(tester);
    await tester.tap(find.text('New routine'));
    await tester.pumpAndSettle();

    expect(find.text('New routine'), findsNWidgets(1));
    expect(find.text('Save routine'), findsOneWidget);
    expect(find.text('No exercises yet. Tap Add to pick from the catalog.'),
        findsOneWidget);
  });

  testWidgets('surfaces a stream failure as a friendly empty state',
      (tester) async {
    repo.failWatch = true;

    await openWorkout(tester);

    expect(find.text('Routines unavailable'), findsOneWidget);
    expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
  });

  testWidgets('explains when Firebase is not configured', (tester) async {
    repo.configured = false;

    await openWorkout(tester);

    expect(
      find.textContaining('Firebase is not configured yet'),
      findsOneWidget,
    );
    expect(find.text('No routines yet'), findsOneWidget);
    expect(repo.watchCalls, isEmpty);
  });

  testWidgets('reflects a routine deleted while the list is open',
      (tester) async {
    repo.store['test-uid'] = <Routine>[
      Routine(
        id: 'r1',
        name: 'Push Day',
        exercises: const <RoutineExercise>[
          RoutineExercise(exerciseId: 'e1', exerciseName: 'Bench Press'),
        ],
      ),
    ];

    await openWorkout(tester);
    expect(find.text('Push Day'), findsOneWidget);

    repo.store['test-uid']!.clear();
    repo.emit('test-uid');
    await tester.pumpAndSettle();

    expect(find.text('Push Day'), findsNothing);
    expect(find.text('No routines yet'), findsOneWidget);
  });
}
