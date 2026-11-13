import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/core/routing/app_router.dart';
import 'package:frontend_flutter/core/theme/app_theme.dart';
import 'package:frontend_flutter/services/app_controller.dart';
import 'package:frontend_flutter/services/system_api.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _professor = {
  'id': 7,
  'name': 'Ana Teste',
  'registration': 'P-007',
  'active': true,
  'created_at': '2026-01-01T12:00:00Z',
};

const _loan = {
  'session_id': 42,
  'professor_name': 'Ana Teste',
  'registration': 'P-007',
  'requested_quantity': 2,
  'taken_quantity': 2,
  'pending_quantity': 1,
  'purpose': 'Atividade de laboratorio com tablets',
  'class_name': 'Turma A',
  'status': 'DIVERGENT',
  'started_at': '2026-11-12T10:00:00Z',
  'completed_at': null,
};

const _alert = {
  'event_id': 'fictional-reader-alert',
  'type': 'READER_ERROR',
  'title': 'Falha no leitor RFID',
  'severity': 'high',
  'occurred_at': '2026-11-12T10:10:00Z',
  'session_id': 42,
};

/// Complete, fictional API fixture also usable by isolated visual previews.
SystemApi createResponsiveApi({List<http.Request>? requests}) => SystemApi(
  baseUrl: 'http://test.local',
  httpClient: MockClient((request) async {
    requests?.add(request);
    Object? body;
    switch (request.url.path) {
      case '/health':
        body = {'status': 'ok', 'database': 'ok'};
        break;
      case '/auth/rfid':
        body = {
          'access_token': 'fictional-teacher-token',
          'expires_in': 600,
          'professor': _professor,
        };
        break;
      case '/admin/login':
        body = {
          'access_token': 'fictional-admin-token',
          'username': 'admin',
          'expires_in': 600,
        };
        break;
      case '/admin/session':
        body = {'username': 'admin', 'role': 'admin'};
        break;
      case '/tablets/available':
        // Teacher availability intentionally contains no individual assets.
        body = {'available': 4, 'total': 6, 'tablets': []};
        break;
      case '/tablets':
        body = [
          for (var id = 1; id <= 6; id++)
            {
              'id': id,
              'asset_code': 'TAB-00$id',
              'has_rfid_tag': true,
              'status': id <= 4
                  ? 'AVAILABLE'
                  : id == 5
                  ? 'CHECKED_OUT'
                  : 'MAINTENANCE',
              'updated_at': '2026-11-12T10:00:00Z',
            },
        ];
        break;
      case '/history':
        final status = request.url.queryParameters['status'];
        final rows = status == null || status == 'DIVERGENT'
            ? [_loan]
            : <Map<String, Object?>>[];
        body = {
          'total': rows.length,
          'limit': int.parse(request.url.queryParameters['limit'] ?? '20'),
          'offset': 0,
          'rows': rows,
        };
        break;
      case '/admin/overview':
        body = {
          'inventory': {
            'total': 6,
            'available': 4,
            'checked_out': 1,
            'maintenance': 1,
          },
          'sessions': {'open': 0, 'divergent': 1, 'in_flight': 0},
          'alert_events_total': 1,
          'recent_alerts': [_alert],
        };
        break;
      case '/admin/alerts':
        body = [_alert];
        break;
      case '/professors/by-badge/DEADBEEF':
        body = _professor;
        break;
      case '/admin/professors/sync-google-sheets':
        body = {'created': 0, 'updated': 0, 'unchanged': 1};
        break;
      default:
        return http.Response(
          jsonEncode({'detail': 'Unexpected test route'}),
          404,
        );
    }
    return http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json'},
    );
  }),
);

Future<GoRouter> _mount(
  WidgetTester tester, {
  required Size size,
  required AppController controller,
  double textScale = 1.5,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  final router = createAppRouter(controller);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> _unmount(
  WidgetTester tester,
  GoRouter router,
  AppController controller,
) async {
  await tester.pumpWidget(const SizedBox());
  router.dispose();
  controller.dispose();
  await tester.pump();
}

void main() {
  for (final admin in [false, true]) {
    testWidgets(
      '${admin ? 'admin' : 'teacher'} desktop portal keeps role styling and navigation',
      (tester) async {
        final controller = AppController(createResponsiveApi());
        if (admin) {
          await controller.loginAdmin('admin', 'fictional-password');
        } else {
          await controller.identify('DEADBEEF');
        }
        final router = await _mount(
          tester,
          size: const Size(1440, 1000),
          controller: controller,
          textScale: 1,
        );
        try {
          expect(find.byType(NavigationBar), findsNothing);
          expect(find.byKey(const Key('portal-welcome')), findsOneWidget);
          final theme = Theme.of(
            tester.element(find.byKey(const Key('portal-welcome'))),
          );
          expect(
            theme.colorScheme.primary,
            admin ? AppTheme.blue : AppTheme.teacherPrimary,
          );
          expect(
            find.text(
              admin ? 'Seu espaço de gestão.' : 'Seu espaço de professor.',
            ),
            findsOneWidget,
          );
          if (!admin) {
            expect(find.text('Matrícula: P-007'), findsOneWidget);
            expect(find.text('Configurações'), findsNothing);
          }
          expect(tester.takeException(), isNull);
          final target = admin ? '/alerts' : '/movements';
          await tester.tap(find.byKey(ValueKey('portal-nav-$target')));
          await tester.pumpAndSettle();
          expect(router.routeInformationProvider.value.uri.path, target);
          expect(tester.takeException(), isNull);
        } finally {
          await _unmount(tester, router, controller);
        }
      },
    );
  }

  testWidgets('both logins fit a 360px screen with enlarged text', (
    tester,
  ) async {
    final controller = AppController(createResponsiveApi());
    final router = await _mount(
      tester,
      size: const Size(360, 800),
      controller: controller,
    );
    try {
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Senha'), findsOneWidget);
      expect(find.text('Passe o crachá'), findsOneWidget);
      expect(find.textContaining('Google'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.byKey(const Key('badge-access')));
      await tester.tap(find.byKey(const Key('badge-access')));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/login');
      expect(find.text('Passe o crachá'), findsOneWidget);
      expect(find.text('Senha'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Acessar com cadastro'));
      await tester.tap(find.text('Acessar com cadastro'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/admin/login');
      expect(find.byType(TextField), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    } finally {
      await _unmount(tester, router, controller);
    }
  });

  testWidgets(
    'teacher mobile navigation keeps stock and pending returns clear',
    (tester) async {
      final requests = <http.Request>[];
      final controller = AppController(createResponsiveApi(requests: requests));
      await controller.identify('DEADBEEF');
      final router = await _mount(
        tester,
        size: const Size(360, 800),
        controller: controller,
      );
      try {
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byTooltip('Abrir menu'));
        await tester.pumpAndSettle();
        expect(find.text('Configurações'), findsNothing);
        expect(
          find.descendant(
            of: find.byType(Drawer),
            matching: find.text('Retirar tablets'),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(
          find.descendant(
            of: find.byType(Drawer),
            matching: find.text('Início'),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Retirar'),
          ),
        );
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/movements');
        expect(find.text('4'), findsOneWidget);
        expect(find.text('Nenhum tablet disponível.'), findsNothing);
        expect(find.text('Nenhum tablet disponível no momento.'), findsNothing);
        expect(find.text('Confirmar retirada'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Devolver'),
          ),
        );
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/returns');
        expect(find.text('1 pendentes'), findsOneWidget);
        await tester.ensureVisible(find.text('Ler devolução'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Ler devolução'));
        await tester.pumpAndSettle();
        expect(find.text('Confirmar devolução #42'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(
          requests.where((request) => request.url.path == '/returns/reconcile'),
          isEmpty,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await _unmount(tester, router, controller);
      }
    },
  );

  for (final size in [const Size(360, 800), const Size(1440, 1000)]) {
    testWidgets('admin flows fit ${size.width.toInt()}px with enlarged text', (
      tester,
    ) async {
      final requests = <http.Request>[];
      final controller = AppController(createResponsiveApi(requests: requests));
      await controller.loginAdmin('admin', 'fictional-password');
      final router = await _mount(tester, size: size, controller: controller);
      try {
        expect(find.text('Olá, admin'), findsOneWidget);
        expect(find.text('Tablets cadastrados'), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
        expect(tester.takeException(), isNull);

        router.go('/alerts');
        await tester.pumpAndSettle();
        expect(find.text('Falha no leitor RFID'), findsOneWidget);
        expect(tester.takeException(), isNull);

        router.go('/teachers');
        await tester.pumpAndSettle();
        expect(find.text('Localizar cadastro'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.enterText(find.byType(TextField).last, 'DEADBEEF');
        await tester.ensureVisible(find.text('Consultar'));
        await tester.tap(find.text('Consultar'));
        await tester.pumpAndSettle();
        expect(find.text('Ana Teste'), findsOneWidget);
        expect(find.textContaining('Cadastro ativo'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(find.text('Sincronizar professores'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sincronizar professores'));
        await tester.pumpAndSettle();
        expect(find.text('Sincronizar professores?'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(
          requests.where(
            (request) =>
                request.url.path == '/admin/professors/sync-google-sheets',
          ),
          isEmpty,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await _unmount(tester, router, controller);
      }
    });
  }
}
