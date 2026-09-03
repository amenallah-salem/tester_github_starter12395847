import 'package:flutter/material.dart';

/// Design system for Milestone 1, matching the TES-6 clickable prototype.
/// Dark-first: bg #0f1115, surface #171a21, card #20242e, ink #f4f6fb,
/// muted #9aa3b2, brand #5b8cff, accent #7be0a6, warn #ffb454, line #2b3140.
class AppTheme {
  static const bg = Color(0xFF0F1115);
  static const surface = Color(0xFF171A21);
  static const card = Color(0xFF20242E);
  static const ink = Color(0xFFF4F6FB);
  static const mut = Color(0xFF9AA3B2);
  static const brand = Color(0xFF5B8CFF);
  static const accent = Color(0xFF7BE0A6);
  static const warn = Color(0xFFFFB454);
  static const line = Color(0xFF2B3140);

  static final _inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: line),
  );

  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      surface: bg,
      primary: brand,
      secondary: accent,
      error: warn,
      onSurface: ink,
      onPrimary: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      foregroundColor: ink,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      color: card,
      surfaceTintColor: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: line),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: brand,
      unselectedItemColor: mut,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: brand,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: const BorderSide(color: line),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: _inputBorder,
      enabledBorder: _inputBorder,
      focusedBorder: _inputBorder.copyWith(
        borderSide: const BorderSide(color: brand),
      ),
      labelStyle: const TextStyle(color: mut),
    ),
    dividerColor: line,
    chipTheme: ChipThemeData(
      backgroundColor: card,
      side: const BorderSide(color: line),
      labelStyle: const TextStyle(color: ink),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selectedColor: brand,
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: accent),
  );

  /// Light variant kept for completeness; M1 ships dark-first.
  static final light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: brand,
      secondary: accent,
      brightness: Brightness.light,
    ),
  );
}
