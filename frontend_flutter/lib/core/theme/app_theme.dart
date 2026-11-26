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

  /// One-time entrance of highlight panels (fade + short slide).
  static const Duration entrance = Duration(milliseconds: 360);
  static const double entranceOffset = 16;
  static const Curve curve = Curves.easeOutCubic;
}

/// Glass variants: [dark] carries white text over colored backdrops (login,
/// home band); [light] carries dark text over light pages (top bar).
enum GlassTone { light, dark }

/// Glass surface parameters. Every value is checked for >=4.5:1 text
/// contrast against the worst-case backdrop in `theme_contrast_test.dart`.
abstract final class AppGlass {
  static const double blurSigma = 18;

  /// Light glass: white tint for bars over light pages.
  static const double lightOpacity = .68;
  static const double lightBorderOpacity = .80;

  /// Dark glass: a navy veil under a white tint. The tint alone (.10–.16)
  /// cannot keep white text at 4.5:1 when a bright glow sits behind it, so
  /// the veil darkens the backdrop first and the tint adds the frost.
  static const Color darkVeil = Color(0xFF061A33);
  static const double darkVeilOpacity = .42;
  static const double darkTintOpacity = .12;
  static const double darkBorderOpacity = .26;

  /// Extra white at the top edge: brighter stroke and a faint inner sheen.
  static const double highlightOpacity = .55;
  static const double darkSheenOpacity = .06;
  static const double lightSheenOpacity = .30;

  /// Active navigation item on the light bar: a brighter glass pill.
  static const double pillOpacity = .85;

  /// Fills without blur (`blur: false`, reduced motion, high contrast).
  static const double fallbackOpacity = .97;
  static const double darkFallbackOpacity = .94;

  /// Effective fill of a glass surface before compositing over the backdrop.
  static Color fill(
    GlassTone tone, {
    bool blurred = true,
    Color darkBase = darkVeil,
  }) {
    if (!blurred) {
      return tone == GlassTone.light
          ? Colors.white.withValues(alpha: fallbackOpacity)
          : darkBase.withValues(alpha: darkFallbackOpacity);
    }
    return tone == GlassTone.light
        ? Colors.white.withValues(alpha: lightOpacity)
        : Color.alphaBlend(
            Colors.white.withValues(alpha: darkTintOpacity),
            darkVeil.withValues(alpha: darkVeilOpacity),
          );
  }

  /// 1px stroke color at the bottom of the surface (the top is brighter).
  static Color border(GlassTone tone) => Colors.white.withValues(
    alpha: tone == GlassTone.light ? lightBorderOpacity : darkBorderOpacity,
  );

  /// Translucent fills for controls placed on dark glass. Fields sink
  /// (darker than the panel); secondary buttons rise (lighter).
  static Color darkControlFill({double tint = .10}) => Color.alphaBlend(
    Colors.white.withValues(alpha: tint),
    darkVeil.withValues(alpha: .20),
  );
  static const double fieldTint = .04;
  static const double fieldFocusTint = .08;
  static const double buttonTint = .10;
  static const double buttonHoverTint = .16;
}

/// A soft colored glow painted behind glass so the blur has something to show.
@immutable
class GlowSpot {
  const GlowSpot(this.color, this.opacity, this.center, this.radius);

  final Color color;

  /// Peak opacity at the center; it fades to zero at [radius].
  final double opacity;
  final Alignment center;

  /// Radius as a fraction of the painted area's shortest side.
  final double radius;
}

/// Backdrops placed behind glass. The contrast test composites all glows of
/// a set at their peak over the lightest stop (worst case: full overlap).
abstract final class AppBackdrop {
  // SENAI-derived accents for the admin profile.
  static const cyan = Color(0xFF22B5E8);
  static const violet = Color(0xFF7C5CFF);
  static const skyBlue = Color(0xFF5AA2FF);

  // Professor profile: deep aqua tones.
  static const aqua = Color(0xFF0FA89A);
  static const seaGreen = Color(0xFF12A676);
  static const lagoon = Color(0xFF2496C8);

  /// Login gradient, darker than [AppTheme.backdropFor] so colored glows
  /// stay vivid without lifting white text below 4.5:1.
  static List<Color> loginStopsFor(bool admin) => admin
      ? const [Color(0xFF031631), Color(0xFF052F5C)]
      : const [Color(0xFF032019), Color(0xFF08352F)];

  static List<GlowSpot> loginGlowsFor(bool admin) => admin
      ? const [
          // Two glows sit behind the form (right half) so its blur shows.
          GlowSpot(cyan, .26, Alignment(.4, -.6), .55),
          GlowSpot(violet, .32, Alignment(-.75, .6), .8),
          GlowSpot(skyBlue, .25, Alignment(.8, .65), .5),
        ]
      : const [
          GlowSpot(aqua, .28, Alignment(.4, -.6), .55),
          GlowSpot(seaGreen, .26, Alignment(-.75, .6), .8),
          GlowSpot(lagoon, .25, Alignment(.8, .65), .5),
        ];

  /// Subtle glows inside the home band (gradient = [AppTheme.backdropFor]).
  static List<GlowSpot> bandGlowsFor(bool admin) => admin
      ? const [
          GlowSpot(cyan, .16, Alignment(1, -1), 1.1),
          GlowSpot(violet, .20, Alignment(.35, 1.1), .9),
        ]
      : const [
          GlowSpot(aqua, .14, Alignment(1, -1), 1.1),
          GlowSpot(lagoon, .14, Alignment(.35, 1.1), .9),
        ];

  /// Page canvas behind the light top bar: very faint tints of the profile.
  static List<Color> pageStopsFor(bool admin) => admin
      ? const [Color(0xFFF1F5FB), AppTheme.background]
      : const [Color(0xFFEEF6F3), Color(0xFFF2F6F5)];

  static List<GlowSpot> pageGlowsFor(bool admin) => admin
      ? const [
          GlowSpot(skyBlue, .16, Alignment(-.9, -1), .9),
          GlowSpot(violet, .08, Alignment(1, -.9), .7),
        ]
      : const [
          GlowSpot(aqua, .14, Alignment(-.9, -1), .9),
          GlowSpot(lagoon, .08, Alignment(1, -.9), .7),
        ];
}

class AppTheme {
  AppTheme._();

  // Cool neutrals.
  static const navy = Color(0xFF0F223D);
  static const text = Color(0xFF152238);
  static const muted = Color(0xFF4C5A70);
  static const border = Color(0xFFDDE3EB);

  /// Separators and outlines that must stay visible on glass.
  static const borderStrong = Color(0xFFBCC7D4);
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

  /// Secondary text and icons on the light glass bar: [muted] drops below
  /// 4.5:1 when the dark home band scrolls under the bar.
  static const mutedStrong = Color(0xFF364256);

  /// Error text and outline on dark glass ([danger] is too dark there).
  static const onGlassError = Color(0xFFFFE9E6);
  static const onGlassErrorBorder = Color(0xFFFF8A80);

  static const tabularFigures = <FontFeature>[FontFeature.tabularFigures()];

  /// Profile of an ambient theme: [teacher] uses [teacherPrimary].
  static bool isAdminTheme(ThemeData theme) =>
      theme.colorScheme.primary != teacherPrimary;

  static Color headerFor(bool admin) => admin ? blue : teacherHeader;
  static Color accentFor(bool admin) => admin ? blue : teacherPrimary;

  /// Gradient stops (darkest first) for profile backdrops. Both stops keep
  /// white and [onBrandMuted] text at >=4.5:1, including the band glows.
  static List<Color> backdropFor(bool admin) =>
      admin ? const [blueDeep, blue] : const [teacherDeep, teacherPrimary];

  /// Primary action gradient (top, bottom): the accent fades into a deeper
  /// tone; white text stays >=4.5:1 on both stops plus the sheen.
  static List<Color> primaryGradientFor(bool admin) => admin
      ? const [blue, Color(0xFF05427F)]
      : const [teacherPrimary, Color(0xFF0E4F46)];

  /// Colored glow under the primary action.
  static Color primaryGlowFor(bool admin) =>
      admin ? const Color(0xFF3B9BFF) : const Color(0xFF2CC4A8);

  /// Bright outline for focused fields on dark glass and decorative icons
  /// (non-text: >=3:1). Text on dark glass uses [onBrand]/[onBrandMuted].
  static Color focusGlowFor(bool admin) =>
      admin ? const Color(0xFF9AD7FF) : const Color(0xFF8EEBD6);

  /// Theme for content on dark glass: white text, sunken translucent fields
  /// with a light outline, bright focus outline and light error color.
  static ThemeData onDarkGlass(ThemeData base, {required bool admin}) {
    final focus = focusGlowFor(admin);
    final textTheme = base.textTheme
        .apply(bodyColor: onBrand, displayColor: onBrand)
        .copyWith(
          bodySmall: base.textTheme.bodySmall?.copyWith(color: onBrandMuted),
        );
    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: color, width: width),
        );
    const labelStyle = TextStyle(
      color: onBrandMuted,
      fontWeight: FontWeight.w500,
    );
    return base.copyWith(
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: onBrandMuted),
      dividerColor: Colors.white.withValues(alpha: .22),
      hoverColor: Colors.white.withValues(alpha: .06),
      focusColor: Colors.white.withValues(alpha: .12),
      colorScheme: base.colorScheme.copyWith(
        onSurface: onBrand,
        onSurfaceVariant: onBrandMuted,
        outline: Colors.white.withValues(alpha: .45),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: onBrand,
        selectionColor: focus.withValues(alpha: .35),
        selectionHandleColor: focus,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: WidgetStateColor.resolveWith(
          (states) => AppGlass.darkControlFill(
            tint: states.contains(WidgetState.focused)
                ? AppGlass.fieldFocusTint
                : AppGlass.fieldTint,
          ),
        ),
        labelStyle: labelStyle,
        floatingLabelStyle: labelStyle,
        hintStyle: const TextStyle(
          color: onBrandMuted,
          fontWeight: FontWeight.w400,
        ),
        prefixIconColor: onBrandMuted,
        suffixIconColor: onBrandMuted,
        errorStyle: const TextStyle(
          color: onGlassError,
          fontSize: 12,
          height: 1.4,
        ),
        border: outline(Colors.white.withValues(alpha: .30)),
        enabledBorder: outline(Colors.white.withValues(alpha: .30)),
        focusedBorder: outline(focus, 2),
        errorBorder: outline(onGlassErrorBorder),
        focusedErrorBorder: outline(onGlassErrorBorder, 2),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: onBrand,
          overlayColor: Colors.white,
          minimumSize: const Size(48, 48),
          textStyle: base.textTheme.labelLarge?.copyWith(fontFamily: 'Roboto'),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: onBrandMuted,
          minimumSize: const Size(48, 48),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        side: const BorderSide(color: onBrandMuted, width: 1.5),
        checkColor: WidgetStatePropertyAll(base.colorScheme.primary),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? onBrand
              : Colors.transparent,
        ),
      ),
      listTileTheme: const ListTileThemeData(textColor: onBrand),
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: onBrand,
        collapsedIconColor: onBrandMuted,
        textColor: onBrand,
        collapsedTextColor: onBrand,
      ),
    );
  }

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
          side: const BorderSide(color: borderStrong),
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
