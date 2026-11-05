import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/core/network/api_exception.dart';
import 'package:frontend_flutter/services/app_controller.dart';
import 'package:frontend_flutter/services/system_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('terminal enrollment uses administrative session', () async {
    final calls = <String>[];
    final api = SystemApi(
      baseUrl: 'http://test.local',
      httpClient: MockClient((request) async {
        calls.add(request.url.path);
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
        expect(request.headers['authorization'], 'Bearer admin-token');
        if (request.url.path == '/admin/session') {
          return http.Response(
            jsonEncode({'username': 'admin', 'role': 'admin'}),
            200,
          );
        }
        return http.Response(jsonEncode({'authorized': true}), 200);
      }),
    );
    await api.loginAdmin('admin', 'test-password');
    await api.authorizeTerminal();
    expect(calls, ['/admin/login', '/admin/session', '/terminal/authorize']);
  });

  test('unapproved terminal cannot create local teacher identity', () async {
    final controller = AppController(
      SystemApi(
        baseUrl: 'http://test.local',
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({'detail': 'Terminal não autorizado'}),
            401,
          ),
        ),
      ),
    );
    await expectLater(
      controller.identify('AABB1234'),
      throwsA(isA<ApiException>()),
    );
    expect(controller.hasIdentity, false);
    controller.dispose();
  });

  testWidgets('teacher identity expires without requiring a password', (
    tester,
  ) async {
    final controller = AppController(
      SystemApi(
        baseUrl: 'http://test.local',
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'access_token': 'teacher-token',
              'expires_in': 5,
              'professor': {
                'id': 1,
                'name': 'Ana',
                'registration': 'T-1',
                'active': true,
                'created_at': '2026-01-01T00:00:00Z',
              },
            }),
            200,
          ),
        ),
      ),
    );
    await controller.identify('AABB1234');
    expect(controller.hasIdentity, true);
    await tester.pump(const Duration(seconds: 6));
    expect(controller.hasIdentity, false);
    controller.dispose();
  });
}
