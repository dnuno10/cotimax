import 'package:flutter/material.dart';

class AppColorPalette {
  const AppColorPalette({
    required this.primary,
    required this.accent,
    required this.white,
    required this.background,
    required this.container,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.error,
    required this.warning,
  });

  final Color primary;
  final Color accent;
  final Color white;
  final Color background;
  final Color container;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color error;
  final Color warning;
}

class AppColors {
  static const AppColorPalette lightPalette = AppColorPalette(
    primary: Color(0xFF1E5BB8),
    accent: Color(0xFFF04A2A),
    white: Color(0xFFFFFFFF),
    background: Color(0xFFF7F9FC),
    container: Color(0xFFFFFFFF),
    border: Color(0xFFE6EAF0),
    textPrimary: Color(0xFF1F2937),
    textSecondary: Color(0xFF6B7280),
    textMuted: Color(0xFF9CA3AF),
    success: Color(0xFF16A34A),
    error: Color(0xFFDC2626),
    warning: Color(0xFFD97706),
  );

  static const AppColorPalette darkPalette = AppColorPalette(
    primary: Color(0xFF6EA8FF),
    accent: Color(0xFFFF8A65),
    white: Color(0xFF0F172A),
    background: Color(0xFF08111F),
    container: Color(0xFF0F172A),
    border: Color(0xFF233043),
    textPrimary: Color(0xFFF3F6FB),
    textSecondary: Color(0xFFB5C0CF),
    textMuted: Color(0xFF7B8798),
    success: Color(0xFF34D399),
    error: Color(0xFFF87171),
    warning: Color(0xFFFBBF24),
  );

  static AppColorPalette _currentPalette = lightPalette;

  static void syncThemeMode(ThemeMode mode) {
    _currentPalette = mode == ThemeMode.dark ? darkPalette : lightPalette;
  }

  static Color get primary => _currentPalette.primary;
  static Color get accent => _currentPalette.accent;
  static Color get white => _currentPalette.white;
  static Color get background => _currentPalette.background;
  static Color get container => _currentPalette.container;
  static Color get border => _currentPalette.border;
  static Color get textPrimary => _currentPalette.textPrimary;
  static Color get textSecondary => _currentPalette.textSecondary;
  static Color get textMuted => _currentPalette.textMuted;
  static Color get success => _currentPalette.success;
  static Color get error => _currentPalette.error;
  static Color get warning => _currentPalette.warning;
}
