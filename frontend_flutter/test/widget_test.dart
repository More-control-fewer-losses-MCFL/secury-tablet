import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/app.dart';
import 'package:frontend_flutter/services/system_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('RFID identification opens the API-backed dashboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    final client = MockClient((request) async {
      if (request.url.path == '/health') {
        return http.Response(
          jsonEncode({'status': 'ok', 'database': 'ok'}),
          200,
        );
      }
      if (request.url.path == '/auth/rfid') {
        expect(request.method, 'POST');
        expect(jsonDecode(request.body), {'badge_uid': 'AABB1234'});
        return http.Response(
          jsonEncode({
            'access_token': 'teacher-token',
            'expires_in': 600,
            'professor': {
              'id': 7,
              'name': 'Maria Silva',
              'registration': 'P-007',
              'active': true,
              'created_at': '2026-01-01T12:00:00Z',
            },
          }),
          200,
        );
      }
      if (request.url.path == '/tablets/available') {
        expect(request.headers['authorization'], 'Bearer teacher-token');
        return http.Response(
          jsonEncode({'available': 4, 'total': 10, 'tablets': []}),
          200,
        );
      }
      if (request.url.path == '/history') {
        return http.Response(
          jsonEncode({'total': 0, 'limit': 8, 'offset': 0, 'rows': []}),
          200,
        );
      }
      return http.Response(jsonEncode({'detail': 'Rota não encontrada'}), 404);
    });

    await tester.pumpWidget(
      SystemApp(
        api: SystemApi(baseUrl: 'http://test.local', httpClient: client),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('badge-access')));
    await tester.pumpAndSettle();
    expect(find.text('Passe o crachá'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'AABB1234');
    await tester.tap(find.text('Validar crachá'));
    await tester.pumpAndSettle();

    expect(find.text('Olá, Maria Silva'), findsOneWidget);
    expect(find.text('Disponíveis agora'), findsOneWidget);
    expect(find.text('Professores'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('administrator login verifies the signed API session', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    final client = MockClient((request) async {
      if (request.url.path == '/health') {
        return http.Response(
          jsonEncode({'status': 'ok', 'database': 'ok'}),
          200,
        );
      }
      if (request.url.path == '/admin/login') {
        expect(jsonDecode(request.body), {
          'username': 'admin',
          'password': 'test-admin-password',
        });
        return http.Response(
          jsonEncode({
            'access_token': 'signed-admin-token',
            'token_type': 'bearer',
            'expires_in': 28800,
            'username': 'admin',
          }),
          200,
        );
      }
      if (request.url.path == '/admin/session') {
        expect(request.headers['authorization'], 'Bearer signed-admin-token');
        return http.Response(
          jsonEncode({'username': 'admin', 'role': 'admin'}),
          200,
        );
      }
      if (request.url.path == '/tablets') {
        return http.Response('[]', 200);
      }
      if (request.url.path == '/history') {
        return http.Response(
          jsonEncode({'total': 0, 'limit': 8, 'offset': 0, 'rows': []}),
          200,
        );
      }
      return http.Response(jsonEncode({'detail': 'Rota não encontrada'}), 404);
    });

    await tester.pumpWidget(
      SystemApp(
        api: SystemApi(baseUrl: 'http://test.local', httpClient: client),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo ao Secury Tablet'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), 'test-admin-password');
    await tester.ensureVisible(find.text('Acessar'));
    await tester.tap(find.text('Acessar'));
    await tester.pumpAndSettle();

    expect(find.text('Olá, admin'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('administrator enrolls terminal and stays on RFID login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    var enrolled = false;
    final client = MockClient((request) async {
      if (request.url.path == '/health') {
        return http.Response(
          jsonEncode({'status': 'ok', 'database': 'ok'}),
          200,
        );
      }
      if (request.url.path == '/admin/login') {
        return http.Response(
          jsonEncode({
            'access_token': 'admin-token',
            'username': 'admin',
            'expires_in': 480,
          }),
          200,
        );
      }
      if (request.url.path == '/admin/session') {
        return http.Response(
          jsonEncode({'username': 'admin', 'role': 'admin'}),
          200,
        );
      }
      if (request.url.path == '/terminal/authorize') {
        expect(request.headers['authorization'], 'Bearer admin-token');
        enrolled = true;
        return http.Response(jsonEncode({'authorized': true}), 200);
      }
      return http.Response('{}', 404);
    });
    await tester.pumpWidget(
      SystemApp(
        api: SystemApi(baseUrl: 'http://test.local', httpClient: client),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Configurar acesso por crachá'));
    await tester.tap(find.text('Configurar acesso por crachá'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.enterText(find.byType(TextField).at(1), 'test-password');
    await tester.ensureVisible(find.text('Autorizar terminal'));
    await tester.tap(find.text('Autorizar terminal'));
    await tester.pumpAndSettle();
    expect(enrolled, true);
    expect(find.text('Passe o crachá'), findsOneWidget);
    expect(find.text('Olá, admin'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
