import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/core/routing/app_router.dart';
import 'package:frontend_flutter/core/theme/app_theme.dart';
import 'package:frontend_flutter/core/widgets/glass_surface.dart';
import 'package:frontend_flutter/services/app_controller.dart';
import 'package:frontend_flutter/widgets/common_widgets.dart';

import 'responsive_flows_test.dart' show createResponsiveApi;

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
  testWidgets('light glass blurs the backdrop with a translucent fill', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const GlassSurface(child: Text('Conteúdo sobre vidro'))),
    );

    expect(find.text('Conteúdo sobre vidro'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(_fillOf(tester).a, closeTo(AppGlass.lightOpacity, .01));
    expect(
      find.descendant(
        of: find.byType(GlassSurface),
        matching: find.byType(RepaintBoundary),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: find.byType(GlassSurface),
        matching: find.byType(ClipRRect),
      ),
      findsOneWidget,
    );
  });

  testWidgets('dark glass uses the veil plus a white tint', (tester) async {
    await tester.pumpWidget(
      _host(
        const GlassSurface(tone: GlassTone.dark, child: Text('Vidro escuro')),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(_fillOf(tester), AppGlass.fill(GlassTone.dark));
    // Translucent: the blurred backdrop must remain visible through it.
    expect(_fillOf(tester).a, lessThan(.6));
  });

  testWidgets('blur: false renders an opaque fallback without filter', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const GlassSurface(blur: false, child: Text('Totem'))),
    );

    expect(find.byType(BackdropFilter), findsNothing);
    expect(_fillOf(tester).a, closeTo(AppGlass.fallbackOpacity, .01));

    await tester.pumpWidget(
      _host(
        const GlassSurface(
          tone: GlassTone.dark,
          blur: false,
          fallbackColor: AppTheme.blueDeep,
          child: Text('Totem'),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsNothing);
    final fill = _fillOf(tester);
    expect(fill.a, closeTo(AppGlass.darkFallbackOpacity, .01));
    expect(fill.withValues(alpha: 1), AppTheme.blueDeep);
  });

  testWidgets('reduced motion and high contrast disable the blur', (
    tester,
  ) async {
    for (final tone in GlassTone.values) {
      for (final data in const [
        MediaQueryData(disableAnimations: true),
        MediaQueryData(highContrast: true),
      ]) {
        await tester.pumpWidget(
          _host(
            GlassSurface(tone: tone, child: const Text('Acessível')),
            data: data,
          ),
        );

        expect(find.byType(BackdropFilter), findsNothing);
        expect(
          _fillOf(tester).a,
          closeTo(
            tone == GlassTone.light
                ? AppGlass.fallbackOpacity
                : AppGlass.darkFallbackOpacity,
            .01,
          ),
        );
      }
    }
  });

  testWidgets('status feedback stays opaque when placed on glass', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const GlassSurface(
          tone: GlassTone.dark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusPill('Sistema disponível', color: AppTheme.success),
              InlineNotice(
                title: 'Falha',
                message: 'Tente novamente.',
                hint: 'Verifique a conexão.',
              ),
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
    // The notice keeps dark text on its light fill whatever the theme says.
    expect(
      tester.widget<Text>(find.text('Tente novamente.')).style?.color,
      AppTheme.text,
    );
  });

  group('blur budget per screen (max 2 BackdropFilter)', () {
    Future<void> Function()? unmount;

    Future<void> mount(
      WidgetTester tester,
      String location,
      Size size, {
      bool admin = false,
      bool teacher = false,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = AppController(createResponsiveApi());
      if (admin) await controller.loginAdmin('admin', 'fictional-password');
      if (teacher) await controller.identify('DEADBEEF');
      final router = createAppRouter(controller);
      router.go(location);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      );
      await tester.pumpAndSettle();
      // Disposed inside the test body so session timers do not outlive it.
      unmount = () async {
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        controller.dispose();
        await tester.pump();
      };
    }

    for (final (location, label) in const [
      ('/admin/login', 'admin login'),
      ('/professor/login', 'professor login'),
      ('/login', 'badge login'),
    ]) {
      for (final size in const [Size(1440, 900), Size(390, 844)]) {
        testWidgets('$label at ${size.width.toInt()}px', (tester) async {
          await mount(tester, location, size);
          final filters = find.byType(BackdropFilter).evaluate().length;
          expect(filters, size.width >= 980 ? 2 : 1);
          expect(find.byKey(const ValueKey('access-glass')), findsOneWidget);
          await unmount!();
        });
      }
    }

    for (final admin in [true, false]) {
      testWidgets('${admin ? 'admin' : 'professor'} home at 1440px', (
        tester,
      ) async {
        await mount(
          tester,
          '/home',
          const Size(1440, 1000),
          admin: admin,
          teacher: !admin,
        );
        expect(find.byKey(const ValueKey('shell-glass-bar')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('portal-overview-glass')),
          findsOneWidget,
        );
        expect(find.byType(BackdropFilter), findsNWidgets(2));
        await unmount!();
      });
    }
  });
}
