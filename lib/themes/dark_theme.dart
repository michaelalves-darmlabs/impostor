import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tema escuro do aplicativo com Material 3.
ThemeData get darkTheme {
  final scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: kDarkPrimary,
    onPrimary: kDarkTextPrimary,
    primaryContainer: Color(0xFFAA3333),
    onPrimaryContainer: kDarkTextPrimary,
    secondary: kDarkSecondary,
    onSecondary: kDarkTextPrimary,
    secondaryContainer: Color(0xFF5A8C6F),
    onSecondaryContainer: kDarkTextPrimary,
    tertiary: Color(0xFF4B0082),
    onTertiary: kDarkTextPrimary,
    tertiaryContainer: Color(0xFF6B2DAA),
    onTertiaryContainer: kDarkTextPrimary,
    error: kDarkError,
    onError: kDarkTextPrimary,
    errorContainer: Color(0xFFBB3333),
    onErrorContainer: kDarkTextPrimary,
    background: kDarkBackground,
    onBackground: kDarkTextPrimary,
    surface: kDarkSurface,
    onSurface: kDarkTextPrimary,
    surfaceVariant: Color(0xFF3A2A32),
    onSurfaceVariant: kDarkTextSecondary,
    outline: Color(0xFF8A7A82),
    scrim: Color(0xFF000000),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: kDarkBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: kDarkSurface,
      foregroundColor: kDarkTextPrimary,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.outline),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    ),
    cardTheme: CardThemeData(
      color: kDarkSurface,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceVariant.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outline.withOpacity(0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outline.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant.withOpacity(0.7)),
    ),
    drawerTheme: DrawerThemeData(backgroundColor: kDarkSurface, elevation: 1),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      elevation: 4,
    ),
  );
}
