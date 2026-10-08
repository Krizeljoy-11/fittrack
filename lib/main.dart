import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/firebase_bootstrap.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/routine_provider.dart';
import 'repositories/exercise_repository.dart';
import 'repositories/routine_repository.dart';
import 'repositories/user_repository.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/routines/routine_detail_screen.dart';
import 'screens/routines/routine_edit_screen.dart';
import 'screens/shell/main_shell.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.init();
  await NotificationService().initialize();
  runApp(const MyApp());
}

/// Named-route table.
///
/// Every screen reachable through `Navigator.pushNamed` is registered here.
/// The five tab routes open [MainShell] on the matching tab; anything unknown
/// falls back to [AuthGate] so navigation can never dead-end.
final Map<String, WidgetBuilder> _routes = <String, WidgetBuilder>{
  AppRoutes.authGate: (_) => const AuthGate(),
  AppRoutes.login: (_) => const LoginScreen(),
  AppRoutes.register: (_) => const RegisterScreen(),
  AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
  AppRoutes.main: (_) => const MainShell(),
  AppRoutes.home: (_) => const MainShell(initialIndex: 0),
  AppRoutes.workout: (_) => const MainShell(initialIndex: 1),
  AppRoutes.schedule: (_) => const MainShell(initialIndex: 2),
  AppRoutes.progress: (_) => const MainShell(initialIndex: 3),
  AppRoutes.profile: (_) => const MainShell(initialIndex: 4),
  AppRoutes.editProfile: (_) => const EditProfileScreen(),
};

Route<dynamic> _onGenerateRoute(RouteSettings settings) {
  // Screens that take a single string argument are built here so tests can
  // also construct them directly with the same constructor.
  if (settings.name == AppRoutes.routineDetail) {
    final Object? arguments = settings.arguments;
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => RoutineDetailScreen(
        routineId: arguments is String ? arguments : '',
      ),
    );
  }
  if (settings.name == AppRoutes.routineEdit) {
    final Object? arguments = settings.arguments;
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => RoutineEditScreen(
        routineId: arguments is String ? arguments : null,
      ),
    );
  }

  final WidgetBuilder? builder = _routes[settings.name];
  if (builder == null) {
    debugPrint('AppRouter: no route for "${settings.name}", using AuthGate.');
  }
  return MaterialPageRoute<dynamic>(
    settings: settings,
    builder: builder ?? (_) => const AuthGate(),
  );
}

/// FitTrack root widget.
///
/// Owns the provider wiring so both `main()` and widget tests can pump it
/// without extra setup. [authService] exists so widget tests can drive the
/// auth flow with a fake instead of a real Firebase project, and the
/// repository parameters let them serve the same documents the same way.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.authService,
    this.profileRepository,
    this.routineRepository,
    this.exerciseRepository,
  });

  final AuthService? authService;
  final UserRepository? profileRepository;
  final RoutineRepository? routineRepository;
  final ExerciseRepository? exerciseRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(service: authService),
        ),
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => ProfileProvider(repository: profileRepository),
        ),
        ChangeNotifierProvider<RoutineProvider>(
          create: (_) => RoutineProvider(
            repository: routineRepository,
            exerciseRepository: exerciseRepository,
          ),
        ),
        Provider<NotificationService>(create: (_) => NotificationService()),
      ],
      child: MaterialApp(
        title: 'FitTrack',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.authGate,
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }
}
