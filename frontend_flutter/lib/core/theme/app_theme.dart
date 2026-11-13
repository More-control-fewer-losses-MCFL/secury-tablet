import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const navy = Color(0xFF142C4B);
  static const blue = Color(0xFF075DA8);
  static const buttonBlue = blue;
  static const paleBlue = Color(0xFFEEF4FF);
  static const background = Color(0xFFF4F6FA);
  static const text = Color(0xFF172B45);
  static const muted = Color(0xFF526178);
  static const success = Color(0xFF12744C);
  static const danger = Color(0xFFB42332);
  static const warning = Color(0xFF95520B);
  static const border = Color(0xFFDDE4EE);

  static const teacherGreen = Color(0xFF3A9988);
  static const teacherHeader = Color(0xFF2C8375);
  static const teacherPrimary = Color(0xFF17695D);
  static const teacherSurface = Color(0xFFE8F5F0);

  static Color headerFor(bool admin) => admin ? blue : teacherHeader;

  static final ThemeData _adminTheme = _build(
    primary: blue,
    soft: paleBlue,
    canvas: background,
  );

  static ThemeData get light => _adminTheme;

  static final ThemeData _teacherTheme = _build(
    primary: teacherPrimary,
    soft: teacherSurface,
    canvas: const Color(0xFFF1F6F4),
  );

  static ThemeData get teacher => _teacherTheme;

  static ThemeData _build({
    required Color primary,
    required Color soft,
    required Color canvas,
  }) {
    final typography = ThemeData.light().textTheme.apply(
      bodyColor: text,
      displayColor: text,
    );
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      primaryContainer: soft,
      onPrimary: Colors.white,
      onPrimaryContainer: primary,
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
      scaffoldBackgroundColor: canvas,
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
          borderSide: BorderSide(color: primary, width: 2),
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
          backgroundColor: primary,
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
          foregroundColor: primary,
          side: BorderSide(color: primary),
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: shape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(48, 48),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 24,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: soft,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? primary : muted,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
