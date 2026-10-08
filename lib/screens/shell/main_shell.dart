import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/loading_overlay.dart';
import '../../providers/auth_provider.dart';
import 'home_tab.dart';
import 'profile_tab.dart';
import 'progress_tab.dart';
import 'schedule_tab.dart';
import 'workout_tab.dart';

/// Root of the signed-in experience: app bar, five tabs, bottom navigation.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  /// Index of the tab opened when the shell is built (used by named routes).
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const int _tabCount = 5;

  static const List<_ShellTab> _tabs = <_ShellTab>[
    _ShellTab('Home', Icons.home_outlined, Icons.home, HomeTab()),
    _ShellTab(
      'Workout',
      Icons.fitness_center_outlined,
      Icons.fitness_center,
      WorkoutTab(),
    ),
    _ShellTab(
      'Schedule',
      Icons.calendar_month_outlined,
      Icons.calendar_month,
      ScheduleTab(),
    ),
    _ShellTab(
      'Progress',
      Icons.insights_outlined,
      Icons.insights,
      ProgressTab(),
    ),
    _ShellTab(
      'Profile',
      Icons.person_outline,
      Icons.person,
      ProfileTab(),
    ),
  ];

  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, _tabCount - 1);
  }

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('FitTrack')),
      body: LoadingOverlay(
        isLoading: auth.isBusy,
        child: IndexedStack(
          index: _index,
          children: _tabs.map((_ShellTab tab) => tab.widget).toList(),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: _tabs
            .map(
              (_ShellTab tab) => NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selectedIcon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ShellTab {
  const _ShellTab(this.label, this.icon, this.selectedIcon, this.widget);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget widget;
}
