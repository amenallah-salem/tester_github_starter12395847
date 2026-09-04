import 'package:flutter/material.dart';

/// Welora theme: light cream bg, dark green primary, terracotta tertiary.
/// Per Stitch design: rounded-2xl cards, material symbols icons, Plus Jakarta Sans.
class AppTheme {
  // Background palette
  static const bg = Color(0xFFF1FCF3);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFEBF7ED);
  static const surfaceContainer = Color(0xFFE5F1E7);
  static const surfaceContainerHigh = Color(0xFFE0EBE2);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);

  // Brand: dark forest green
  static const primary = Color(0xFF32533C);
  static const primaryContainer = Color(0xFFC7ECCE);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFFC5EACC);

  // Secondary green
  static const secondary = Color(0xFF446651);
  static const secondaryContainer = Color(0xFFC3E9CF);
  static const secondaryFixed = Color(0xFFC6EBD1);

  // Tertiary terracotta accent
  static const tertiary = Color(0xFF7A391D);
  static const tertiaryContainer = Color(0xFFFFDBCE);
  static const tertiaryFixed = Color(0xFFFFDBCE);
  static const onTertiary = Color(0xFFFFFFFF);
  static const onTertiaryContainer = Color(0xFFFFD9CC);

  // Text
  static const ink = Color(0xFF141E18);
  static const onSurfaceVariant = Color(0xFF424842);
  static const mut = Color(0xFF727972);
  static const outline = Color(0xFFC2C8C0);
  static const outlineVariant = Color(0xFFDAE5DC);

  // Accents
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);

  // Border radii (per design: lg=2rem, full=9999px)
  static const radiusLg = 32.0;
  static const radiusXl = 48.0;
  static const radiusPill = 999.0;

  static final _inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(28),
    borderSide: const BorderSide(color: outline),
  );

  static final _darkInputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(28),
    borderSide: const BorderSide(color: Color(0xFF3D4A41)),
  );

  static const _fontFamily = 'Plus Jakarta Sans';

  static final light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: _fontFamily,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.light(
      surface: surface,
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      error: error,
      onSurface: ink,
      onPrimary: onPrimary,
      onSecondary: onPrimary,
      onTertiary: onTertiary,
      primaryContainer: primaryContainer,
      secondaryContainer: secondaryContainer,
      tertiaryContainer: tertiaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      onSecondaryContainer: Color(0xFF496A55),
      onTertiaryContainer: onTertiaryContainer,
      errorContainer: errorContainer,
      onError: Colors.white,
      outline: outline,
      outlineVariant: outlineVariant,
      surfaceContainerLowest: surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      foregroundColor: ink,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        side: const BorderSide(color: outlineVariant),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: mut,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: const BorderSide(color: outlineVariant),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceContainerLowest,
      border: _inputBorder,
      enabledBorder: _inputBorder,
      focusedBorder: _inputBorder.copyWith(
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      labelStyle: const TextStyle(color: mut),
      hintStyle: const TextStyle(color: mut),
    ),
    dividerColor: outlineVariant,
    chipTheme: ChipThemeData(
      backgroundColor: surfaceContainerLowest,
      side: const BorderSide(color: outlineVariant),
      labelStyle: const TextStyle(color: ink),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusPill),
      ),
      selectedColor: primary,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
  );

  /// Dark variant — complete ColorScheme (per Material 3 spec).
  /// Avoids runtime errors that would surface if any required token is missing.
  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: _fontFamily,
    scaffoldBackgroundColor: const Color(0xFF121A14),
    colorScheme: const ColorScheme.dark(
      surface: Color(0xFF121A14),
      primary: primaryContainer,
      onPrimary: Color(0xFF01210F),
      primaryContainer: Color(0xFF1B3A26),
      onPrimaryContainer: Color(0xFFC5EACC),
      secondary: secondaryFixed,
      onSecondary: Color(0xFF1B3A26),
      secondaryContainer: Color(0xFF2C4A37),
      onSecondaryContainer: Color(0xFFC6EBD1),
      secondaryFixed: Color(0xFFC6EBD1),
      tertiary: tertiaryFixed,
      onTertiary: Color(0xFF3D1A0B),
      tertiaryContainer: Color(0xFF7A391D),
      onTertiaryContainer: Color(0xFFFFD9CC),
      tertiaryFixed: Color(0xFFFFDBCE),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      onSurface: Color(0xFFE8F4EA),
      onSurfaceVariant: Color(0xFFA8B3AB),
      outline: Color(0xFF6B776F),
      outlineVariant: Color(0xFF3D4A41),
      surfaceContainerLowest: Color(0xFF0A1209),
      surfaceContainerLow: Color(0xFF1A231B),
      surfaceContainer: Color(0xFF1E2820),
      surfaceContainerHigh: Color(0xFF293326),
      surfaceContainerHighest: Color(0xFF343E30),
      inverseSurface: Color(0xFFE8F4EA),
      onInverseSurface: Color(0xFF141E18),
      inversePrimary: primary,
      shadow: Colors.black,
      scrim: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121A14),
      foregroundColor: Color(0xFFE8F4EA),
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A231B),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        side: const BorderSide(color: Color(0xFF3D4A41)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1A231B),
      selectedItemColor: primaryContainer,
      unselectedItemColor: Color(0xFFA8B3AB),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryContainer,
        foregroundColor: const Color(0xFF01210F),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFE8F4EA),
        side: const BorderSide(color: Color(0xFF3D4A41)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A231B),
      border: _darkInputBorder,
      enabledBorder: _darkInputBorder,
      focusedBorder: _darkInputBorder.copyWith(
        borderSide: const BorderSide(color: primaryContainer, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Color(0xFFA8B3AB)),
      hintStyle: const TextStyle(color: Color(0xFFA8B3AB)),
    ),
    dividerColor: const Color(0xFF3D4A41),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF1A231B),
      side: const BorderSide(color: Color(0xFF3D4A41)),
      labelStyle: const TextStyle(color: Color(0xFFE8F4EA)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusPill),
      ),
      selectedColor: primaryContainer,
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: primaryContainer),
  );
}
