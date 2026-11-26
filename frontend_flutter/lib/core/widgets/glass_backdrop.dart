import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Gradient with soft colored glows: the color that glass surfaces blur.
///
/// Glows are radial gradients (no blur filter), so the backdrop is cheap to
/// paint and cached in its own layer by the [RepaintBoundary].
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({
    required this.stops,
    required this.glows,
    required this.child,
    this.borderRadius,
    super.key,
  });

  /// Gradient colors from top-left to bottom-right.
  final List<Color> stops;
  final List<GlowSpot> glows;
  final BorderRadius? borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: stops,
        ),
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _GlowPainter(glows)),
            ),
          ),
          child,
        ],
      ),
    );
    return borderRadius == null
        ? ClipRect(child: decorated)
        : ClipRRect(borderRadius: borderRadius!, child: decorated);
  }
}

class _GlowPainter extends CustomPainter {
  const _GlowPainter(this.glows);
  final List<GlowSpot> glows;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final shortest = size.shortestSide;
    for (final glow in glows) {
      final center = glow.center.alongSize(size);
      final radius = shortest * glow.radius;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              glow.color.withValues(alpha: glow.opacity),
              glow.color.withValues(alpha: glow.opacity * .5),
              glow.color.withValues(alpha: 0),
            ],
            stops: const [0, .45, 1],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) => oldDelegate.glows != glows;
}
