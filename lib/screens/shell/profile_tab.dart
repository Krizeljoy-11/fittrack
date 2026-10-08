import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_banner.dart';
import '../../core/widgets/section_header.dart';
import '../../providers/auth_provider.dart';

/// Placeholder profile: signed-in identity plus sign-out.
///
/// Editing display name, height, weight and fitness goal arrives with the
/// profile phase.
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> _signOut(BuildContext context) async {
    final AuthProvider auth = context.read<AuthProvider>();
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Sign out?',
      message: 'You will need to sign in again to access your workouts.',
      confirmLabel: 'Sign out',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await auth.signOut();
  }

  String _name(AuthProvider auth) {
    final String displayName = (auth.user?.displayName ?? '').trim();
    if (displayName.isNotEmpty) return displayName;
    final String email = (auth.user?.email ?? '').trim();
    if (email.isNotEmpty) return email;
    return 'FitTrack member';
  }

  String _initial(String name) {
    if (name.isEmpty) return 'F';
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme texts = Theme.of(context).textTheme;
    final String name = _name(auth);
    final String email = (auth.user?.email ?? '').trim();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: <Widget>[
        if (auth.errorMessage != null) ...<Widget>[
          ErrorBanner(
            message: auth.errorMessage!,
            onDismiss: auth.clearError,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppCard(
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: AppSpacing.lg,
                backgroundColor: colors.primary.withValues(alpha: 0.12),
                child: Text(
                  _initial(name),
                  style: texts.titleMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(name, style: texts.titleMedium),
                    if (email.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Text(email, style: texts.bodySmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader('Account'),
        AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SecondaryButton(
                label: 'Sign out',
                icon: Icons.logout,
                isDestructive: true,
                isLoading: auth.isBusy,
                onPressed: () => _signOut(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'FitTrack',
          textAlign: TextAlign.center,
          style: texts.bodySmall,
        ),
      ],
    );
  }
}
