import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/core/theme/app_theme.dart';

void main() {
  test('body and status text retain readable contrast on their surfaces', () {
    for (final color in [
      AppTheme.text,
      AppTheme.muted,
      AppTheme.blue,
      AppTheme.success,
      AppTheme.warning,
      AppTheme.danger,
    ]) {
      final background = Color.alphaBlend(
        color.withValues(alpha: .08),
        Colors.white,
      );
      final ratio =
          (background.computeLuminance() + .05) /
          (color.computeLuminance() + .05);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason: 'Status text must remain readable',
      );
    }
    final buttonRatio =
        (Colors.white.computeLuminance() + .05) /
        (AppTheme.buttonBlue.computeLuminance() + .05);
    expect(buttonRatio, greaterThanOrEqualTo(4.5));
  });
}
