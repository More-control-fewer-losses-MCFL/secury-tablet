import 'package:flutter/material.dart';

/// Fixed spacing scale. Layouts use these values instead of ad hoc numbers.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Corner radii: controls, cards and highlight panels.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;

  static const BorderRadius control = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius panel = BorderRadius.all(Radius.circular(lg));
}

/// Two soft elevation levels; most surfaces rely on borders instead.
abstract final class AppShadows {
  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x0F0F223D), blurRadius: 12, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> raised = [
    BoxShadow(
      color: Color(0x290A1A33),
      blurRadius: 48,
      spreadRadius: -12,
      offset: Offset(0, 24),
    ),
  ];
}

/// Discreet transitions for hover, focus and state changes.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 250);
  static const Curve curve = Curves.easeOutCubic;
}

/// Glass surface parameters. Opacity is high enough for >=4.5:1 text
/// contrast over the darkest profile backdrop (see theme_contrast_test).
abstract final class AppGlass {
  static const double blurSigma = 16;
  static const double opacity = .86;
  static const double fallbackOpacity = .97;
  static const double borderOpacity = .55;

  /// Effective fill of a white glass surface before compositing.
  static Color fill({bool blurred = true, double? opacity}) =>
      Colors.white.withValues(
        alpha: blurred ? (opacity ?? AppGlass.opacity) : fallbackOpacity,
      );
}

class AppTheme {
  AppTheme._();

  // Cool neutrals.
  static const navy = Color(0xFF0F223D);
  static const text = Color(0xFF152238);
  static const muted = Color(0xFF4C5A70);
  static const border = Color(0xFFDDE3EB);
  static const background = Color(0xFFF3F5F8);
  static const surfaceMuted = Color(0xFFF8FAFC);

  // Administration profile (SENAI blue).
  static const blue = Color(0xFF075DA8);
  static const blueDeep = Color(0xFF052F5C);
  static const buttonBlue = blue;
  static const paleBlue = Color(0xFFEAF1FB);

  // Professor profile (green).
  static const teacherGreen = Color(0xFF3A9988);
  static const teacherHeader = Color(0xFF2C8375);
  static const teacherPrimary = Color(0xFF17695D);
  static const teacherDeep = Color(0xFF0B3F38);
  static const teacherSurface = Color(0xFFE6F3EE);

  // Semantic status colors (unchanged: validated contrast).
  static const success = Color(0xFF12744C);
  static const danger = Color(0xFFB42332);
  static const warning = Color(0xFF95520B);

  /// Text over a profile-colored backdrop.
  static const onBrand = Colors.white;
  static const onBrandMuted = Color(0xFFE6EFF8);

  static const tabularFigures = <FontFeature>[FontFeature.tabularFigures()];

  static Color headerFor(bool admin) => admin ? blue : teacherHeader;
  static Color accentFor(bool admin) => admin ? blue : teacherPrimary;

  /// Gradient stops (darkest first) for profile backdrops. Both stops keep
  /// white and [onBrandMuted] text at >=4.5:1, including the glows below.
  static List<Color> backdropFor(bool admin) =>
      admin ? const [blueDeep, blue] : const [teacherDeep, teacherPrimary];

  /// Maximum white overlay painted by decorative backdrop shapes.
  static const double backdropGlowOpacity = .08;

  static final ThemeData _adminTheme = _build(
    primary: blue,
    soft: paleBlue,
    canvas: background,
  );

  static ThemeData get light => _adminTheme;

  static final ThemeData _teacherTheme = _build(
    primary: teacherPrimary,
    soft: teacherSurface,
    canvas: const Color(0xFFF2F6F5),
  );

  static ThemeData get teacher => _teacherTheme;

  static TextTheme _textTheme() {
    final base = ThemeData.light().textTheme.apply(
      bodyColor: text,
      displayColor: text,
    );
    return base.copyWith(
      displaySmall: const TextStyle(
        fontSize: 44,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.4,
        color: text,
      ),
      headlineMedium: const TextStyle(
        fontSize: 30,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -.8,
        color: text,
      ),
      headlineSmall: const TextStyle(
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -.5,
        color: text,
      ),
      titleLarge: const TextStyle(
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -.2,
        color: text,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w600,
        letterSpacing: -.1,
        color: text,
      ),
      titleSmall: const TextStyle(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      bodyLarge: const TextStyle(fontSize: 16, height: 1.5, color: text),
      bodyMedium: const TextStyle(fontSize: 14, height: 1.5, color: text),
      bodySmall: const TextStyle(fontSize: 12, height: 1.5, color: muted),
      labelLarge: const TextStyle(
        fontSize: 14,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: .1,
      ),
      labelMedium: const TextStyle(
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: .2,
      ),
      // Eyebrow / overline: uppercase strings, one tracking for the whole app.
      labelSmall: const TextStyle(
        fontSize: 11,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }

  static ThemeData _build({
    required Color primary,
    required Color soft,
    required Color canvas,
  }) {
    final textTheme = _textTheme();
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      primaryContainer: soft,
      onPrimary: Colors.white,
      onPrimaryContainer: primary,
      surface: Colors.white,
      onSurface: text,
      onSurfaceVariant: muted,
      outline: border,
      outlineVariant: border,
      error: danger,
    );
    const controlShape = RoundedRectangleBorder(
      borderRadius: AppRadius.control,
    );
    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: color, width: width),
        );
    final buttonText = textTheme.labelLarge?.copyWith(fontFamily: 'Roboto');
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: textTheme,
      focusColor: primary.withValues(alpha: .12),
      hoverColor: primary.withValues(alpha: .06),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        labelStyle: const TextStyle(color: muted, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: muted, fontWeight: FontWeight.w400),
        prefixIconColor: muted,
        errorMaxLines: 3,
        helperMaxLines: 3,
        errorStyle: const TextStyle(color: danger, fontSize: 12, height: 1.4),
        border: inputBorder(border),
        enabledBorder: inputBorder(border),
        focusedBorder: inputBorder(primary, 2),
        errorBorder: inputBorder(danger),
        focusedErrorBorder: inputBorder(danger, 2),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: border),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.panel),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          textStyle: buttonText,
          shape: controlShape,
          animationDuration: AppMotion.fast,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border),
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md + AppSpacing.xxs,
            vertical: AppSpacing.md,
          ),
          textStyle: buttonText,
          shape: controlShape,
          animationDuration: AppMotion.fast,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(48, 48),
          textStyle: buttonText,
          shape: controlShape,
          animationDuration: AppMotion.fast,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(48, 48),
          animationDuration: AppMotion.fast,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: AppSpacing.lg,
      ),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(color: navy, borderRadius: AppRadius.control),
        textStyle: TextStyle(color: Colors.white, fontSize: 12),
        waitDuration: Duration(milliseconds: 400),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: navy,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.control),
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
