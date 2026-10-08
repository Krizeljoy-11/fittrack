import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_banner.dart';
import '../../core/widgets/loading_overlay.dart';
import '../../core/widgets/section_header.dart';
import '../../models/routine.dart';
import '../../providers/auth_provider.dart';
import '../../providers/routine_provider.dart';

/// Routine list for the Workout tab.
///
/// Subscribes to the live routine stream for the signed-in member and offers
/// a create action; opening, editing and deleting happen on the detail and
/// editor screens pushed from here.
class WorkoutTab extends StatefulWidget {
  const WorkoutTab({super.key});

  @override
  State<WorkoutTab> createState() => _WorkoutTabState();
}

class _WorkoutTabState extends State<WorkoutTab> {
  @override
  void initState() {
    super.initState();
    // Deferred one frame so the first notifyListeners() never lands mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _watchRoutines());
  }

  void _watchRoutines() {
    if (!mounted) return;
    final String? uid = context.read<AuthProvider>().uid;
    if (uid == null) return;
    context.read<RoutineProvider>().watch(uid);
  }

  void _openCreate() {
    Navigator.of(context).pushNamed(AppRoutes.routineEdit);
  }

  void _openDetail(Routine routine) {
    Navigator.of(context).pushNamed(
      AppRoutes.routineDetail,
      arguments: routine.id,
    );
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

  Widget _routineCard(BuildContext context, Routine routine) {
    final TextTheme texts = Theme.of(context).textTheme;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      onTap: () => _openDetail(routine),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(routine.name, style: texts.titleMedium)),
              _difficultyChip(context, routine.difficulty),
            ],
          ),
          if (routine.description.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              routine.description.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: texts.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${routine.exercises.length} exercise(s) · '
            '${routine.totalSets} set(s)',
            style: texts.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final RoutineProvider provider = context.watch<RoutineProvider>();
    final List<Routine> routines = provider.routines;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('New routine'),
      ),
      body: LoadingOverlay(
        isLoading: provider.isLoading && routines.isEmpty,
        child: !provider.isConfigured
            ? ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: <Widget>[
                  const ErrorBanner(
                    message:
                        'Firebase is not configured yet. Run flutterfire '
                        'configure, then restart the app.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const EmptyState(
                    icon: Icons.fitness_center_outlined,
                    title: 'No routines yet',
                    message:
                        'Workout routines you create will be listed here, '
                        'ready to start or schedule.',
                  ),
                ],
              )
            : routines.isEmpty
                ? EmptyState(
                    icon: Icons.fitness_center_outlined,
                    title: provider.errorMessage != null
                        ? 'Routines unavailable'
                        : 'No routines yet',
                    message: provider.errorMessage ??
                        'Workout routines you create will be listed here, '
                            'ready to start or schedule.',
                  )
                : ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: <Widget>[
                      if (provider.errorMessage != null) ...<Widget>[
                        ErrorBanner(
                          message: provider.errorMessage!,
                          onDismiss: provider.clearError,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      const SectionHeader('Your routines'),
                      ...routines.map((Routine routine) =>
                          _routineCard(context, routine)),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
      ),
    );
  }
}
