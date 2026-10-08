import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_banner.dart';
import '../../core/widgets/loading_overlay.dart';
import '../../core/widgets/section_header.dart';
import '../../models/routine.dart';
import '../../providers/auth_provider.dart';
import '../../providers/routine_provider.dart';

/// Read-only view of one routine with edit and delete actions.
///
/// Pushed with the routine id as the route argument. The screen watches the
/// loaded list, so it stays correct if the routine changes (or disappears)
/// while it is open.
class RoutineDetailScreen extends StatelessWidget {
  const RoutineDetailScreen({super.key, required this.routineId});

  final String routineId;

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

  Future<void> _edit(BuildContext context) {
    return Navigator.of(context).pushNamed(
      AppRoutes.routineEdit,
      arguments: routineId,
    );
  }

  Future<void> _delete(BuildContext context) async {
    final RoutineProvider provider = context.read<RoutineProvider>();
    final AuthProvider auth = context.read<AuthProvider>();
    final String? uid = auth.uid;
    if (uid == null) return;

    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Delete routine?',
      message: 'This removes the routine from your list. '
          'Past workout logs are not affected.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    provider.clearError();
    final bool deleted = await provider.deleteRoutine(
      uid: uid,
      routineId: routineId,
    );
    if (!deleted || !context.mounted) return;

    final String? success = provider.successMessage;
    if (success != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(success)));
      provider.clearSuccess();
    }
    Navigator.of(context).pop();
  }

  Widget _difficultyChip(BuildContext context, RoutineDifficulty difficulty) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme texts = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        _difficultyLabel(difficulty),
        style: texts.bodySmall?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final RoutineProvider provider = context.watch<RoutineProvider>();
    final Routine? routine = provider.routineById(routineId);
    final TextTheme texts = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Routine details'),
        actions: <Widget>[
          IconButton(
            onPressed: routine == null ? null : () => _edit(context),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit routine',
          ),
          IconButton(
            onPressed: routine == null ? null : () => _delete(context),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete routine',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: provider.isSaving,
        child: routine == null
            ? const EmptyState(
                icon: Icons.fitness_center_outlined,
                title: 'Routine not found',
                message:
                    'This routine no longer exists. It may have been deleted '
                    'from another device.',
              )
            : SafeArea(
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
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(routine.name, style: texts.titleLarge),
                              ),
                              _difficultyChip(context, routine.difficulty),
                            ],
                          ),
                          if (routine.description.trim().isNotEmpty) ...<Widget>[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              routine.description.trim(),
                              style: texts.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            '${routine.exercises.length} exercise(s) · '
                            '${routine.totalSets} working set(s)',
                            style: texts.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const SectionHeader('Exercises'),
                    if (routine.exercises.isEmpty)
                      const AppCard(
                        child: Text(
                          'This routine has no exercises yet. Tap edit to add '
                          'some.',
                          style: TextStyle(color: AppColors.textSecondary),
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
                            for (int i = 0; i < routine.exercises.length; i++) ...<Widget>[
                              if (i > 0) const Divider(height: 1),
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                                leading: CircleAvatar(
                                  radius: AppSpacing.sm + 2,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.12),
                                  child: Text(
                                    '${i + 1}',
                                    style: texts.labelMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                title: Text(routine.exercises[i].exerciseName),
                                subtitle: Text(
                                  _exerciseSummary(routine.exercises[i]),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: 'Edit routine',
                      icon: Icons.edit_outlined,
                      onPressed: () => _edit(context),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SecondaryButton(
                      label: 'Delete routine',
                      icon: Icons.delete_outline,
                      isDestructive: true,
                      onPressed: () => _delete(context),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
