import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

/// Placeholder for the schedule calendar (populated by the scheduling phase).
class ScheduleTab extends StatelessWidget {
  const ScheduleTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: EmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'Nothing scheduled',
        message:
            'Scheduled workouts and your weekly recurring sessions will show '
            'up here.',
      ),
    );
  }
}
