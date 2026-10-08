import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'login_screen.dart';
import '../shell/main_shell.dart';

/// Routes between the signed-in shell and the signed-out login screen.
///
/// The switch is declarative: when [AuthProvider] reports a different auth
/// state, this widget simply builds the other tree. No imperative navigation
/// is involved, so auth changes always win over whatever is on screen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    if (auth.isSignedIn) return const MainShell();
    return const LoginScreen();
  }
}
