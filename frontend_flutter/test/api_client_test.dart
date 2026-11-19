import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/core/network/api_client.dart';
import 'package:frontend_flutter/core/network/api_exception.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final entry in {
    401: ApiErrorKind.authentication,
    403: ApiErrorKind.authorization,
    404: ApiErrorKind.notFound,
    409: ApiErrorKind.conflict,
    422: ApiErrorKind.validation,
    429: ApiErrorKind.rateLimit,
    500: ApiErrorKind.server,
    502: ApiErrorKind.server,
    503: ApiErrorKind.server,
  }.entries) {
    test(
      'HTTP ${entry.key} keeps its category even when proxy returns HTML',
      () async {
        final client = ApiClient(
          baseUrl: 'http://test.local',
          client: MockClient(
            (_) async =>
                http.Response('<h1>internal-fixture-only</h1>', entry.key),
          ),
        );
        await expectLater(
          client.get('/history'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.category, 'category', entry.value)
                .having((e) => e.statusCode, 'status', entry.key)
                .having(
                  (e) => e.message,
                  'safe message',
                  isNot(contains('internal-fixture-only')),
                ),
          ),
        );
      },
    );
  }

  test(
    'validation identifies known fields without echoing values or raw detail',
    () async {
      final client = ApiClient(
        baseUrl: 'http://test.local',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'detail': [
                {
                  'loc': ['body', 'username'],
                  'msg': 'unsafe-detail-fixture',
                  'input': 'private-fixture',
                },
                {
                  'loc': ['body', 'password'],
                  'msg': 'unsafe-detail-fixture',
                  'input': 'private-fixture',
                },
              ],
            }),
            422,
          ),
        ),
      );
      await expectLater(
        client.post('/auth/professor/login', {}),
        throwsA(
          isA<ApiException>()
              .having(
                (e) => e.message,
                'fields',
                'Confira os campos: Usuário, Senha.',
              )
              .having(
                (e) => e.message,
                'no raw detail',
                isNot(contains('fixture')),
              ),
        ),
      );
    },
  );

  test(
    'server JSON and login failures never echo arbitrary server details',
    () async {
      for (final status in [401, 500]) {
        final client = ApiClient(
          baseUrl: 'http://test.local',
          client: MockClient(
            (_) async => http.Response(
              jsonEncode({'detail': 'private-internal-fixture'}),
              status,
            ),
          ),
        );
        await expectLater(
          client.post('/auth/professor/login', {}),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'safe message',
              isNot(contains('private-internal')),
            ),
          ),
        );
      }
    },
  );

  test('business conflicts keep a meaningful curated description', () async {
    final client = ApiClient(
      baseUrl: 'http://test.local',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'code': 'InsufficientAvailabilityError',
            'detail': 'ignored-fixture',
          }),
          409,
        ),
      ),
    );
    await expectLater(
      client.post('/checkout-requests', {}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.category, 'category', ApiErrorKind.conflict)
            .having(
              (e) => e.message,
              'description',
              contains('tablets disponíveis'),
            ),
      ),
    );
  });

  test(
    'RFID terminal authorization is distinct from incorrect password',
    () async {
      final client = ApiClient(
        baseUrl: 'http://test.local',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'detail': 'Terminal não autorizado ou revogado.'}),
            401,
          ),
        ),
      );
      await expectLater(
        client.post('/auth/rfid', {}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.category, 'category', ApiErrorKind.authorization)
              .having((e) => e.message, 'description', contains('terminal')),
        ),
      );
    },
  );

  test('timeout reports uncertain outcome and never retries a POST', () async {
    var calls = 0;
    final pending = Completer<http.Response>();
    final client = ApiClient(
      baseUrl: 'http://test.local',
      timeout: const Duration(milliseconds: 1),
      client: MockClient((_) {
        calls++;
        return pending.future;
      }),
    );
    await expectLater(
      client.post('/checkout-requests', {}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.category, 'category', ApiErrorKind.timeout)
            .having(
              (e) => e.recoveryHint,
              'check before retry',
              contains('histórico'),
            ),
      ),
    );
    expect(calls, 1);
    pending.complete(http.Response('{}', 200));
  });

  test('network failure has an actionable classification without low level details', () async {
    final client = ApiClient(
      baseUrl: 'http://test.local',
      client: MockClient(
        (_) async => throw http.ClientException('private-fixture'),
      ),
    );
    await expectLater(
      client.get('/health'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.category, 'category', ApiErrorKind.network)
            .having(
              (e) => e.message,
              'safe message',
              isNot(contains('private-fixture')),
            ),
      ),
    );
  });

  test(
    'invalid successful JSON is distinct from an HTTP server failure',
    () async {
      final client = ApiClient(
        baseUrl: 'http://test.local',
        client: MockClient(
          (_) async => http.Response('<html>not-json</html>', 200),
        ),
      );
      await expectLater(
        client.get('/health'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.category,
            'category',
            ApiErrorKind.invalidResponse,
          ),
        ),
      );
    },
  );
  test(
    'expired terminal cookie guides RFID users to terminal authorization',
    () async {
      final client = ApiClient(
        baseUrl: 'http://test.local',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'detail': 'Sessão inválida ou expirada.'}),
            401,
          ),
        ),
      );
      await expectLater(
        client.post('/auth/rfid', {}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.category, 'category', ApiErrorKind.authorization)
              .having(
                (e) => e.message,
                'terminal instruction',
                contains('terminal'),
              )
              .having(
                (e) => e.recoveryHint,
                'no password instruction',
                isNot(contains('senha')),
              ),
        ),
      );
    },
  );
}
