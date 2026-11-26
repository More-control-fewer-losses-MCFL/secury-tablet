import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/core/theme/app_theme.dart';
import 'package:frontend_flutter/core/widgets/glass_button.dart';

Widget _host(
  Widget child, {
  MediaQueryData data = const MediaQueryData(),
  ThemeData? theme,
}) => MaterialApp(
  theme: theme ?? AppTheme.light,
  home: MediaQuery(
    data: data,
    child: Scaffold(
      backgroundColor: AppTheme.blueDeep,
      body: Center(child: child),
    ),
  ),
);

BoxDecoration _decorationOf(WidgetTester tester) =>
    tester
            .widget<AnimatedContainer>(
              find.descendant(
                of: find.byType(GlassButton),
                matching: find.byType(AnimatedContainer),
              ),
            )
            .decoration!
        as BoxDecoration;

double _translationY(WidgetTester tester) => tester
    .widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(GlassButton),
        matching: find.byType(AnimatedContainer),
      ),
    )
    .transform!
    .getTranslation()
    .y;

void main() {
  testWidgets('keeps a 48px touch target and never blurs', (tester) async {
    for (final variant in GlassButtonVariant.values) {
      await tester.pumpWidget(
        _host(
          GlassButton(
            variant: variant,
            label: 'Ok',
            icon: Icons.check,
            onPressed: () {},
          ),
        ),
      );
      final size = tester.getSize(find.byType(GlassButton));
      expect(size.height, greaterThanOrEqualTo(48), reason: '$variant');
      expect(size.width, greaterThanOrEqualTo(48), reason: '$variant');
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byIcon(Icons.check), findsOneWidget);
    }
  });

  testWidgets('primary uses the profile gradient with a glow', (tester) async {
    for (final (theme, admin) in [
      (AppTheme.light, true),
      (AppTheme.teacher, false),
    ]) {
      await tester.pumpWidget(
        _host(
          theme: theme,
          GlassButton(
            variant: GlassButtonVariant.primary,
            label: 'Acessar',
            onPressed: () {},
          ),
        ),
      );
      // MaterialApp animates theme changes; let it settle on the profile.
      await tester.pumpAndSettle();
      final decoration = _decorationOf(tester);
      expect(
        (decoration.gradient! as LinearGradient).colors,
        AppTheme.primaryGradientFor(admin),
      );
      expect(decoration.boxShadow, isNotEmpty);
    }
  });

  testWidgets('taps, hover lift and pressed scale', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(GlassButton(label: 'Entrar', onPressed: () => taps++)),
    );
    final restBorder = (_decorationOf(tester).border! as Border).top.color;
    expect(_translationY(tester), 0);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(GlassButton)));
    await tester.pumpAndSettle();
    expect(_translationY(tester), -1, reason: 'hover lifts the button');
    expect(
      (_decorationOf(tester).border! as Border).top.color.a,
      greaterThan(restBorder.a),
    );

    final press = await tester.startGesture(
      tester.getCenter(find.byType(GlassButton)),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, .98);
    await press.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('keyboard focus is visible and activates the button', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(GlassButton(label: 'Entrar', onPressed: () => taps++)),
    );
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    final ring = find.descendant(
      of: find.byType(GlassButton),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            '${widget.foregroundPainter.runtimeType}' == '_FocusRing' &&
            (widget.foregroundPainter! as dynamic).visible == true,
      ),
    );
    expect(ring, findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(taps, 1);
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  testWidgets('disabled ignores taps and reports it to assistive tech', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(const GlassButton(label: 'Indisponível', onPressed: null)),
    );
    await tester.tap(find.byType(GlassButton), warnIfMissed: false);
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      .5,
    );
    expect(
      tester.getSemantics(find.byType(GlassButton)),
      isSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
        label: 'Indisponível',
      ),
    );
    semantics.dispose();
  });

  testWidgets('loading shows progress, keeps full opacity, blocks taps', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        GlassButton(
          variant: GlassButtonVariant.primary,
          label: 'Acessar',
          loading: true,
          loadingLabel: 'Verificando acesso…',
          onPressed: () => taps++,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Verificando acesso…'), findsOneWidget);
    expect(find.text('Acessar'), findsNothing);
    await tester.tap(find.byType(GlassButton), warnIfMissed: false);
    expect(taps, 0);
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      1,
    );
  });

  testWidgets('high contrast drops translucency and gradients', (tester) async {
    for (final variant in [
      GlassButtonVariant.primary,
      GlassButtonVariant.secondary,
    ]) {
      await tester.pumpWidget(
        _host(
          data: const MediaQueryData(highContrast: true),
          GlassButton(variant: variant, label: 'Ok', onPressed: () {}),
        ),
      );
      final decoration = _decorationOf(tester);
      expect(decoration.gradient, isNull, reason: '$variant');
      expect(decoration.color!.a, 1, reason: '$variant fill is opaque');
      final border = (decoration.border! as Border).top;
      expect(border.width, 2);
      expect(border.color, Colors.white);
      expect(decoration.boxShadow, isEmpty);
    }
  });

  testWidgets('reduced motion makes state changes instant without lift', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        data: const MediaQueryData(disableAnimations: true),
        GlassButton(label: 'Entrar', onPressed: () {}),
      ),
    );
    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(GlassButton),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(container.duration, Duration.zero);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(GlassButton)));
    await tester.pump();
    expect(_translationY(tester), 0);
  });
}
