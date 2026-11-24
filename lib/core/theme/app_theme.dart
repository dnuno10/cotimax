import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/constants/app_spacing.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Muse-inspired theme: Inter (SF-like) typography, near-white surfaces,
/// pill-shaped buttons, borderless filled inputs and large soft radii.
class AppTheme {
  static ThemeData light() =>
      _buildTheme(AppColors.lightPalette, Brightness.light);

  static ThemeData dark() =>
      _buildTheme(AppColors.darkPalette, Brightness.dark);

  static TextStyle _font({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  static ThemeData _buildTheme(AppColorPalette p, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final stadium = WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder());
    // Flat UI: no elevation shadows anywhere.
    final floatingShadowColor = Colors.transparent;
    final hairline = BorderSide(color: p.border);
    const motion = Duration(milliseconds: 260);

    final textTheme = GoogleFonts.interTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    ).apply(bodyColor: p.textPrimary, displayColor: p.textPrimary);

    final baseText = textTheme.copyWith(
      displaySmall: _font(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: p.textPrimary,
        height: 1.05,
        letterSpacing: -0.8,
      ),
      headlineLarge: _font(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: p.textPrimary,
        height: 1.05,
        letterSpacing: -0.7,
      ),
      headlineMedium: _font(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: p.textPrimary,
        height: 1.1,
        letterSpacing: -0.5,
      ),
      titleLarge: _font(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: p.textPrimary,
        letterSpacing: -0.2,
      ),
      titleMedium: _font(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: p.textPrimary,
      ),
      bodyLarge: _font(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: p.textPrimary,
        height: 1.45,
      ),
      bodyMedium: _font(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: p.textPrimary,
        height: 1.4,
      ),
      bodySmall: _font(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        color: p.textSecondary,
      ),
      labelLarge: _font(fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: _font(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        color: p.textSecondary,
      ),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: p.primary,
      brightness: brightness,
      primary: p.primary,
      onPrimary: Colors.white,
      secondary: p.accent,
      surface: p.container,
      onSurface: p.textPrimary,
      surfaceContainerHighest: p.muted,
      error: p.error,
      outline: p.border,
      outlineVariant: p.border,
    );

    final buttonText = WidgetStatePropertyAll(
      _font(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.1),
    );
    final buttonPadding = WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      borderSide: BorderSide(color: p.border),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: baseText,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.container,
      shadowColor: Colors.transparent,
      splashFactory: InkRipple.splashFactory,
      splashColor: p.textPrimary.withValues(alpha: 0.04),
      highlightColor: Colors.transparent,
      hoverColor: p.hover,
      focusColor: p.primary.withValues(alpha: 0.10),
      dividerColor: p.border,
      fontFamily: GoogleFonts.inter().fontFamily,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        color: p.container,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: BorderSide(color: p.border),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: p.textPrimary,
        titleTextStyle: _font(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
        ),
      ),
      // Inputs: soft gray fill + hairline, like the call-card inner panels.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.muted,
        hoverColor: Colors.transparent,
        hintStyle: _font(
          color: p.textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: _font(
          color: p.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: _font(
          color: p.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        helperStyle: _font(color: p.textMuted, fontSize: 12),
        errorStyle: _font(color: p.error, fontSize: 12),
        prefixIconColor: p.textMuted,
        suffixIconColor: p.textMuted,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: p.border.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          borderSide: BorderSide(
            color: p.primary.withValues(alpha: 0.6),
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          borderSide: BorderSide(color: p.error.withValues(alpha: 0.6)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          borderSide: BorderSide(color: p.error, width: 1.4),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.primary,
        selectionColor: p.primary.withValues(alpha: 0.18),
        selectionHandleColor: p.primary,
      ),
      // Primary CTA: solid blue pill (Muse "Generate").
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          animationDuration: motion,
          elevation: WidgetStatePropertyAll(0),
          shadowColor: WidgetStatePropertyAll(Colors.transparent),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return p.primary.withValues(alpha: 0.40);
            }
            if (states.contains(WidgetState.hovered)) {
              return Color.alphaBlend(
                Colors.black.withValues(alpha: 0.05),
                p.primary,
              );
            }
            return p.primary;
          }),
          foregroundColor: WidgetStatePropertyAll(Colors.white),
          iconColor: WidgetStatePropertyAll(Colors.white),
          padding: buttonPadding,
          minimumSize: WidgetStatePropertyAll(Size(0, 44)),
          shape: stadium,
          textStyle: buttonText,
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      // Secondary: soft gray pill, no border (Muse "Edit").
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          animationDuration: motion,
          side: WidgetStatePropertyAll(BorderSide.none),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return p.muted.withValues(alpha: 0.6);
            }
            if (states.contains(WidgetState.hovered)) {
              return Color.alphaBlend(
                p.textPrimary.withValues(alpha: 0.03),
                p.muted,
              );
            }
            return p.muted;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return p.textMuted;
            return p.textPrimary;
          }),
          iconColor: WidgetStatePropertyAll(p.textPrimary),
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
          shape: stadium,
          textStyle: buttonText,
          padding: buttonPadding,
          minimumSize: WidgetStatePropertyAll(Size(0, 44)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          animationDuration: motion,
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return p.textMuted;
            return p.textPrimary;
          }),
          iconColor: WidgetStatePropertyAll(p.textPrimary),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return p.hover;
            return Colors.transparent;
          }),
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
          shape: stadium,
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          textStyle: buttonText,
        ),
      ),
      // Filled: ink pill (dark play / send button).
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          animationDuration: motion,
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return p.ink.withValues(alpha: 0.35);
            }
            return p.ink;
          }),
          foregroundColor: WidgetStatePropertyAll(p.onInk),
          iconColor: WidgetStatePropertyAll(p.onInk),
          shape: stadium,
          padding: buttonPadding,
          minimumSize: WidgetStatePropertyAll(Size(0, 44)),
          textStyle: buttonText,
          overlayColor: WidgetStatePropertyAll(p.onInk.withValues(alpha: 0.08)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          animationDuration: motion,
          iconColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return p.textMuted.withValues(alpha: 0.6);
            }
            return p.textPrimary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return p.textMuted.withValues(alpha: 0.6);
            }
            return p.textPrimary;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return p.hover;
            return Colors.transparent;
          }),
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(CircleBorder()),
          minimumSize: WidgetStatePropertyAll(Size(40, 40)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.ink,
        foregroundColor: p.onInk,
        elevation: 0,
        highlightElevation: 0,
        shape: CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.muted,
        selectedColor: p.ink,
        secondarySelectedColor: p.ink,
        disabledColor: p.muted.withValues(alpha: 0.5),
        checkmarkColor: p.onInk,
        side: BorderSide.none,
        shape: StadiumBorder(),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: _font(
          color: p.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: _font(
          color: p.onInk,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.dialogRadius),
          side: hairline,
        ),
        elevation: 0,
        shadowColor: floatingShadowColor,
        surfaceTintColor: Colors.transparent,
        backgroundColor: p.container,
        barrierColor: Colors.black.withValues(alpha: isDark ? 0.5 : 0.18),
        titleTextStyle: _font(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
          letterSpacing: -0.2,
        ),
        contentTextStyle: _font(
          fontSize: 14,
          color: p.textSecondary,
          height: 1.45,
        ),
        actionsPadding: EdgeInsets.fromLTRB(24, 0, 24, 20),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.container,
        surfaceTintColor: Colors.transparent,
        shadowColor: floatingShadowColor,
        elevation: 0,
        position: PopupMenuPosition.under,
        menuPadding: EdgeInsets.all(6),
        textStyle: _font(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: p.textPrimary,
        ),
        labelTextStyle: WidgetStatePropertyAll(
          _font(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: p.textPrimary,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: hairline,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(p.container),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
          elevation: WidgetStatePropertyAll(0),
          side: WidgetStatePropertyAll(hairline),
          shadowColor: WidgetStatePropertyAll(floatingShadowColor),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.ink,
        elevation: 0,
        contentTextStyle: _font(
          color: p.onInk,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        shape: StadiumBorder(),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: _font(
          fontWeight: FontWeight.w500,
          color: p.textSecondary,
          fontSize: 12.5,
        ),
        dataTextStyle: _font(
          color: p.textPrimary,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        dividerThickness: 1,
        headingRowColor: WidgetStatePropertyAll(Colors.transparent),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return p.primary.withValues(alpha: 0.06);
          }
          if (states.contains(WidgetState.hovered)) return p.hover;
          return Colors.transparent;
        }),
        headingRowHeight: 44,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 60,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.container,
        modalBackgroundColor: p.container,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.mutedStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.dialogRadius),
          ),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: p.container,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: floatingShadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(AppSpacing.dialogRadius),
          ),
        ),
        endShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(AppSpacing.dialogRadius),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: p.textPrimary,
        textColor: p.textPrimary,
        tileColor: Colors.transparent,
        selectedColor: p.textPrimary,
        selectedTileColor: p.muted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.symmetric(horizontal: 14),
        titleTextStyle: _font(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: p.textPrimary,
        ),
        subtitleTextStyle: _font(fontSize: 13, color: p.textSecondary),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        iconColor: p.textSecondary,
        collapsedIconColor: p.textSecondary,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(Colors.white),
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BorderSide(color: p.primary, width: 1.5);
          }
          return BorderSide(color: p.textMuted, width: 1.5);
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.primary;
          return p.textMuted;
        }),
      ),
      // iOS-like switch: white thumb, green track, no outline.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.success;
          return p.mutedStrong;
        }),
        trackOutlineColor: WidgetStatePropertyAll(Colors.transparent),
        overlayColor: WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.textPrimary,
        linearTrackColor: p.muted,
        circularTrackColor: Colors.transparent,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.success,
        inactiveTrackColor: p.mutedStrong,
        thumbColor: p.success,
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: Duration(milliseconds: 500),
        exitDuration: Duration(milliseconds: 120),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: p.ink,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: _font(
          color: p.onInk,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(p.container),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
          shadowColor: WidgetStatePropertyAll(floatingShadowColor),
          elevation: WidgetStatePropertyAll(0),
          side: WidgetStatePropertyAll(hairline),
          padding: WidgetStatePropertyAll(EdgeInsets.all(6)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ),
      // Segmented look: white raised pill on a muted track.
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelColor: p.textPrimary,
        unselectedLabelColor: p.textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: p.container,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: p.border),
        ),
        overlayColor: WidgetStatePropertyAll(Colors.transparent),
        labelStyle: _font(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: _font(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.container,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: floatingShadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.dialogRadius),
          side: hairline,
        ),
        headerBackgroundColor: p.container,
        headerForegroundColor: p.textPrimary,
        dividerColor: p.border,
        todayBorder: BorderSide(color: p.primary, width: 1.2),
        dayShape: WidgetStatePropertyAll(CircleBorder()),
        cancelButtonStyle: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(p.textPrimary),
          shape: stadium,
        ),
        confirmButtonStyle: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(p.primary),
          shape: stadium,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(p.textMuted.withValues(alpha: 0.45)),
        radius: Radius.circular(999),
        thickness: WidgetStatePropertyAll(6),
      ),
    );
  }
}
