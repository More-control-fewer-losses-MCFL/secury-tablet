import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/core/theme/app_theme.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return ((la > lb ? la : lb) + .05) / ((la > lb ? lb : la) + .05);
}

/// Composites [layers] in order (bottom first) over an opaque [base].
Color composite(Color base, Iterable<Color> layers) =>
    layers.fold(base, (under, layer) => Color.alphaBlend(layer, under));

/// Worst case behind glass: every glow at its peak, fully overlapping, over
/// each gradient stop (the lightest stop is the binding one).
List<Color> worstBackdrops(List<Color> stops, List<GlowSpot> glows) => [
  for (final stop in stops)
    composite(stop, [
      for (final glow in glows) glow.color.withValues(alpha: glow.opacity),
    ]),
];

void expectReadable(
  Color text,
  Color background,
  String reason, {
  double minimum = 4.5,
}) => expect(
  contrast(text, background),
  greaterThanOrEqualTo(minimum),
  reason: '$reason: $text on $background',
);

/// Dark glass as painted when blurred: fill plus the top sheen.
List<Color> darkGlassLayers() => [
  AppGlass.fill(GlassTone.dark),
  Colors.white.withValues(alpha: AppGlass.darkSheenOpacity),
];

void main() {
  test('profile headers and action colors keep readable white text', () {
    for (final color in [
      AppTheme.blue,
      AppTheme.teacherHeader,
      AppTheme.teacherPrimary,
    ]) {
      expectReadable(Colors.white, color, 'header');
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
      expectReadable(color, background, 'status text');
    }
    expectReadable(Colors.white, AppTheme.buttonBlue, 'button');
  });

  group('login', () {
    for (final admin in [true, false]) {
      final profile = admin ? 'admin' : 'professor';
      final backdrops = worstBackdrops(
        AppBackdrop.loginStopsFor(admin),
        AppBackdrop.loginGlowsFor(admin),
      );

      test('$profile: glows stay perceptible (.25–.45 peak)', () {
        for (final glow in AppBackdrop.loginGlowsFor(admin)) {
          expect(glow.opacity, inInclusiveRange(.25, .45));
        }
      });

      test('$profile: institution text on the colored backdrop', () {
        for (final backdrop in backdrops) {
          for (final color in [AppTheme.onBrand, AppTheme.onBrandMuted]) {
            expectReadable(color, backdrop, '$profile backdrop');
          }
        }
      });

      test('$profile: form text on dark glass over the brightest glow', () {
        for (final backdrop in backdrops) {
          final glass = composite(backdrop, darkGlassLayers());
          for (final color in [
            AppTheme.onBrand,
            AppTheme.onBrandMuted,
            AppTheme.onGlassError,
          ]) {
            expectReadable(color, glass, '$profile dark glass');
          }
          // Focus outline and reader icon are non-text: 3:1.
          expectReadable(
            AppTheme.focusGlowFor(admin),
            glass,
            '$profile focus outline',
            minimum: 3,
          );
          // Sunken fields (rest and focused) and the reader card.
          for (final tint in [AppGlass.fieldTint, AppGlass.fieldFocusTint]) {
            final field = Color.alphaBlend(
              AppGlass.darkControlFill(tint: tint),
              glass,
            );
            for (final color in [
              AppTheme.onBrand,
              AppTheme.onBrandMuted,
              AppTheme.onGlassError,
            ]) {
              expectReadable(color, field, '$profile field');
            }
          }
          // Secondary and ghost buttons (rest and hover) keep white labels.
          for (final tint in [
            AppGlass.buttonTint,
            AppGlass.buttonHoverTint,
            AppGlass.fieldFocusTint,
          ]) {
            final button = Color.alphaBlend(
              AppGlass.darkControlFill(tint: tint),
              glass,
            );
            expectReadable(AppTheme.onBrand, button, '$profile button');
          }
        }
      });

      test('$profile: dark glass fallback without blur', () {
        final base = AppBackdrop.loginStopsFor(admin).first;
        for (final backdrop in backdrops) {
          final glass = Color.alphaBlend(
            AppGlass.fill(GlassTone.dark, blurred: false, darkBase: base),
            backdrop,
          );
          for (final color in [AppTheme.onBrand, AppTheme.onBrandMuted]) {
            expectReadable(color, glass, '$profile fallback');
          }
        }
      });
    }
  });

  group('home band', () {
    for (final admin in [true, false]) {
      final profile = admin ? 'admin' : 'professor';
      final backdrops = worstBackdrops(
        AppTheme.backdropFor(admin),
        AppBackdrop.bandGlowsFor(admin),
      );

      test('$profile: identity text and glass shortcuts', () {
        for (final backdrop in backdrops) {
          for (final color in [AppTheme.onBrand, AppTheme.onBrandMuted]) {
            expectReadable(color, backdrop, '$profile band');
          }
          for (final tint in [AppGlass.buttonTint, AppGlass.buttonHoverTint]) {
            final button = Color.alphaBlend(
              AppGlass.darkControlFill(tint: tint),
              backdrop,
            );
            expectReadable(AppTheme.onBrand, button, '$profile shortcut');
          }
        }
      });

      test('$profile: overview card on dark glass, blurred or not', () {
        for (final backdrop in backdrops) {
          for (final glass in [
            composite(backdrop, darkGlassLayers()),
            Color.alphaBlend(
              AppGlass.fill(
                GlassTone.dark,
                blurred: false,
                darkBase: AppTheme.backdropFor(admin).first,
              ),
              backdrop,
            ),
          ]) {
            for (final color in [AppTheme.onBrand, AppTheme.onBrandMuted]) {
              expectReadable(color, glass, '$profile overview');
            }
          }
        }
      });
    }
  });

  group('primary glass button', () {
    for (final admin in [true, false]) {
      test('${admin ? 'admin' : 'professor'}: white label on gradient', () {
        for (final stop in AppTheme.primaryGradientFor(admin)) {
          // Hover sheen (.14) is the brightest state of the top stop.
          final lit = Color.alphaBlend(
            Colors.white.withValues(alpha: .14),
            stop,
          );
          expectReadable(AppTheme.onBrand, lit, 'primary');
        }
      });
    }
  });

  group('light glass top bar', () {
    for (final admin in [true, false]) {
      final profile = admin ? 'admin' : 'professor';
      test('$profile: bar text over the page and over the scrolled band', () {
        final under = [
          ...worstBackdrops(
            AppBackdrop.pageStopsFor(admin),
            AppBackdrop.pageGlowsFor(admin),
          ),
          // The darkest content that can scroll under the bar: the band.
          ...AppTheme.backdropFor(admin),
        ];
        for (final backdrop in under) {
          final bar = Color.alphaBlend(
            AppGlass.fill(GlassTone.light),
            backdrop,
          );
          for (final color in [AppTheme.text, AppTheme.mutedStrong]) {
            expectReadable(color, bar, '$profile bar');
          }
          final pill = Color.alphaBlend(
            Colors.white.withValues(alpha: AppGlass.pillOpacity),
            bar,
          );
          expectReadable(AppTheme.accentFor(admin), pill, '$profile pill');
        }
      });

      test('$profile: page text directly on the tinted canvas', () {
        for (final backdrop in worstBackdrops(
          AppBackdrop.pageStopsFor(admin),
          AppBackdrop.pageGlowsFor(admin),
        )) {
          for (final color in [AppTheme.text, AppTheme.muted]) {
            expectReadable(color, backdrop, '$profile canvas');
          }
        }
      });
    }

    test('light glass fallback stays nearly opaque', () {
      expect(
        AppGlass.fill(GlassTone.light, blurred: false).a,
        closeTo(AppGlass.fallbackOpacity, .001),
      );
    });
  });

  test('glass tokens stay inside the documented ranges', () {
    expect(AppGlass.darkTintOpacity, inInclusiveRange(.10, .16));
    expect(AppGlass.darkBorderOpacity, inInclusiveRange(.22, .30));
    expect(AppGlass.lightOpacity, inInclusiveRange(.55, .70));
    expect(AppGlass.fallbackOpacity, greaterThanOrEqualTo(.94));
    expect(AppGlass.darkFallbackOpacity, greaterThanOrEqualTo(.94));
  });
}
