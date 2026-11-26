import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Translucent "glass" surface: backdrop blur, white tint, 1px light border.
///
/// Use only for highlight surfaces (login form, top bar, hero cards). Tables,
/// long lists and long forms stay on opaque cards for legibility.
///
/// Blur is skipped — and the fill becomes nearly opaque — when [blur] is
/// false (e.g. totem on modest hardware) or when the platform asks for
/// reduced motion or high contrast.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    required this.child,
    this.blur = true,
    this.sigma = AppGlass.blurSigma,
    this.opacity = AppGlass.opacity,
    this.fallbackOpacity = AppGlass.fallbackOpacity,
    this.tint = Colors.white,
    this.borderRadius = AppRadius.panel,
    this.borderColor,
    this.shadows = AppShadows.raised,
    this.padding,
    super.key,
  }) : assert(sigma >= 0 && sigma <= 30),
       assert(opacity >= 0 && opacity <= 1),
       assert(fallbackOpacity >= 0 && fallbackOpacity <= 1);

  final Widget child;
  final bool blur;
  final double sigma;
  final double opacity;

  /// Fill opacity used when blur is not applied. Light text on a dark glass
  /// should pass a low value here so it stays readable.
  final double fallbackOpacity;
  final Color tint;
  final BorderRadius borderRadius;
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
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: blurred ? opacity : fallbackOpacity),
        borderRadius: borderRadius,
        border: Border.all(
          color:
              borderColor ??
              Colors.white.withValues(alpha: AppGlass.borderOpacity),
        ),
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadows),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: blurred
            ? BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                child: surface,
              )
            : surface,
      ),
    );
  }
}
