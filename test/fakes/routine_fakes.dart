import 'dart:async';

import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/routine.dart';
import 'package:fittrack/repositories/exercise_repository.dart';
import 'package:fittrack/repositories/routine_repository.dart';

/// Scriptable [RoutineRepository] double.
///
/// Nothing here touches Firebase: routines live in a per-uid map and every
/// mutation re-emits on the same live stream the real repository would use.
class FakeRoutineRepository implements RoutineRepository {
  final Map<String, List<Routine>> store = <String, List<Routine>>{};
  final List<Routine> created = <Routine>[];
  final List<Routine> updated = <Routine>[];
  final List<String> deleted = <String>[];
  final List<String> watchCalls = <String>[];

  bool configured = true;
  bool failWatch = false;
  bool failWrite = false;
  Duration writeDelay = Duration.zero;

  int _nextId = 0;

  final Map<String, StreamController<List<Routine>>> _controllers =
      <String, StreamController<List<Routine>>>{};

  List<Routine> _current(String uid) =>
      List<Routine>.unmodifiable(store[uid] ?? const <Routine>[]);

  void _emit(StreamController<List<Routine>> controller, String uid) {
    if (failWatch) {
      controller.addError(StateError('fake watch failure'));
      return;
    }
    controller.add(_current(uid));
  }

  /// Pushes the current store contents to anyone watching [uid].
  void emit(String uid) {
    final StreamController<List<Routine>>? controller = _controllers[uid];
    if (controller == null || controller.isClosed) return;
    _emit(controller, uid);
  }

  @override
  bool get isConfigured => configured;

  @override
  Stream<List<Routine>> watch(String uid) {
    watchCalls.add(uid);
    StreamController<List<Routine>>? controller = _controllers[uid];
    if (controller == null || controller.isClosed) {
      final StreamController<List<Routine>> created =
          StreamController<List<Routine>>.broadcast(sync: true);
      // Microtask, not a synchronous add: like Firestore, the first snapshot
      // never lands inside the listen() call itself.
      created.onListen =
          () => scheduleMicrotask(() => _emit(created, uid));
      controller = created;
      _controllers[uid] = created;
    }
    return controller.stream;
  }

  @override
  Future<Routine?> getById(String uid, String routineId) async {
    for (final Routine routine in _current(uid)) {
      if (routine.id == routineId) return routine;
    }
    return null;
  }

  @override
  Future<String> create(String uid, Routine routine) async {
    if (writeDelay > Duration.zero) {
      await Future<void>.delayed(writeDelay);
    }
    if (failWrite) throw StateError('fake write failure');
    final String id = 'routine-${_nextId++}';
    final Routine stored = routine.copyWith(
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    created.add(stored);
    store.putIfAbsent(uid, () => <Routine>[]).add(stored);
    emit(uid);
    return id;
  }

  @override
  Future<void> update(String uid, Routine routine) async {
    if (writeDelay > Duration.zero) {
      await Future<void>.delayed(writeDelay);
    }
    if (failWrite) throw StateError('fake write failure');
    updated.add(routine);
    final List<Routine>? routines = store[uid];
    if (routines == null) return;
    final int index = routines
        .indexWhere((Routine existing) => existing.id == routine.id);
    if (index >= 0) routines[index] = routine;
    emit(uid);
  }

  @override
  Future<void> delete(String uid, String routineId) async {
    if (writeDelay > Duration.zero) {
      await Future<void>.delayed(writeDelay);
    }
    if (failWrite) throw StateError('fake write failure');
    deleted.add(routineId);
    store[uid]?.removeWhere((Routine routine) => routine.id == routineId);
    emit(uid);
  }

  void dispose() {
    for (final StreamController<List<Routine>> controller
        in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }
}

/// Scriptable [ExerciseRepository] double backed by an in-memory catalog.
class FakeExerciseRepository implements ExerciseRepository {
  FakeExerciseRepository({List<Exercise>? catalog})
      : catalog = List<Exercise>.of(catalog ?? const <Exercise>[]);

  final List<Exercise> catalog;

  bool configured = true;
  bool failFetch = false;

  @override
  bool get isConfigured => configured;

  @override
  Stream<List<Exercise>> watchAll() => Stream<List<Exercise>>.value(catalog);

  @override
  Future<List<Exercise>> fetchAll() async {
    if (failFetch) throw StateError('fake catalog failure');
    return catalog;
  }

  @override
  Future<Exercise?> getById(String exerciseId) async {
    for (final Exercise exercise in catalog) {
      if (exercise.id == exerciseId) return exercise;
    }
    return null;
  }
}
