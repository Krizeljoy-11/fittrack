import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Labelled text field used by every FitTrack form.
///
/// Styling comes from `AppTheme.light.inputDecorationTheme`; this widget only
/// adds the label, icons and validation wiring.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.autofillHints,
    this.obscureText = false,
    this.enabled = true,
    this.autocorrect = false,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.onChanged,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final bool enabled;
  final bool autocorrect;
  final bool enableSuggestions;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      enabled: enabled,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      maxLines: maxLines,
      autofillHints: autofillHints,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: AppSpacing.lg),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
