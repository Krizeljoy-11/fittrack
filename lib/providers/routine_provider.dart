import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/error_messages.dart';
import '../models/exercise.dart';
import '../models/routine.dart';
import '../repositories/exercise_repository.dart';
import '../repositories/routine_repository.dart';

/// UI state for the signed-in member's routines plus the shared catalog.
///
/// Screens watch this provider and never touch Firestore themselves: routine
/// reads go through a live [RoutineRepository.watch] subscription started by
/// [watch], writes through [saveRoutine] / [deleteRoutine], and the exercise
/// catalog through [loadCatalog]. Like [ProfileProvider], every method
/// swallows failures and reports them through [errorMessage] instead of
/// throwing, so a missing or unreachable backend can never crash the app.
class RoutineProvider extends ChangeNotifier {
  RoutineProvider({
    RoutineRepository? repository,
    ExerciseRepository? exerciseRepository,
  })  : _repository = repository ?? FirestoreRoutineRepository(),
        _exerciseRepository =
            exerciseRepository ?? FirestoreExerciseRepository();

  static const String notConfiguredMessage =
      'Firebase is not configured yet. Configure Firebase, then try again.';

  final RoutineRepository _repository;
  final ExerciseRepository _exerciseRepository;

  StreamSubscription<List<Routine>>? _subscription;

  String? _uid;
  List<Routine> _routines = const <Routine>[];
  List<Exercise> _catalog = const <Exercise>[];
  bool _loading = false;
  bool _saving = false;
  bool _loadingCatalog = false;
  String? _error;
  String? _success;

  String? get uid => _uid;
  List<Routine> get routines => _routines;
  List<Exercise> get catalog => _catalog;
  bool get isLoading => _loading;
  bool get isSaving => _saving;
  bool get isLoadingCatalog => _loadingCatalog;
  String? get errorMessage => _error;
  String? get successMessage => _success;
  bool get isConfigured => _repository.isConfigured;

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void clearSuccess() {
    if (_success == null) return;
    _success = null;
    notifyListeners();
  }

  /// The routine with [routineId] in the currently loaded list, if any.
  Routine? routineById(String routineId) {
    for (final Routine routine in _routines) {
      if (routine.id == routineId) return routine;
    }
    return null;
  }

  /// Subscribes to the live routine list for the authenticated [uid].
  ///
  /// Re-watching the same uid is a no-op; switching uid cancels the previous
  /// subscription first. When Firebase is not configured the screen renders
  /// the "not configured" notice itself and no subscription is opened.
  void watch(String uid) {
    if (_uid == uid && _subscription != null) return;
    _subscription?.cancel();
    _subscription = null;
    _uid = uid;
    _routines = const <Routine>[];
    _error = null;

    if (!_repository.isConfigured) {
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();
    _subscription = _repository.watch(uid).listen(
      (List<Routine> routines) {
        _routines = routines;
        _loading = false;
        notifyListeners();
      },
      onError: (Object error) {
        _routines = const <Routine>[];
        _loading = false;
        _error = describeError(error);
        debugPrint('RoutineProvider: $error');
        notifyListeners();
      },
    );
  }

  /// Creates (when [routineId] is `null`) or updates the routine and reports
  /// whether it succeeded.
  ///
  /// Exercises are re-ordered to match their position in [exercises] so the
  /// stored `order` always matches what the editor shows.
  Future<bool> saveRoutine({
    required String uid,
    String? routineId,
    required String name,
    required String description,
    required RoutineDifficulty difficulty,
    required List<RoutineExercise> exercises,
  }) async {
    _saving = true;
    _error = null;
    _success = null;
    notifyListeners();

    try {
      if (!_repository.isConfigured) {
        _error = notConfiguredMessage;
        return false;
      }
      final List<RoutineExercise> ordered = <RoutineExercise>[
        for (int i = 0; i < exercises.length; i++)
          exercises[i].copyWith(order: i),
      ];
      if (routineId == null) {
        await _repository.create(
          uid,
          Routine(
            id: '',
            name: name.trim(),
            description: description.trim(),
            difficulty: difficulty,
            exercises: ordered,
          ),
        );
        _success = 'Routine created.';
      } else {
        final Routine? existing = await _repository.getById(uid, routineId);
        await _repository.update(
          uid,
          Routine(
            id: routineId,
            name: name.trim(),
            description: description.trim(),
            difficulty: difficulty,
            exercises: ordered,
            createdAt: existing?.createdAt,
          ),
        );
        _success = 'Routine updated.';
      }
      return true;
    } on Object catch (error) {
      _error = describeError(error);
      debugPrint('RoutineProvider: $error');
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  /// Deletes the routine and reports whether it succeeded.
  Future<bool> deleteRoutine({
    required String uid,
    required String routineId,
  }) async {
    _saving = true;
    _error = null;
    _success = null;
    notifyListeners();

    try {
      if (!_repository.isConfigured) {
        _error = notConfiguredMessage;
        return false;
      }
      await _repository.delete(uid, routineId);
      _success = 'Routine deleted.';
      return true;
    } on Object catch (error) {
      _error = describeError(error);
      debugPrint('RoutineProvider: $error');
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  /// Loads the shared exercise catalog for the routine editor's picker.
  Future<void> loadCatalog() async {
    if (_loadingCatalog) return;
    _loadingCatalog = true;
    notifyListeners();

    try {
      if (!_exerciseRepository.isConfigured) {
        _catalog = const <Exercise>[];
        return;
      }
      _catalog = await _exerciseRepository.fetchAll();
    } on Object catch (error) {
      _catalog = const <Exercise>[];
      _error = describeError(error);
      debugPrint('RoutineProvider: catalog $error');
    } finally {
      _loadingCatalog = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
