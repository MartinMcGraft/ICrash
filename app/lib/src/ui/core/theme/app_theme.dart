import 'package:flutter/material.dart';

import 'tokens.dart';

/// Material theme built from the v2 tokens, so stock Material widgets
/// (dialogs, snackbars, date pickers, menus) match the custom components.
ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: IcColors.actionPrimary,
    onPrimary: IcColors.textOnDark,
    primaryContainer: IcColors.navy50,
    onPrimaryContainer: IcColors.navy800,
    secondary: IcColors.navy600,
    onSecondary: IcColors.textOnDark,
    secondaryContainer: IcColors.navy100,
    onSecondaryContainer: IcColors.navy900,
    tertiary: IcColors.amber700,
    onTertiary: IcColors.textOnDark,
    error: IcColors.dangerFg,
    onError: IcColors.textOnDark,
    errorContainer: IcColors.dangerBg,
    onErrorContainer: IcColors.red800,
    surface: IcColors.bgSurface,
    onSurface: IcColors.textPrimary,
    onSurfaceVariant: IcColors.textSecondary,
    surfaceContainerLowest: IcColors.bgSurface,
    surfaceContainerLow: IcColors.warm25,
    surfaceContainer: IcColors.bgCanvas,
    surfaceContainerHigh: IcColors.bgSurfaceMuted,
    surfaceContainerHighest: IcColors.bgSurfaceSunken,
    outline: IcColors.borderStrong,
    outlineVariant: IcColors.borderDefault,
    shadow: Color(0xFF1E1D1A),
    inverseSurface: IcColors.warm900,
    onInverseSurface: IcColors.warm0,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: IcFonts.sans,
    scaffoldBackgroundColor: IcColors.bgCanvas,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );

  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(IcRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displaySmall: IcText.display,
      headlineSmall: IcText.titleL,
      titleLarge: IcText.titleM,
      titleMedium: IcText.titleS,
      titleSmall: IcText.labelM,
      bodyLarge: IcText.bodyL,
      bodyMedium: IcText.bodyM,
      bodySmall: IcText.bodyS,
      labelLarge: IcText.labelM,
      labelMedium: IcText.labelS,
      labelSmall: IcText.labelS,
    ),
    dividerTheme: const DividerThemeData(color: IcColors.borderDefault, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: IcColors.bgSurface,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      hintStyle: IcText.bodyM.copyWith(color: IcColors.textMuted),
      labelStyle: IcText.labelS.copyWith(color: IcColors.textSecondary),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      border: border(IcColors.borderStrong, 1),
      enabledBorder: border(IcColors.borderStrong, 1),
      focusedBorder: border(IcColors.borderFocus, 2),
      errorBorder: border(IcColors.dangerFg, 2),
      focusedErrorBorder: border(IcColors.dangerFg, 2),
      errorStyle: IcText.bodyS.copyWith(color: IcColors.dangerFg),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: IcColors.actionPrimary,
        foregroundColor: IcColors.textOnDark,
        minimumSize: const Size(64, IcSize.touchMin),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: IcText.labelM,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(IcRadius.md)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: IcColors.textPrimary,
        minimumSize: const Size(64, IcSize.touchMin),
        side: const BorderSide(color: IcColors.borderStrong, width: 1.5),
        textStyle: IcText.labelM,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(IcRadius.md)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: IcColors.textLink,
        minimumSize: const Size(48, IcSize.touchMin),
        textStyle: IcText.labelM,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(IcRadius.md)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: IcColors.bgSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(IcRadius.lg)),
      titleTextStyle: IcText.titleM,
      contentTextStyle: IcText.bodyM,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: IcColors.warm900,
      contentTextStyle: IcText.bodyM.copyWith(color: IcColors.textOnDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(IcRadius.md)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: IcColors.bgSurface,
      surfaceTintColor: Colors.transparent,
      textStyle: IcText.bodyM,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(IcRadius.md),
        side: const BorderSide(color: IcColors.borderDefault),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? IcColors.okFg : IcColors.bgSurface,
      ),
      side: const BorderSide(color: IcColors.borderStrong, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(IcRadius.sm)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: IcColors.actionPrimary),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: IcColors.bgSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(IcRadius.lg)),
    ),
  );
}
