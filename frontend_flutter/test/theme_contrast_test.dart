import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/core/theme/app_theme.dart';

void main() {
  test('profile headers and action colors keep readable white text', () {
    for (final color in [
      AppTheme.blue,
      AppTheme.teacherHeader,
      AppTheme.teacherPrimary,
    ]) {
      final ratio =
          (Colors.white.computeLuminance() + .05) /
          (color.computeLuminance() + .05);
      expect(ratio, greaterThanOrEqualTo(4.5));
    }
  });

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

  double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return ((la > lb ? la : lb) + .05) / ((la > lb ? lb : la) + .05);
  }

  test('text on glass stays readable over every profile backdrop', () {
    for (final admin in [true, false]) {
      for (final backdrop in AppTheme.backdropFor(admin)) {
        for (final blurred in [true, false]) {
          // Worst case: the darkest backdrop color seen through the glass.
          final glass = Color.alphaBlend(
            AppGlass.fill(blurred: blurred),
            backdrop,
          );
          for (final color in [
            AppTheme.text,
            AppTheme.muted,
            AppTheme.accentFor(admin),
          ]) {
            expect(
              contrast(color, glass),
              greaterThanOrEqualTo(4.5),
              reason: 'text $color on glass over $backdrop',
            );
          }
        }
      }
    }
  });

  test('light text stays readable on profile backdrops and glows', () {
    for (final admin in [true, false]) {
      for (final backdrop in AppTheme.backdropFor(admin)) {
        final lightest = Color.alphaBlend(
          Colors.white.withValues(alpha: AppTheme.backdropGlowOpacity),
          backdrop,
        );
        for (final color in [AppTheme.onBrand, AppTheme.onBrandMuted]) {
          expect(
            contrast(color, lightest),
            greaterThanOrEqualTo(4.5),
            reason: '$color over $backdrop with glow',
          );
        }
      }
    }
  });
}
