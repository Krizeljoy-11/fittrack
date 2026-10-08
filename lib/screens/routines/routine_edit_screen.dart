import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/validators/validators.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_banner.dart';
import '../../core/widgets/loading_overlay.dart';
import '../../core/widgets/section_header.dart';
import '../../models/exercise.dart';
import '../../models/routine.dart';
import '../../providers/auth_provider.dart';
import '../../providers/routine_provider.dart';

/// Creates or edits a reusable workout routine.
///
/// Pushed with no [routineId] to create, or with one to edit the matching
/// routine from the loaded list. Exercises are picked from the shared catalog
/// and tuned (sets, reps, duration, rest) before being added.
class RoutineEditScreen extends StatefulWidget {
  const RoutineEditScreen({super.key, this.routineId});

  /// `null` creates a new routine; otherwise the id to edit.
  final String? routineId;

  @override
  State<RoutineEditScreen> createState() => _RoutineEditScreenState();
}

class _RoutineEditScreenState extends State<RoutineEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  late RoutineDifficulty _difficulty;
  late List<RoutineExercise> _exercises;
  String? _exercisesError;

  @override
  void initState() {
    super.initState();
    // `read` (not `watch`) so the controllers are seeded once from the loaded
    // routine without rebuilding when the stream delivers updates.
    final String? routineId = widget.routineId;
    final Routine? routine = routineId == null
        ? null
        : context.read<RoutineProvider>().routineById(routineId);

    _nameController = TextEditingController(text: routine?.name ?? '');
    _descriptionController =
        TextEditingController(text: routine?.description ?? '');
    _difficulty = routine?.difficulty ?? RoutineDifficulty.beginner;
    _exercises = List<RoutineExercise>.of(routine?.exercises ?? const <RoutineExercise>[]);

    // Deferred one frame so the first notifyListeners() never lands mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCatalog());
  }

  void _loadCatalog() {
    if (!mounted) return;
    context.read<RoutineProvider>().loadCatalog();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _difficultyLabel(RoutineDifficulty difficulty) {
    switch (difficulty) {
      case RoutineDifficulty.beginner:
        return 'Beginner';
      case RoutineDifficulty.intermediate:
        return 'Intermediate';
      case RoutineDifficulty.advanced:
        return 'Advanced';
    }
  }

  String _exerciseSummary(RoutineExercise exercise) {
    final List<String> parts = <String>['${exercise.sets} set(s)'];
    if (exercise.reps != null) parts.add('${exercise.reps} rep(s)');
    if (exercise.durationSeconds != null) {
      parts.add('${exercise.durationSeconds} s work');
    }
    if (exercise.restSeconds > 0) parts.add('${exercise.restSeconds} s rest');
    return parts.join(' · ');
  }

  Future<void> _pickExercise() async {
    final Exercise? picked = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => const _CatalogPickerSheet(),
    );
    if (picked == null || !mounted) return;

    final RoutineExercise? tuned = await showDialog<RoutineExercise>(
      context: context,
      builder: (BuildContext context) => _ExerciseSettingsDialog(
        exerciseId: picked.id,
        exerciseName: picked.name,
      ),
    );
    if (tuned == null || !mounted) return;

    setState(() {
      _exercises.add(tuned);
      _exercisesError = null;
    });
  }

  Future<void> _editExercise(int index) async {
    final RoutineExercise current = _exercises[index];
    final RoutineExercise? tuned = await showDialog<RoutineExercise>(
      context: context,
      builder: (BuildContext context) => _ExerciseSettingsDialog(
        exerciseId: current.exerciseId,
        exerciseName: current.exerciseName,
        initial: current,
      ),
    );
    if (tuned == null || !mounted) return;

    setState(() => _exercises[index] = tuned);
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
      if (_exercises.isEmpty) {
        _exercisesError = 'Add at least one exercise to continue.';
      }
    });
  }

  Future<void> _submit() async {
    final RoutineProvider provider = context.read<RoutineProvider>();
    final AuthProvider auth = context.read<AuthProvider>();
    provider.clearError();

    final bool formOk = _formKey.currentState?.validate() ?? false;
    if (_exercises.isEmpty) {
      setState(() => _exercisesError = 'Add at least one exercise to continue.');
    }
    final String? uid = auth.uid;
    if (!formOk || _exercises.isEmpty || uid == null) return;

    final bool saved = await provider.saveRoutine(
      uid: uid,
      routineId: widget.routineId,
      name: _nameController.text,
      description: _descriptionController.text,
      difficulty: _difficulty,
      exercises: _exercises,
    );
    if (!saved || !mounted) return;

    final String? success = provider.successMessage;
    if (success != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(success)));
      provider.clearSuccess();
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final RoutineProvider provider = context.watch<RoutineProvider>();
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme texts = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routineId == null ? 'New routine' : 'Edit routine'),
      ),
      body: LoadingOverlay(
        isLoading: provider.isSaving,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              if (provider.errorMessage != null) ...<Widget>[
                ErrorBanner(
                  message: provider.errorMessage!,
                  onDismiss: provider.clearError,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SectionHeader('Routine details'),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          AppTextField(
                            label: 'Routine name',
                            controller: _nameController,
                            prefixIcon: Icons.fitness_center_outlined,
                            textInputAction: TextInputAction.next,
                            validator: (String? value) =>
                                Validators.displayName(
                              value,
                              field: 'Routine name',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Description (optional)',
                            controller: _descriptionController,
                            prefixIcon: Icons.notes_outlined,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const SectionHeader('Difficulty'),
                    AppCard(
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: RoutineDifficulty.values
                            .map(
                              (RoutineDifficulty difficulty) => ChoiceChip(
                                label: Text(_difficultyLabel(difficulty)),
                                selected: _difficulty == difficulty,
                                onSelected: (_) =>
                                    setState(() => _difficulty = difficulty),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(
                      'Exercises (${_exercises.length})',
                      action: TextButton.icon(
                        onPressed: _pickExercise,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ),
                    if (_exercises.isEmpty)
                      AppCard(
                        child: Text(
                          _exercisesError ??
                              'No exercises yet. Tap Add to pick from the '
                                  'catalog.',
                          style: texts.bodySmall?.copyWith(
                            color: _exercisesError == null
                                ? AppColors.textSecondary
                                : colors.error,
                          ),
                        ),
                      )
                    else
                      AppCard(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            for (int i = 0; i < _exercises.length; i++) ...<Widget>[
                              if (i > 0) const Divider(height: 1),
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                                leading: CircleAvatar(
                                  radius: AppSpacing.sm + 2,
                                  backgroundColor: colors.primary
                                      .withValues(alpha: 0.12),
                                  child: Text(
                                    '${i + 1}',
                                    style: texts.labelMedium?.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                title: Text(_exercises[i].exerciseName),
                                subtitle: Text(_exerciseSummary(_exercises[i])),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    IconButton(
                                      onPressed: () => _editExercise(i),
                                      icon: const Icon(Icons.edit_outlined),
                                      tooltip: 'Edit exercise',
                                    ),
                                    IconButton(
                                      onPressed: () => _removeExercise(i),
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip: 'Remove exercise',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    if (_exercisesError != null && _exercises.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _exercisesError!,
                        style: texts.bodySmall?.copyWith(color: colors.error),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: 'Save routine',
                      isLoading: provider.isSaving,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet listing the shared exercise catalog for picking.
class _CatalogPickerSheet extends StatelessWidget {
  const _CatalogPickerSheet();

  @override
  Widget build(BuildContext context) {
    final RoutineProvider provider = context.watch<RoutineProvider>();
    final TextTheme texts = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text('Pick an exercise', style: texts.titleMedium),
            ),
            Expanded(
              child: provider.isLoadingCatalog
                  ? const Center(child: CircularProgressIndicator())
                  : provider.catalog.isEmpty
                      ? const EmptyState(
                          icon: Icons.library_books_outlined,
                          title: 'No exercises yet',
                          message:
                              'The shared exercise catalog is empty. It is '
                              'seeded outside the app.',
                        )
                      : ListView.separated(
                          itemCount: provider.catalog.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (BuildContext context, int index) {
                            final Exercise exercise = provider.catalog[index];
                            return ListTile(
                              title: Text(exercise.name),
                              subtitle: exercise.muscleGroup.isEmpty
                                  ? null
                                  : Text(
                                      exercise.muscleGroup,
                                      style: texts.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: colors.outline,
                              ),
                              onTap: () => Navigator.of(context).pop(exercise),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog that tunes sets / reps / duration / rest for one exercise.
class _ExerciseSettingsDialog extends StatefulWidget {
  const _ExerciseSettingsDialog({
    required this.exerciseId,
    required this.exerciseName,
    this.initial,
  });

  final String exerciseId;
  final String exerciseName;
  final RoutineExercise? initial;

  @override
  State<_ExerciseSettingsDialog> createState() =>
      _ExerciseSettingsDialogState();
}

class _ExerciseSettingsDialogState extends State<_ExerciseSettingsDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _setsController;
  late final TextEditingController _repsController;
  late final TextEditingController _durationController;
  late final TextEditingController _restController;

  @override
  void initState() {
    super.initState();
    final RoutineExercise? initial = widget.initial;
    _setsController = TextEditingController(text: '${initial?.sets ?? 3}');
    _repsController =
        TextEditingController(text: initial?.reps?.toString() ?? '');
    _durationController =
        TextEditingController(text: initial?.durationSeconds?.toString() ?? '');
    _restController =
        TextEditingController(text: '${initial?.restSeconds ?? 60}');
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _durationController.dispose();
    _restController.dispose();
    super.dispose();
  }

  int? _toInt(TextEditingController controller) =>
      int.tryParse(controller.text.trim());

  void _save() {
    final bool formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk) return;
    Navigator.of(context).pop(
      RoutineExercise(
        exerciseId: widget.exerciseId,
        exerciseName: widget.exerciseName,
        sets: _toInt(_setsController) ?? 3,
        reps: _toInt(_repsController),
        durationSeconds: _toInt(_durationController),
        restSeconds: _toInt(_restController) ?? 60,
        order: widget.initial?.order ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text(widget.exerciseName),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppTextField(
                  label: 'Sets',
                  controller: _setsController,
                  keyboardType: TextInputType.number,
                  validator: (String? value) => Validators.number(
                    value,
                    field: 'Sets',
                    min: 1,
                    max: 50,
                    allowEmpty: false,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Reps (optional)',
                  controller: _repsController,
                  keyboardType: TextInputType.number,
                  validator: (String? value) =>
                      Validators.number(value, field: 'Reps', min: 1, max: 999),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Duration in seconds (optional)',
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  validator: (String? value) => Validators.number(
                    value,
                    field: 'Duration',
                    min: 1,
                    max: 86400,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Rest in seconds',
                  controller: _restController,
                  keyboardType: TextInputType.number,
                  validator: (String? value) => Validators.number(
                    value,
                    field: 'Rest',
                    min: 0,
                    max: 3600,
                    allowEmpty: false,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Leave reps or duration empty for exercises that use the '
                  'other one.',
                  style: texts.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Done')),
      ],
    );
  }
}
