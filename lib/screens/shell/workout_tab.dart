import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

/// Placeholder for the routine list (populated by the routines phase).
class WorkoutTab extends StatelessWidget {
  const WorkoutTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: EmptyState(
        icon: Icons.fitness_center_outlined,
        title: 'No routines yet',
        message:
            'Workout routines you create will be listed here, ready to start '
            'or schedule.',
      ),
    );
  }
}
