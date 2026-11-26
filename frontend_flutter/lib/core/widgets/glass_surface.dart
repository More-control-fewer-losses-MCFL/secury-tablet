import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Translucent "frosted glass" surface: backdrop blur, tinted fill, 1px light
/// border brighter at the top edge, faint top sheen and a soft shadow.
///
/// Use only for highlight surfaces (login form, top bar, hero cards). Tables,
/// long lists and long forms stay on opaque cards for legibility. Each screen
/// keeps at most two blurred surfaces (see docs/frontend-ux.md).
///
/// [GlassTone.dark] carries white text over colored backdrops;
/// [GlassTone.light] carries dark text over light pages.
///
/// Blur is skipped — and the fill becomes nearly opaque — when [blur] is
/// false (e.g. totem on modest hardware) or when the platform asks for
/// reduced motion or high contrast. Dark glass then falls back to
/// [fallbackColor] (default: the navy veil) so white text stays readable.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    required this.child,
    this.tone = GlassTone.light,
    this.blur = true,
    this.sigma = AppGlass.blurSigma,
    this.fill,
    this.fallbackColor,
    this.highlight = true,
    this.borderRadius = AppRadius.panel,
    this.borderColor,
    this.shadows = AppShadows.raised,
    this.padding,
    super.key,
  }) : assert(sigma >= 0 && sigma <= 30);

  final Widget child;
  final GlassTone tone;
  final bool blur;
  final double sigma;

  /// Overrides the blurred fill of [tone] (e.g. a fainter decorative glass).
  final Color? fill;

  /// Opaque base for dark glass without blur; ignored for light glass.
  final Color? fallbackColor;

  /// Brighter top stroke and inner sheen.
  final bool highlight;
  final BorderRadius borderRadius;

  /// Solid stroke replacing the default translucent one (no gradient).
  final Color? borderColor;
  final List<BoxShadow> shadows;
  final EdgeInsetsGeometry? padding;

  /// Whether effects should be reduced for accessibility.
  static bool reduceEffects(BuildContext context) =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
      (MediaQuery.maybeHighContrastOf(context) ?? false);

  @override
  Widget build(BuildContext context) {
    final blurred = blur && sigma > 0 && !reduceEffects(context);
    final color = blurred
        ? fill ?? AppGlass.fill(tone)
        : AppGlass.fill(
            tone,
            blurred: false,
            darkBase: fallbackColor ?? AppGlass.darkVeil,
          );
    final sheen = tone == GlassTone.light
        ? AppGlass.lightSheenOpacity
        : AppGlass.darkSheenOpacity;
    final bottomStroke = borderColor ?? AppGlass.border(tone);
    final topStroke =
        borderColor ??
        Colors.white.withValues(
          alpha: tone == GlassTone.light ? 1 : AppGlass.highlightOpacity,
        );
    Widget content = padding == null
        ? child
        : Padding(padding: padding!, child: child);
    if (highlight && blurred) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: const Alignment(0, -.2),
            colors: [
              Colors.white.withValues(alpha: sheen),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
        child: content,
      );
    }
    final surface = DecoratedBox(
      decoration: BoxDecoration(color: color, borderRadius: borderRadius),
      child: CustomPaint(
        foregroundPainter: _GlassStroke(
          borderRadius: borderRadius,
          top: highlight ? topStroke : bottomStroke,
          bottom: bottomStroke,
        ),
        child: content,
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadows),
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: borderRadius,
          child: blurred
              ? BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  child: surface,
                )
              : surface,
        ),
      ),
    );
  }
}

/// 1px rounded stroke with a vertical gradient: light catches the top edge.
class _GlassStroke extends CustomPainter {
  const _GlassStroke({
    required this.borderRadius,
    required this.top,
    required this.bottom,
  });

  final BorderRadius borderRadius;
  final Color top;
  final Color bottom;

  @override
  void paint(Canvas canvas, Size size) {
    if (top.a == 0 && bottom.a == 0) return;
    final rect = (Offset.zero & size).deflate(.5);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, bottom],
        stops: const [0, .6],
      ).createShader(rect);
    canvas.drawRRect(borderRadius.toRRect(rect), paint);
  }

  @override
  bool shouldRepaint(_GlassStroke oldDelegate) =>
      oldDelegate.top != top ||
      oldDelegate.bottom != bottom ||
      oldDelegate.borderRadius != borderRadius;
}
