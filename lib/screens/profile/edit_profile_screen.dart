import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/validators/validators.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/error_banner.dart';
import '../../core/widgets/loading_overlay.dart';
import '../../core/widgets/section_header.dart';
import '../../models/app_user.dart';
import '../../models/fitness_goal.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

/// Edits display name, height, weight and fitness goal.
///
/// Email is shown for reference only — changing the sign-in address is out of
/// scope for this phase.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  FitnessGoal? _goal;
  String? _goalError;

  @override
  void initState() {
    super.initState();
    // `read` (not `watch`) so the controllers are seeded once from the loaded
    // profile without rebuilding when it changes.
    final AppUser? profile = context.read<ProfileProvider>().profile;
    final String authName = (context.read<AuthProvider>().user?.displayName ?? '').trim();

    _nameController = TextEditingController(
      text: (profile?.displayName.trim().isNotEmpty ?? false)
          ? profile!.displayName.trim()
          : authName,
    );
    _heightController = TextEditingController(text: _toText(profile?.height));
    _weightController = TextEditingController(text: _toText(profile?.weight));
    _goal = profile?.fitnessGoal;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  /// Whole numbers read back without a trailing `.0`.
  String _toText(double? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1);
  }

  double? _toDouble(TextEditingController controller) =>
      double.tryParse(controller.text.trim());

  void _selectGoal(FitnessGoal goal) {
    setState(() {
      _goal = goal;
      _goalError = null;
    });
  }

  Future<void> _submit() async {
    final ProfileProvider provider = context.read<ProfileProvider>();
    final AuthProvider auth = context.read<AuthProvider>();
    provider.clearError();

    final bool formOk = _formKey.currentState?.validate() ?? false;
    final FitnessGoal? goal = _goal;
    if (goal == null) {
      setState(() => _goalError = 'Choose a fitness goal to continue.');
    }
    final String? uid = auth.uid;
    if (!formOk || goal == null || uid == null) return;

    final bool saved = await provider.save(
      uid: uid,
      email: (auth.user?.email ?? provider.profile?.email ?? '').trim(),
      displayName: _nameController.text,
      height: _toDouble(_heightController),
      weight: _toDouble(_weightController),
      fitnessGoal: goal,
    );
    if (!saved || !mounted) return;

    final String? success = provider.successMessage;
    if (success != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(success)));
      provider.clearSuccess();
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ProfileProvider provider = context.watch<ProfileProvider>();
    final AuthProvider auth = context.watch<AuthProvider>();
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme texts = Theme.of(context).textTheme;

    final String profileEmail = provider.profile?.email ?? '';
    final String email = profileEmail.trim().isNotEmpty
        ? profileEmail.trim()
        : (auth.user?.email ?? '').trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: LoadingOverlay(
        isLoading: provider.isSaving,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              if (provider.errorMessage != null) ...<Widget>[
                ErrorBanner(
                  message: provider.errorMessage!,
                  onDismiss: provider.clearError,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SectionHeader('Profile details'),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          AppTextField(
                            label: 'Display name',
                            controller: _nameController,
                            prefixIcon: Icons.person_outline,
                            textInputAction: TextInputAction.next,
                            validator: Validators.displayName,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Height (cm)',
                            controller: _heightController,
                            prefixIcon: Icons.height,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            textInputAction: TextInputAction.next,
                            validator: (String? value) => Validators.number(
                              value,
                              field: 'Height',
                              min: 50,
                              max: 250,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Weight (kg)',
                            controller: _weightController,
                            prefixIcon: Icons.monitor_weight_outlined,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            textInputAction: TextInputAction.done,
                            validator: (String? value) => Validators.number(
                              value,
                              field: 'Weight',
                              min: 20,
                              max: 400,
                            ),
                            onFieldSubmitted: (_) => _submit(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const SectionHeader('Fitness goal'),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'What are you training for?',
                            style: texts.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: FitnessGoal.values
                                .map(
                                  (FitnessGoal goal) => ChoiceChip(
                                    label: Text(goal.label),
                                    selected: _goal == goal,
                                    onSelected: (_) => _selectGoal(goal),
                                  ),
                                )
                                .toList(),
                          ),
                          if (_goalError != null) ...<Widget>[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              _goalError!,
                              style: texts.bodySmall?.copyWith(
                                color: colors.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const SectionHeader('Account'),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Email',
                            style: texts.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            email.isNotEmpty ? email : 'Not available',
                            style: texts.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Your email is your sign-in address and cannot '
                            'be changed here.',
                            style: texts.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: 'Save changes',
                      isLoading: provider.isSaving,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
