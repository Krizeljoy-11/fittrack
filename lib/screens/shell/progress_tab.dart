import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

/// Placeholder for statistics and charts (populated by the progress phase).
class ProgressTab extends StatelessWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: EmptyState(
        icon: Icons.insights_outlined,
        title: 'No progress data yet',
        message:
            'Workout statistics, weekly totals and your streak will show up '
            'here once you complete workouts.',
      ),
    );
  }
}
