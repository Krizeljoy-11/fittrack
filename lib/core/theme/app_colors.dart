import 'package:flutter/material.dart';

/// FitTrack color tokens.
///
/// Modern fitness look: green/teal primary, light background, white surfaces.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF059669);
  static const Color secondary = Color(0xFF14B8A6);

  // Surfaces
  static const Color background = Color(0xFFF5F8F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEDF2F0);
  static const Color border = Color(0xFFE1E7E4);

  // Text
  static const Color textPrimary = Color(0xFF0F1F1A);
  static const Color textSecondary = Color(0xFF5B6B65);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}
