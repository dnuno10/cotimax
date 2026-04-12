import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/constants/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() => _buildTheme(
    brightness: Brightness.light,
    surface: AppColors.lightPalette.container,
    background: AppColors.lightPalette.background,
    border: AppColors.lightPalette.border,
    primaryText: AppColors.lightPalette.textPrimary,
    secondaryText: AppColors.lightPalette.textSecondary,
    mutedText: AppColors.lightPalette.textMuted,
  );

  static ThemeData dark() => _buildTheme(
    brightness: Brightness.dark,
    surface: AppColors.darkPalette.container,
    background: AppColors.darkPalette.background,
    border: AppColors.darkPalette.border,
    primaryText: AppColors.darkPalette.textPrimary,
    secondaryText: AppColors.darkPalette.textSecondary,
    mutedText: AppColors.darkPalette.textMuted,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color surface,
    required Color background,
    required Color border,
    required Color primaryText,
    required Color secondaryText,
    required Color mutedText,
  }) {
    final bodyText = GoogleFonts.plusJakartaSansTextTheme();
    final surfaceAlt = brightness == Brightness.dark
        ? Color.alphaBlend(
            AppColors.darkPalette.primary.withValues(alpha: 0.08),
            surface,
          )
        : background;
    final overlayShadow = primaryText.withValues(
      alpha: brightness == Brightness.dark ? 0.24 : 0.08,
    );
    final baseText = bodyText.copyWith(
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: primaryText,
        height: 1.02,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: primaryText,
        height: 1.06,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: primaryText,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: primaryText,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primaryText,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: secondaryText,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: brightness == Brightness.dark
            ? AppColors.darkPalette.background
            : AppColors.lightPalette.white,
      ),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.lightPalette.primary,
      brightness: brightness,
      primary: brightness == Brightness.dark
          ? AppColors.darkPalette.primary
          : AppColors.lightPalette.primary,
      secondary: brightness == Brightness.dark
          ? AppColors.darkPalette.accent
          : AppColors.lightPalette.accent,
      surface: surface,
      error: brightness == Brightness.dark
          ? AppColors.darkPalette.error
          : AppColors.lightPalette.error,
      outline: border,
    );

    final textOnPrimary = brightness == Brightness.dark
        ? AppColors.darkPalette.background
        : AppColors.lightPalette.white;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: baseText,
      scaffoldBackgroundColor: background,
      splashFactory: InkRipple.splashFactory,
      splashColor: colorScheme.primary.withValues(alpha: 0.10),
      highlightColor: colorScheme.primary.withValues(alpha: 0.04),
      hoverColor: colorScheme.primary.withValues(alpha: 0.05),
      dividerColor: border,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      pageTransitionsTheme:  PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius + 6),
          side: BorderSide(color: border),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: colorScheme.primary.withValues(alpha: 0.08),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: primaryText,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        hintStyle: TextStyle(
          color: mutedText,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: TextStyle(
          color: secondaryText,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        contentPadding:  EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.primary.withValues(alpha: 0.45);
            }
            return colorScheme.primary;
          }),
          foregroundColor: WidgetStatePropertyAll(textOnPrimary),
          elevation:  WidgetStatePropertyAll(0),
          padding:  WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          overlayColor: WidgetStatePropertyAll(
            textOnPrimary.withValues(alpha: 0.08),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(BorderSide(color: border)),
          backgroundColor: WidgetStatePropertyAll(surface.withValues(alpha: 0.72)),
          foregroundColor: WidgetStatePropertyAll(primaryText),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          padding:  WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(primaryText),
          overlayColor: WidgetStatePropertyAll(
            colorScheme.primary.withValues(alpha: 0.08),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(colorScheme.primary),
          foregroundColor: WidgetStatePropertyAll(textOnPrimary),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(secondaryText),
          backgroundColor: WidgetStatePropertyAll(surface),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              side: BorderSide(color: border),
            ),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        side: BorderSide(color: border),
        shape: StadiumBorder(),
        labelStyle: TextStyle(color: secondaryText),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          side: BorderSide(color: border),
        ),
        elevation: 0,
        backgroundColor: surface,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        position: PopupMenuPosition.under,
        menuPadding:  EdgeInsets.symmetric(vertical: 8),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: primaryText,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius + 6),
          side: BorderSide(color: border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surface,
        contentTextStyle: TextStyle(
          color: primaryText,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius + 4),
          side: BorderSide(color: border),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: secondaryText,
          fontSize: 12,
        ),
        dataTextStyle: TextStyle(
          color: primaryText,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        dividerThickness: 1,
        headingRowColor: WidgetStatePropertyAll(surfaceAlt),
        dataRowMinHeight: 44,
        dataRowMaxHeight: 52,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius + 8),
          side: BorderSide(color: border),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius + 8),
          side: BorderSide(color: border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: secondaryText,
        textColor: primaryText,
        tileColor: surface,
        selectedColor: colorScheme.primary,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return surfaceAlt;
        }),
        checkColor: WidgetStatePropertyAll(textOnPrimary),
        side: BorderSide(color: border),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return secondaryText;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.45);
          }
          return border;
        }),
        trackOutlineColor: WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: surfaceAlt,
        circularTrackColor: surfaceAlt,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: surfaceAlt,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: overlayShadow,
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          color: primaryText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surface),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
          shadowColor: WidgetStatePropertyAll(Colors.transparent),
          side: WidgetStatePropertyAll(BorderSide(color: border)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius + 6),
            ),
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: border,
        labelColor: primaryText,
        unselectedLabelColor: mutedText,
        indicatorColor: colorScheme.primary,
        labelStyle:  TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle:  TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
