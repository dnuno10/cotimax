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
    required this.muted,
    required this.mutedStrong,
    required this.ink,
    required this.onInk,
    required this.rail,
    required this.successSoft,
    required this.errorSoft,
    required this.hover,
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

  /// Soft gray fill: pills, chips, inner panels, inputs, selected nav items.
  final Color muted;

  /// Slightly darker gray for hover / pressed states on [muted] surfaces.
  final Color mutedStrong;

  /// Near-black for strong buttons (play / send), toasts and tooltips.
  final Color ink;

  /// Foreground on top of [ink].
  final Color onInk;

  /// Background of the narrow navigation rail.
  final Color rail;

  /// Mint tint used for positive panels (e.g. "Recording" strip).
  final Color successSoft;

  /// Rose tint used for destructive panels.
  final Color errorSoft;

  /// Very soft hover fill for navigable elements.
  final Color hover;
}

/// Muse-inspired palette: near-white surfaces, ink text, soft gray pills,
/// a calm blue for primary actions and mint / rose status tints.
class AppColors {
  static const AppColorPalette lightPalette = AppColorPalette(
    primary: Color(0xFF2257C9),
    accent: Color(0xFFD6516A),
    white: Color(0xFFFFFFFF),
    background: Color(0xFFFFFFFF),
    container: Color(0xFFFFFFFF),
    border: Color(0xFFE8E8EA),
    textPrimary: Color(0xFF1C1C1E),
    textSecondary: Color(0xFF6B6B70),
    textMuted: Color(0xFFA1A1A6),
    success: Color(0xFF3B8C5E),
    error: Color(0xFFD6516A),
    warning: Color(0xFFD48A1A),
    muted: Color(0xFFF4F4F6),
    mutedStrong: Color(0xFFEAEAED),
    ink: Color(0xFF1A1A1C),
    onInk: Color(0xFFFFFFFF),
    rail: Color(0xFFFFFFFF),
    successSoft: Color(0xFFEFF7F2),
    errorSoft: Color(0xFFFBEEF1),
    hover: Color(0xFFF7F7F8),
  );

  static const AppColorPalette darkPalette = AppColorPalette(
    primary: Color(0xFF5B8DEF),
    accent: Color(0xFFF07A8E),
    white: Color(0xFF1C1C1F),
    background: Color(0xFF141416),
    container: Color(0xFF1C1C1F),
    border: Color(0xFF2E2E33),
    textPrimary: Color(0xFFF5F5F7),
    textSecondary: Color(0xFFA1A1A8),
    textMuted: Color(0xFF6E6E76),
    success: Color(0xFF5CC18A),
    error: Color(0xFFF07A8E),
    warning: Color(0xFFF5B640),
    muted: Color(0xFF26262A),
    mutedStrong: Color(0xFF313136),
    ink: Color(0xFFF5F5F7),
    onInk: Color(0xFF111113),
    rail: Color(0xFF18181B),
    successSoft: Color(0xFF1C2C23),
    errorSoft: Color(0xFF2E1D22),
    hover: Color(0xFF212124),
  );

  static AppColorPalette _currentPalette = lightPalette;

  static void syncThemeMode(ThemeMode mode) {
    _currentPalette = mode == ThemeMode.dark ? darkPalette : lightPalette;
  }

  static bool get isDark => identical(_currentPalette, darkPalette);

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
  static Color get muted => _currentPalette.muted;
  static Color get mutedStrong => _currentPalette.mutedStrong;
  static Color get ink => _currentPalette.ink;
  static Color get onInk => _currentPalette.onInk;
  static Color get rail => _currentPalette.rail;
  static Color get successSoft => _currentPalette.successSoft;
  static Color get errorSoft => _currentPalette.errorSoft;
  static Color get hover => _currentPalette.hover;

  /// Soft, diffuse shadow for cards (Muse / call-card style).
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  /// Deeper shadow for popovers, dialogs and the command palette.
  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.13),
      blurRadius: 48,
      offset: const Offset(0, 18),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
}
