import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const navy = Color(0xFF142C4B);
  static const blue = Color(0xFF1D4ED8);
  static const buttonBlue = blue;
  static const paleBlue = Color(0xFFEEF4FF);
  static const background = Color(0xFFF4F6FA);
  static const text = Color(0xFF172B45);
  static const muted = Color(0xFF526178);
  static const success = Color(0xFF12744C);
  static const danger = Color(0xFFB42332);
  static const warning = Color(0xFF95520B);
  static const border = Color(0xFFDDE4EE);

  static ThemeData get light {
    final typography = ThemeData.light().textTheme.apply(
      bodyColor: text,
      displayColor: text,
    );
    final scheme = ColorScheme.fromSeed(
      seedColor: blue,
      primary: blue,
      surface: Colors.white,
      error: danger,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: typography.copyWith(
        headlineMedium: const TextStyle(
          fontSize: 30,
          height: 1.2,
          fontWeight: FontWeight.w800,
          color: text,
          letterSpacing: -.6,
        ),
        headlineSmall: const TextStyle(
          fontSize: 25,
          height: 1.25,
          fontWeight: FontWeight.w700,
          color: text,
          letterSpacing: -.4,
        ),
        titleLarge: const TextStyle(
          fontSize: 21,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        titleMedium: const TextStyle(
          fontSize: 17,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        bodyLarge: const TextStyle(fontSize: 16, height: 1.5, color: text),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.5, color: text),
        bodySmall: const TextStyle(fontSize: 12, height: 1.5, color: muted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: const Color(0xFFFAFBFD),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: muted),
        hintStyle: const TextStyle(color: muted, fontWeight: FontWeight.w400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: blue, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: blue,
          side: const BorderSide(color: blue),
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: shape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 24,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: paleBlue,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? blue : muted,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
