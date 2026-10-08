/// Named routes used by FitTrack.
///
/// Every `Navigator.pushNamed` in the app uses one of these constants.
abstract final class AppRoutes {
  static const String authGate = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  static const String main = '/main';
  static const String home = '/home';
  static const String workout = '/workout';
  static const String schedule = '/schedule';
  static const String progress = '/progress';
  static const String profile = '/profile';

  static const String routineDetail = '/routine/detail';
  static const String routineEdit = '/routine/edit';
  static const String scheduleEntryDetail = '/schedule/entry';
  static const String workoutSummary = '/workout/summary';
  static const String workoutHistory = '/workout/history';
  static const String goals = '/goals';
}
