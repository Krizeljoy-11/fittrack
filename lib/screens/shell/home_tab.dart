import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_tile.dart';

/// Dashboard tab.
///
/// Phase 1 ships the layout only: the three tiles render placeholder zeros and
/// real numbers arrive with the progress phase.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList.list(
            children: <Widget>[
              const SectionHeader('This week'),
              Row(
                children: <Widget>[
                  const Expanded(
                    child: StatTile(
                      label: 'Workouts',
                      value: '0',
                      icon: Icons.fitness_center_outlined,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: StatTile(
                      label: 'Minutes',
                      value: '0',
                      icon: Icons.timer_outlined,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: StatTile(
                      label: 'Streak',
                      value: '0',
                      icon: Icons.local_fire_department_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.waving_hand_outlined,
            title: 'Welcome to FitTrack',
            message:
                'Upcoming workouts, your weekly summary and streak will '
                'show up here.',
          ),
        ),
      ],
    );
  }
}
