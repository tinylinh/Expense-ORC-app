import 'package:flutter/material.dart';

class AppTheme {
  static const Color accent = Color(0xFF72C9E8);
  static const Color green = Color(0xFF079B61);
  static const Color red = Color(0xFFE8483F);
  static const Color ink = Color(0xFF121416);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      primary: isDark ? const Color(0xFF8DDCF5) : ink,
      surface: isDark ? const Color(0xFF181A1C) : Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF101112)
          : const Color(0xFFF7F7F8),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? const Color(0xFF101112)
            : const Color(0xFFF7F7F8),
        foregroundColor: isDark ? Colors.white : ink,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
