import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/app.dart';
import 'package:frontend_flutter/core/theme/app_theme.dart';
import 'package:frontend_flutter/services/system_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'responsive_flows_test.dart' show createResponsiveApi;

const _password = 'fictional-professor-password';

void _size(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _openProfessor(WidgetTester tester, SystemApi api) async {
  await tester.pumpWidget(SystemApp(api: api));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('professor-password-access')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'password professor enters green portal and requests checkout without UID',
    (tester) async {
      _size(tester);
      final requests = <http.Request>[];
      await _openProfessor(tester, createResponsiveApi(requests: requests));
      expect(find.text('Bem-vindo, professor'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
        true,
      );
      await tester.enterText(find.byType(TextField).first, 'teacher.ana');
      await tester.enterText(find.byType(TextField).at(1), _password);
      await tester.tap(find.text('Acessar'));
      await tester.pumpAndSettle();
      expect(find.text('Olá, Ana Teste'), findsOneWidget);
      expect(find.text('Configurações'), findsNothing);
      expect(
        Theme.of(tester.element(find.byKey(const Key('portal-welcome'))))
            .colorScheme
            .primary,
        AppTheme.teacherPrimary,
      );
      final login = requests.singleWhere(
        (r) => r.url.path == '/auth/professor/login',
      );
      expect(jsonDecode(login.body), {
        'username': 'teacher.ana',
        'password': _password,
      });
      expect(
        requests.any((r) => r.url.path == '/auth/professor/session'),
        true,
      );
      expect(requests.any((r) => r.url.path == '/terminal/authorize'), false);

      await tester.tap(find.byKey(const ValueKey('portal-nav-/movements')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).at(1),
        'Atividade de laboratório',
      );
      await tester.ensureVisible(find.text('Confirmar retirada'));
      await tester.tap(find.text('Confirmar retirada'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      final checkout = requests.singleWhere(
        (r) => r.url.path == '/checkout-requests',
      );
      expect(jsonDecode(checkout.body).containsKey('badge_uid'), false);
      expect(jsonDecode(checkout.body)['quantity'], 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('incorrect professor password stays at the login', (
    tester,
  ) async {
    _size(tester);
    final api = SystemApi(
      baseUrl: 'http://test.local',
      httpClient: MockClient((request) async {
        if (request.url.path == '/health') {
          return http.Response('{"status":"ok","database":"ok"}', 200);
        }
        return http.Response(
          jsonEncode({'detail': 'Usuário ou senha inválidos.'}),
          401,
        );
      }),
    );
    await _openProfessor(tester, api);
    await tester.enterText(find.byType(TextField).first, 'teacher.ana');
    await tester.enterText(find.byType(TextField).at(1), 'incorrect');
    await tester.tap(find.text('Acessar'));
    await tester.pumpAndSettle();
    expect(find.text('Usuário ou senha inválidos.'), findsOneWidget);
    expect(find.text('Bem-vindo, professor'), findsOneWidget);
    expect(find.byKey(const Key('portal-welcome')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  test('mismatched session identity clears the received token', () async {
    String? lastAuthorization;
    final professor = {
      'id': 7,
      'name': 'Ana Teste',
      'registration': 'P-007',
      'active': true,
      'created_at': '2026-01-01T00:00:00Z',
    };
    final api = SystemApi(
      baseUrl: 'http://test.local',
      httpClient: MockClient((request) async {
        lastAuthorization = request.headers['authorization'];
        if (request.url.path == '/auth/professor/login') {
          return http.Response(
            jsonEncode({
              'access_token': 'fictional-token',
              'expires_in': 600,
              'professor': professor,
            }),
            200,
          );
        }
        if (request.url.path == '/auth/professor/session') {
          return http.Response(
            jsonEncode({
              'role': 'professor',
              'professor': {...professor, 'id': 99},
            }),
            200,
          );
        }
        return http.Response('{"available":0,"total":0,"tablets":[]}', 200);
      }),
    );
    await expectLater(
      api.loginProfessor('teacher.ana', _password),
      throwsA(isA<FormatException>()),
    );
    await api.availability();
    expect(lastAuthorization, isNull);
  });

  testWidgets('administrator sets credentials for the selected professor', (
    tester,
  ) async {
    _size(tester);
    final requests = <http.Request>[];
    await tester.pumpWidget(
      SystemApp(api: createResponsiveApi(requests: requests)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).at(1),
      'fictional-administrator-password',
    );
    await tester.tap(find.text('Acessar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('portal-nav-/teachers')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'DEADBEEF');
    await tester.tap(find.text('Consultar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Configurar usuário e senha'));
    await tester.tap(find.text('Configurar usuário e senha'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('professor-credential-username')),
      'teacher.ana',
    );
    await tester.enterText(
      find.byKey(const Key('professor-credential-password')),
      _password,
    );
    await tester.tap(find.text('Salvar acesso'));
    await tester.pumpAndSettle();
    final request = requests.singleWhere(
      (r) => r.url.path == '/admin/professors/7/credentials',
    );
    expect(jsonDecode(request.body), {
      'username': 'teacher.ana',
      'password': _password,
    });
    expect(find.text('Acesso do professor salvo: teacher.ana'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
