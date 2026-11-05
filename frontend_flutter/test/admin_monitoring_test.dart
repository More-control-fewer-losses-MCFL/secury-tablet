// Install as frontend_flutter/test/admin_monitoring_test.dart.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/core/network/api_exception.dart';
import 'package:frontend_flutter/services/system_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'dashboard e incidentes são lidos usando token administrativo',
    () async {
      final client = MockClient((request) async {
        if (request.url.path == '/admin/login') {
          return http.Response(
            jsonEncode({
              'access_token': 'admin-test-token',
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
        expect(request.headers['authorization'], 'Bearer admin-test-token');
        if (request.url.path == '/admin/overview') {
          return http.Response(
            jsonEncode({
              'inventory': {
                'total': 10,
                'available': 7,
                'checked_out': 2,
                'maintenance': 1,
              },
              'sessions': {'open': 2, 'divergent': 1, 'in_flight': 0},
              'alert_events_total': 1,
              'recent_alerts': [
                {
                  'event_id': 'alert-12345678',
                  'type': 'LOCK_ERROR',
                  'title': 'Falha na fechadura',
                  'severity': 'high',
                  'occurred_at': '2026-11-05T16:00:00Z',
                  'session_id': 42,
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path == '/admin/alerts') {
          return http.Response('[]', 200);
        }
        return http.Response('{}', 404);
      });
      final api = SystemApi(baseUrl: 'http://test.local', httpClient: client);
      await api.loginAdmin('admin', 'password');
      final dashboard = await api.adminOverview();
      expect(dashboard.total, 10);
      expect(dashboard.divergentSessions, 1);
      expect(dashboard.recentAlerts.single.sessionId, 42);
      expect(await api.adminAlerts(), isEmpty);
    },
  );

  test('professor não pode usar API de monitoramento administrativo', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/auth/rfid') {
        return http.Response(
          jsonEncode({
            'access_token': 'teacher-test-token',
            'expires_in': 180,
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
      expect(request.headers['authorization'], 'Bearer teacher-test-token');
      return http.Response(
        jsonEncode({'detail': 'Sessão administrativa inválida.'}),
        401,
      );
    });
    final api = SystemApi(baseUrl: 'http://test.local', httpClient: client);
    await api.loginTeacher('AABB1234');
    await expectLater(api.adminOverview(), throwsA(isA<ApiException>()));
  });
}
