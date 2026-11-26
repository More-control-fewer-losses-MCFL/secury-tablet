import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/core/theme/app_theme.dart';
import 'package:frontend_flutter/core/widgets/glass_surface.dart';
import 'package:frontend_flutter/widgets/common_widgets.dart';

Widget _host(Widget child, {MediaQueryData data = const MediaQueryData()}) =>
    MaterialApp(
      home: MediaQuery(
        data: data,
        child: Scaffold(body: Center(child: child)),
      ),
    );

Color _fillOf(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(GlassSurface),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is DecoratedBox &&
                (widget.decoration as BoxDecoration).color != null,
          ),
        )
        .first,
  );
  return (box.decoration as BoxDecoration).color!;
}

void main() {
  testWidgets('blurs the backdrop with the translucent glass fill', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const GlassSurface(child: Text('Conteúdo sobre vidro'))),
    );

    expect(find.text('Conteúdo sobre vidro'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(_fillOf(tester).a, closeTo(AppGlass.opacity, .01));
  });

  testWidgets('blur: false renders an opaque fallback without filter', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const GlassSurface(blur: false, child: Text('Totem'))),
    );

    expect(find.byType(BackdropFilter), findsNothing);
    expect(_fillOf(tester).a, closeTo(AppGlass.fallbackOpacity, .01));
  });

  testWidgets('reduced motion and high contrast disable the blur', (
    tester,
  ) async {
    for (final data in const [
      MediaQueryData(disableAnimations: true),
      MediaQueryData(highContrast: true),
    ]) {
      await tester.pumpWidget(
        _host(const GlassSurface(child: Text('Acessível')), data: data),
      );

      expect(find.byType(BackdropFilter), findsNothing);
      expect(_fillOf(tester).a, closeTo(AppGlass.fallbackOpacity, .01));
    }
  });

  testWidgets('status feedback stays opaque when placed on glass', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const GlassSurface(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusPill('Sistema disponível', color: AppTheme.success),
              InlineNotice(title: 'Falha', message: 'Tente novamente.'),
            ],
          ),
        ),
      ),
    );

    for (final type in [StatusPill, InlineNotice]) {
      final fills = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(type),
              matching: find.byType(Container),
            ),
          )
          .map((c) => (c.decoration as BoxDecoration?)?.color)
          .whereType<Color>();
      expect(fills, isNotEmpty);
      for (final fill in fills) {
        expect(
          fill.a,
          1,
          reason: '$type background must not let glass through',
        );
      }
    }
  });
}
