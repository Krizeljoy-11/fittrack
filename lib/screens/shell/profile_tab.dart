import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_banner.dart';
import '../../core/widgets/loading_overlay.dart';
import '../../core/widgets/section_header.dart';
import '../../models/app_user.dart';
import '../../models/fitness_goal.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

/// The member's profile: identity header, vitals, and account actions.
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  void initState() {
    super.initState();
    // Deferred one frame so the first notifyListeners() never lands mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  /// Loads `users/{uid}` for the signed-in account.
  void _loadProfile() {
    if (!mounted) return;
    final AuthProvider auth = context.read<AuthProvider>();
    final String? uid = auth.uid;
    if (uid == null) return;
    context.read<ProfileProvider>().load(
          uid: uid,
          email: (auth.user?.email ?? '').trim(),
          displayName: (auth.user?.displayName ?? '').trim(),
        );
  }

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

  /// Display name precedence: edited profile, then the auth record.
  String _displayName(AppUser? profile, AuthProvider auth) {
    final String fromProfile = profile?.displayName.trim() ?? '';
    if (fromProfile.isNotEmpty) return fromProfile;
    final String fromAuth = (auth.user?.displayName ?? '').trim();
    if (fromAuth.isNotEmpty) return fromAuth;
    return 'FitTrack member';
  }

  String _initial(String name) {
    if (name.isEmpty) return 'F';
    return name.substring(0, 1).toUpperCase();
  }

  String _value(double? amount, String Function(double) format) {
    if (amount == null) return 'Not set';
    return format(amount);
  }

  Widget _goalChip(BuildContext context, FitnessGoal goal) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme texts = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        goal.label,
        style: texts.bodySmall?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isSet,
  }) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme texts = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Icon(icon, size: AppSpacing.lg, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: texts.bodyMedium)),
          Text(
            value,
            style: texts.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isSet ? colors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final ProfileProvider profileProvider = context.watch<ProfileProvider>();
    final AppUser? profile = profileProvider.profile;
    final TextTheme texts = Theme.of(context).textTheme;

    final String name = _displayName(profile, auth);
    final String profileEmail = profile?.email.trim() ?? '';
    final String email =
        profileEmail.isNotEmpty ? profileEmail : (auth.user?.email ?? '').trim();
    final FitnessGoal? goal = profile?.fitnessGoal;

    return LoadingOverlay(
      isLoading: profileProvider.isLoading,
      message: 'Loading your profile',
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          if (!profileProvider.isConfigured) ...<Widget>[
            const ErrorBanner(
              message:
                  'Firebase is not configured yet. Run flutterfire configure, '
                  'then restart the app.',
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (profileProvider.errorMessage != null) ...<Widget>[
            ErrorBanner(
              message: profileProvider.errorMessage!,
              onDismiss: profileProvider.clearError,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppCard(
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: AppSpacing.lg,
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    _initial(name),
                    style: texts.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
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
                      if (goal != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.sm),
                        _goalChip(context, goal),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader('Profile information'),
          AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _infoRow(
                  context,
                  icon: Icons.height,
                  label: 'Height',
                  value: _value(profile?.height, AppFormatters.height),
                  isSet: profile?.height != null,
                ),
                const Divider(),
                _infoRow(
                  context,
                  icon: Icons.monitor_weight_outlined,
                  label: 'Weight',
                  value: _value(profile?.weight, AppFormatters.weight),
                  isSet: profile?.weight != null,
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
                PrimaryButton(
                  label: 'Edit Profile',
                  icon: Icons.edit_outlined,
                  onPressed: profileProvider.isLoading
                      ? null
                      : () => Navigator.of(context).pushNamed(
                            AppRoutes.editProfile,
                          ),
                ),
                const SizedBox(height: AppSpacing.sm),
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
      ),
    );
  }
}
