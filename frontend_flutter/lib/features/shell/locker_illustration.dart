import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class LockerIllustration extends StatelessWidget {
  const LockerIllustration({this.light = false, super.key});

  final bool light;

  @override
  Widget build(BuildContext context) {
    final cabinet = light ? const Color(0xFF77A7D9) : const Color(0xFF234F80);
    final outline = light ? Colors.white70 : const Color(0xFFBDD4EA);
    return CustomPaint(
      painter: _LockerPainter(cabinet: cabinet, outline: outline, light: light),
      child: const SizedBox.expand(),
    );
  }
}

class _LockerPainter extends CustomPainter {
  const _LockerPainter({
    required this.cabinet,
    required this.outline,
    required this.light,
  });

  final Color cabinet;
  final Color outline;
  final bool light;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = cabinet;
    final stroke = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final x = size.width * .18;
    final y = size.height * .06;
    final width = size.width * .62;
    final height = size.height * .88;
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, width, height),
      const Radius.circular(8),
    );
    canvas.drawRRect(frame, fill);
    canvas.drawRRect(frame, stroke);
    final compartmentPaint = Paint()
      ..color = outline.withValues(alpha: light ? .35 : .26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var row = 0; row < 3; row++) {
      for (var column = 0; column < 2; column++) {
        final left = x + 10 + column * (width * .48);
        final top = y + 10 + row * (height * .30);
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, width * .42, height * .26),
          const Radius.circular(4),
        );
        canvas.drawRRect(rect, compartmentPaint);
        canvas.drawCircle(
          Offset(left + width * .34, top + height * .13),
          2,
          Paint()..color = outline,
        );
      }
    }
    final tabletPaint = Paint()
      ..color = light ? Colors.white : AppTheme.paleBlue;
    final tablet = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        x + width * .74,
        y + height * .48,
        width * .26,
        height * .37,
      ),
      const Radius.circular(5),
    );
    canvas.drawRRect(tablet, tabletPaint);
    canvas.drawRRect(
      tablet,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(x + width * .87, y + height * .79),
      2,
      Paint()..color = cabinet,
    );
    final signal = Paint()
      ..color = light ? const Color(0xFF9BD8FF) : AppTheme.buttonBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (var i = 0; i < 3; i++) {
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(x + width * .5, y + height * .5),
          radius: 15.0 + i * 9,
        ),
        -1.1,
        2.2,
        false,
        signal..color = signal.color.withValues(alpha: .8 - i * .18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LockerPainter oldDelegate) =>
      oldDelegate.cabinet != cabinet ||
      oldDelegate.outline != outline ||
      oldDelegate.light != light;
}
