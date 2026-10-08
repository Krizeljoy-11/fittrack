import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/validators/validators.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/error_banner.dart';
import '../../providers/auth_provider.dart';

/// Creates the Firebase Authentication account.
///
/// Deliberately auth-only: the Firestore profile document is created in a
/// later phase, not here.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AuthProvider auth = context.read<AuthProvider>();
    auth.clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final bool ok = await auth.register(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!ok || !mounted) return;
    // Success: AuthGate rebuilds into the main shell.
    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
  }

  void _backToSignIn() {
    context.read<AuthProvider>().clearError();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final TextTheme texts = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Join FitTrack')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Start tracking your workouts',
                      textAlign: TextAlign.center,
                      style: texts.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (!auth.isConfigured) ...<Widget>[
                      const ErrorBanner(
                        message:
                            'Firebase is not configured yet. Run '
                            'flutterfire configure, then restart the app.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (auth.errorMessage != null) ...<Widget>[
                      ErrorBanner(
                        message: auth.errorMessage!,
                        onDismiss: auth.clearError,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    AppTextField(
                      label: 'Email',
                      controller: _emailController,
                      prefixIcon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.email],
                      validator: Validators.email,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Password',
                      controller: _passwordController,
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.newPassword],
                      validator: Validators.password,
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: AppSpacing.lg,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Confirm password',
                      controller: _confirmController,
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      validator: (String? value) => Validators.confirmPassword(
                        value,
                        _passwordController.text,
                      ),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: 'Create account',
                      isLoading: auth.isBusy,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'Already have an account?',
                          style: texts.bodySmall,
                        ),
                        TextButton(
                          onPressed: auth.isBusy ? null : _backToSignIn,
                          child: const Text('Sign in'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
