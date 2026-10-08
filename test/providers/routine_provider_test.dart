import 'package:flutter_test/flutter_test.dart';

import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/routine.dart';
import 'package:fittrack/providers/routine_provider.dart';

import '../fakes/routine_fakes.dart';

void main() {
  late FakeRoutineRepository repo;
  late FakeExerciseRepository catalogRepo;
  late RoutineProvider provider;

  Routine routine({String id = 'r1', String name = 'Push Day'}) {
    return Routine(
      id: id,
      name: name,
      description: 'Chest and triceps',
      difficulty: RoutineDifficulty.intermediate,
      exercises: const <RoutineExercise>[
        RoutineExercise(
          exerciseId: 'e1',
          exerciseName: 'Bench Press',
          sets: 3,
          reps: 10,
        ),
      ],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  setUp(() {
    repo = FakeRoutineRepository();
    catalogRepo = FakeExerciseRepository(
      catalog: const <Exercise>[
        Exercise(id: 'e1', name: 'Bench Press', muscleGroup: 'Chest'),
        Exercise(id: 'e2', name: 'Squat', muscleGroup: 'Legs'),
      ],
    );
    provider = RoutineProvider(
      repository: repo,
      exerciseRepository: catalogRepo,
    );
  });

  tearDown(() {
    provider.dispose();
    repo.dispose();
  });

  group('watch', () {
    test('delivers the live routine list for the member', () async {
      repo.store['u1'] = <Routine>[routine()];

      provider.watch('u1');
      await Future<void>.delayed(Duration.zero);

      expect(repo.watchCalls, <String>['u1']);
      expect(provider.routines, hasLength(1));
      expect(provider.routines.single.name, 'Push Day');
      expect(provider.uid, 'u1');
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('reflects later stream emissions', () async {
      provider.watch('u1');
      await Future<void>.delayed(Duration.zero);
      expect(provider.routines, isEmpty);

      repo.store['u1'] = <Routine>[routine()];
      repo.emit('u1');
      await Future<void>.delayed(Duration.zero);

      expect(provider.routines, hasLength(1));
    });

    test('reports the loading state while the stream is silent', () async {
      provider.watch('u1');

      expect(provider.isLoading, isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(provider.isLoading, isFalse);
    });

    test('surfaces a stream failure without throwing', () async {
      repo.failWatch = true;

      provider.watch('u1');
      await Future<void>.delayed(Duration.zero);

      expect(provider.errorMessage, 'Something went wrong. Please try again.');
      expect(provider.routines, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('ignores a repeated watch for the same uid', () async {
      repo.store['u1'] = <Routine>[routine()];

      provider.watch('u1');
      await Future<void>.delayed(Duration.zero);
      provider.watch('u1');
      await Future<void>.delayed(Duration.zero);

      expect(repo.watchCalls, <String>['u1']);
    });

    test('resubscribes when the uid changes', () async {
      provider.watch('u1');
      await Future<void>.delayed(Duration.zero);
      provider.watch('u2');
      await Future<void>.delayed(Duration.zero);

      expect(repo.watchCalls, <String>['u1', 'u2']);
      expect(provider.uid, 'u2');
      expect(provider.routines, isEmpty);
    });

    test('stays quiet when Firebase is not configured', () async {
      repo.configured = false;

      provider.watch('u1');
      await Future<void>.delayed(Duration.zero);

      expect(provider.isConfigured, isFalse);
      expect(provider.routines, isEmpty);
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, isFalse);
      expect(repo.watchCalls, isEmpty);
    });

    test('clearError clears a reported failure', () async {
      repo.failWatch = true;
      provider.watch('u1');
      await Future<void>.delayed(Duration.zero);
      expect(provider.errorMessage, isNotNull);

      repo.failWatch = false;
      provider.clearError();

      expect(provider.errorMessage, isNull);
    });
  });

  group('routineById', () {
    test('finds a loaded routine', () async {
      repo.store['u1'] = <Routine>[routine(id: 'r9', name: 'Leg Day')];

      provider.watch('u1');
      await Future<void>.delayed(Duration.zero);

      expect(provider.routineById('r9')?.name, 'Leg Day');
      expect(provider.routineById('missing'), isNull);
    });
  });

  group('saveRoutine', () {
    test('creates a new routine with exercises ordered by position',
        () async {
      final bool saved = await provider.saveRoutine(
        uid: 'u1',
        name: '  Pull Day  ',
        description: 'Back and biceps',
        difficulty: RoutineDifficulty.advanced,
        exercises: const <RoutineExercise>[
          RoutineExercise(
            exerciseId: 'e2',
            exerciseName: 'Row',
            sets: 4,
            order: 7,
          ),
          RoutineExercise(
            exerciseId: 'e1',
            exerciseName: 'Curl',
            sets: 3,
            order: 2,
          ),
        ],
      );

      expect(saved, isTrue);
      expect(repo.created, hasLength(1));
      final Routine written = repo.created.single;
      expect(written.name, 'Pull Day');
      expect(written.description, 'Back and biceps');
      expect(written.difficulty, RoutineDifficulty.advanced);
      expect(written.exercises.map((RoutineExercise e) => e.order),
          <int>[0, 1]);
      expect(written.createdAt, isNotNull);
      expect(provider.successMessage, 'Routine created.');
      expect(provider.errorMessage, isNull);
      expect(provider.isSaving, isFalse);
    });

    test('updates an existing routine and keeps its createdAt', () async {
      repo.store['u1'] = <Routine>[routine(id: 'r1')];

      final bool saved = await provider.saveRoutine(
        uid: 'u1',
        routineId: 'r1',
        name: 'Push Day v2',
        description: 'Updated',
        difficulty: RoutineDifficulty.advanced,
        exercises: const <RoutineExercise>[
          RoutineExercise(exerciseId: 'e1', exerciseName: 'Bench Press'),
        ],
      );

      expect(saved, isTrue);
      expect(repo.updated, hasLength(1));
      final Routine written = repo.updated.single;
      expect(written.id, 'r1');
      expect(written.name, 'Push Day v2');
      expect(written.createdAt, DateTime(2026, 1, 1));
      expect(provider.successMessage, 'Routine updated.');
      expect(repo.created, isEmpty);
    });

    test('reports the saving state while the write is in flight', () async {
      repo.writeDelay = const Duration(milliseconds: 40);

      final Future<bool> pending = provider.saveRoutine(
        uid: 'u1',
        name: 'Slow Day',
        description: '',
        difficulty: RoutineDifficulty.beginner,
        exercises: const <RoutineExercise>[
          RoutineExercise(exerciseId: 'e1', exerciseName: 'Bench Press'),
        ],
      );
      expect(provider.isSaving, isTrue);

      final bool saved = await pending;
      expect(saved, isTrue);
      expect(provider.isSaving, isFalse);
    });

    test('keeps the list and reports a write failure', () async {
      repo.failWrite = true;

      final bool saved = await provider.saveRoutine(
        uid: 'u1',
        name: 'Broken Day',
        description: '',
        difficulty: RoutineDifficulty.beginner,
        exercises: const <RoutineExercise>[
          RoutineExercise(exerciseId: 'e1', exerciseName: 'Bench Press'),
        ],
      );

      expect(saved, isFalse);
      expect(repo.created, isEmpty);
      expect(repo.updated, isEmpty);
      expect(provider.errorMessage, 'Something went wrong. Please try again.');
      expect(provider.successMessage, isNull);
      expect(provider.isSaving, isFalse);
    });

    test('refuses to save when Firebase is not configured', () async {
      repo.configured = false;

      final bool saved = await provider.saveRoutine(
        uid: 'u1',
        name: 'No Backend',
        description: '',
        difficulty: RoutineDifficulty.beginner,
        exercises: const <RoutineExercise>[
          RoutineExercise(exerciseId: 'e1', exerciseName: 'Bench Press'),
        ],
      );

      expect(saved, isFalse);
      expect(provider.errorMessage,
          contains('Firebase is not configured yet'));
      expect(repo.created, isEmpty);
      expect(provider.isSaving, isFalse);
    });
  });

  group('deleteRoutine', () {
    test('deletes the routine and reports success', () async {
      repo.store['u1'] = <Routine>[routine(id: 'r1')];

      final bool deleted = await provider.deleteRoutine(
        uid: 'u1',
        routineId: 'r1',
      );

      expect(deleted, isTrue);
      expect(repo.deleted, <String>['r1']);
      expect(provider.successMessage, 'Routine deleted.');
      expect(provider.errorMessage, isNull);
    });

    test('reports a failure without throwing', () async {
      repo.failWrite = true;

      final bool deleted = await provider.deleteRoutine(
        uid: 'u1',
        routineId: 'r1',
      );

      expect(deleted, isFalse);
      expect(repo.deleted, isEmpty);
      expect(provider.errorMessage, 'Something went wrong. Please try again.');
    });

    test('refuses to delete when Firebase is not configured', () async {
      repo.configured = false;

      final bool deleted = await provider.deleteRoutine(
        uid: 'u1',
        routineId: 'r1',
      );

      expect(deleted, isFalse);
      expect(provider.errorMessage,
          contains('Firebase is not configured yet'));
      expect(repo.deleted, isEmpty);
    });
  });

  group('loadCatalog', () {
    test('loads the shared exercise catalog', () async {
      await provider.loadCatalog();

      expect(provider.catalog.map((Exercise e) => e.name),
          <String>['Bench Press', 'Squat']);
      expect(provider.isLoadingCatalog, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('reports a catalog failure without throwing', () async {
      catalogRepo.failFetch = true;

      await provider.loadCatalog();

      expect(provider.catalog, isEmpty);
      expect(provider.errorMessage, 'Something went wrong. Please try again.');
      expect(provider.isLoadingCatalog, isFalse);
    });

    test('stays empty when Firebase is not configured', () async {
      catalogRepo.configured = false;

      await provider.loadCatalog();

      expect(provider.catalog, isEmpty);
      expect(provider.errorMessage, isNull);
    });
  });
}
