import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/core/routing/app_router.dart';
import 'package:frontend_flutter/services/app_controller.dart';
import 'package:frontend_flutter/services/system_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

SystemApi _testApi() => SystemApi(
  baseUrl: 'http://test.local',
  httpClient: MockClient((request) async {
    switch (request.url.path) {
      case '/auth/rfid':
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
      case '/admin/login':
        return http.Response(
          jsonEncode({
            'access_token': 'admin-token',
            'username': 'admin',
            'expires_in': 600,
          }),
          200,
        );
      case '/admin/session':
        return http.Response(
          jsonEncode({'username': 'admin', 'role': 'admin'}),
          200,
        );
      case '/health':
        return http.Response(
          jsonEncode({'status': 'ok', 'database': 'ok'}),
          200,
        );
      case '/tablets':
        return http.Response('[]', 200);
      case '/tablets/available':
        return http.Response(
          jsonEncode({'available': 4, 'total': 10, 'tablets': []}),
          200,
        );
      case '/history':
        return http.Response(
          jsonEncode({'total': 0, 'limit': 5, 'offset': 0, 'rows': []}),
          200,
        );
      default:
        return http.Response(jsonEncode({'detail': 'Not found'}), 404);
    }
  }),
);

void main() {
  test('role matrix separates admin and teacher paths', () async {
    final controller = AppController(_testApi());
    expect(controller.canAccessRoute('/history'), false);
    await controller.identify('AABB1234');
    expect(controller.isTeacher, true);
    expect(controller.canAccessRoute('/movements'), true);
    expect(controller.canAccessRoute('/totem'), true);
    expect(controller.canAccessRoute('/agenda'), false);
    expect(controller.canAccessRoute('/alerts'), false);
    expect(controller.canAccessRoute('/teachers'), false);
    expect(controller.canAccessRoute('/tablets'), false);
    expect(controller.canAccessRoute('/settings'), false);
    controller.signOut();
    await controller.loginAdmin('admin', 'password');
    expect(controller.isAdmin, true);
    expect(controller.canAccessRoute('/teachers'), true);
    expect(controller.canAccessRoute('/tablets'), true);
    expect(controller.canAccessRoute('/settings'), true);
    expect(controller.canAccessRoute('/movements'), false);
    expect(controller.canAccessRoute('/totem'), false);
    expect(controller.canAccessRoute('/alerts'), true);
    controller.dispose();
  });

  testWidgets('teacher cannot navigate directly to administrator screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    final controller = AppController(_testApi());
    await controller.identify('AABB1234');
    final router = createAppRouter(controller);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('Disponíveis agora'), findsOneWidget);
    for (final path in [
      '/teachers',
      '/tablets',
      '/settings',
      '/alerts',
      '/agenda',
      '/admin/login',
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/home');
    }
    router.go('/totem');
    await tester.pumpAndSettle();
    expect(find.text('Solicitar retirada'), findsOneWidget);
    expect(find.text('Registrar devolução'), findsOneWidget);
    expect(find.text('Meu histórico'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    controller.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('teacher and administrator have distinct login routes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    final controller = AppController(_testApi());
    final router = createAppRouter(controller);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/admin/login');
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Passe o crachá'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('badge-access')));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(find.text('Senha'), findsNothing);
    expect(find.text('Validar crachá'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.text('Acessar com cadastro'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/admin/login');
    expect(find.text('Senha'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    controller.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
