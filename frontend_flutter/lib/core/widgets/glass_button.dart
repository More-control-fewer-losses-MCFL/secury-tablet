import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum GlassButtonVariant { primary, secondary, ghost }

/// Button for dark glass and profile-colored surfaces (white label).
///
/// - [GlassButtonVariant.primary]: profile gradient with a top sheen and a
///   colored glow.
/// - [GlassButtonVariant.secondary]: translucent glass with a light border.
/// - [GlassButtonVariant.ghost]: no fill until hovered.
///
/// It never uses a `BackdropFilter`: it sits on surfaces that are already
/// blurred or colored, so it does not count toward the per-screen blur limit.
/// The profile colors follow the ambient [Theme] (teacher or admin).
///
/// Hover lifts the button 1px and strengthens its shadow; pressing scales it
/// to 98%. Focus draws a 2px outline outside the button. With reduced motion
/// these transitions are instant; with high contrast the fills become opaque
/// and the border 2px wide.
class GlassButton extends StatefulWidget {
  const GlassButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = GlassButtonVariant.secondary,
    this.loading = false,
    this.loadingLabel = 'Aguarde…',
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final GlassButtonVariant variant;

  /// Shows a progress indicator with [loadingLabel] and ignores taps.
  final bool loading;
  final String loadingLabel;

  static const double minHeight = 48;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool hovered = false;
  bool pressed = false;
  bool focused = false;

  bool get enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final admin = AppTheme.isAdminTheme(theme);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final highContrast = MediaQuery.maybeHighContrastOf(context) ?? false;
    final duration = reduceMotion ? Duration.zero : AppMotion.fast;
    final hover = enabled && hovered;
    final down = enabled && pressed;
    final variant = widget.variant;
    const radius = AppRadius.control;

    final Gradient? gradient;
    final Color? color;
    final Color border;
    final List<BoxShadow> shadows;
    switch (variant) {
      case GlassButtonVariant.primary:
        final stops = AppTheme.primaryGradientFor(admin);
        gradient = highContrast
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: stops,
              );
        color = highContrast ? stops.first : null;
        border = Colors.white.withValues(alpha: highContrast ? 1 : .28);
        final glow = AppTheme.primaryGlowFor(admin);
        shadows = highContrast || !enabled
            ? const []
            : [
                BoxShadow(
                  color: glow.withValues(alpha: hover ? .50 : .32),
                  blurRadius: hover ? 24 : 16,
                  spreadRadius: -4,
                  offset: Offset(0, hover ? 8 : 6),
                ),
              ];
      case GlassButtonVariant.secondary:
        gradient = null;
        color = highContrast
            ? AppGlass.darkVeil
            : AppGlass.darkControlFill(
                tint: hover ? AppGlass.buttonHoverTint : AppGlass.buttonTint,
              );
        border = Colors.white.withValues(
          alpha: highContrast
              ? 1
              : hover
              ? .48
              : .30,
        );
        shadows = hover && !highContrast
            ? const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 18,
                  spreadRadius: -6,
                  offset: Offset(0, 8),
                ),
              ]
            : const [];
      case GlassButtonVariant.ghost:
        gradient = null;
        color = hover || down
            ? AppGlass.darkControlFill(tint: AppGlass.fieldFocusTint)
            : Colors.transparent;
        border = highContrast
            ? Colors.white
            : Colors.white.withValues(alpha: hover ? .30 : 0);
        shadows = const [];
    }

    final textStyle = theme.textTheme.labelLarge?.copyWith(
      fontFamily: 'Roboto',
      color: AppTheme.onBrand,
      fontWeight: FontWeight.w600,
    );
    final content = widget.loading
        ? Row(
            key: const ValueKey('glass-button-loading'),
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.onBrand,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: Text(widget.loadingLabel, style: textStyle)),
            ],
          )
        : Row(
            key: const ValueKey('glass-button-label'),
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                ExcludeSemantics(
                  child: Icon(widget.icon, size: 20, color: AppTheme.onBrand),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: textStyle,
                ),
              ),
            ],
          );

    Widget body = ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: GlassButton.minHeight,
        minWidth: GlassButton.minHeight,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + AppSpacing.xxs,
          vertical: AppSpacing.sm,
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: AnimatedSwitcher(duration: duration, child: content),
        ),
      ),
    );
    if (variant == GlassButtonVariant.primary && !highContrast) {
      // Sheen: light catching the top half of the gradient.
      body = DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [
              Colors.white.withValues(alpha: hover ? .14 : .10),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
        child: body,
      );
    }

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      child: AnimatedOpacity(
        duration: duration,
        opacity: enabled || widget.loading ? 1 : .5,
        child: AnimatedScale(
          duration: duration,
          curve: AppMotion.curve,
          scale: down && !reduceMotion ? .98 : 1,
          child: CustomPaint(
            foregroundPainter: _FocusRing(
              visible: focused,
              color: AppTheme.onBrand,
              radius: radius,
            ),
            child: AnimatedContainer(
              duration: duration,
              curve: AppMotion.curve,
              transform: Matrix4.translationValues(
                0,
                hover && !reduceMotion ? -1 : 0,
                0,
              ),
              decoration: BoxDecoration(
                color: color,
                gradient: gradient,
                borderRadius: radius,
                border: Border.all(color: border, width: highContrast ? 2 : 1),
                boxShadow: shadows,
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: enabled ? widget.onPressed : null,
                    onHover: (value) => setState(() => hovered = value),
                    onHighlightChanged: (value) =>
                        setState(() => pressed = value),
                    onFocusChange: (value) => setState(() => focused = value),
                    borderRadius: radius,
                    splashColor: Colors.white.withValues(alpha: .10),
                    highlightColor: Colors.white.withValues(alpha: .04),
                    hoverColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    child: body,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Visible keyboard focus: 2px outline 3px outside the button.
class _FocusRing extends CustomPainter {
  const _FocusRing({
    required this.visible,
    required this.color,
    required this.radius,
  });

  final bool visible;
  final Color color;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (!visible) return;
    final rect = (Offset.zero & size).inflate(3);
    final outer = BorderRadius.only(
      topLeft: radius.topLeft + const Radius.circular(3),
      topRight: radius.topRight + const Radius.circular(3),
      bottomLeft: radius.bottomLeft + const Radius.circular(3),
      bottomRight: radius.bottomRight + const Radius.circular(3),
    );
    canvas.drawRRect(
      outer.toRRect(rect),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_FocusRing oldDelegate) =>
      oldDelegate.visible != visible || oldDelegate.color != color;
}
