import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'http_client_factory.dart';

class ApiClient {
  ApiClient({
    required this._baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 12),
  }) : _client = client ?? createHttpClient();

  final String _baseUrl;
  final http.Client _client;
  final Duration timeout;
  String? _accessToken;

  set accessToken(String? value) => _accessToken = value;

  Future<Object?> get(String path, {Map<String, String>? query}) async {
    final uri = _uri(path, query);
    return _send(() => _client.get(uri, headers: _headers), path: path);
  }

  Future<Object?> post(String path, Map<String, Object?> body) async {
    final uri = _uri(path);
    return _send(
      () => _client.post(uri, headers: _headers, body: jsonEncode(body)),
      path: path,
    );
  }

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.base.resolve('$_baseUrl$path');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  Future<Object?> _send(
    Future<http.Response> Function() request, {
    required String path,
  }) async {
    late final http.Response response;
    try {
      response = await request().timeout(timeout);
    } on TimeoutException {
      throw const ApiException(
        'O sistema demorou além do esperado para responder.',
        kind: ApiErrorKind.timeout,
      );
    } on SocketException {
      throw const ApiException(
        'Não foi possível conectar ao sistema.',
        kind: ApiErrorKind.network,
      );
    } on http.ClientException {
      throw const ApiException(
        'Não foi possível conectar ao sistema.',
        kind: ApiErrorKind.network,
      );
    }

    final success = response.statusCode >= 200 && response.statusCode < 300;
    Object? decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        // Proxy errors may be HTML. Preserve the HTTP classification.
        if (success) {
          throw ApiException(
            'O sistema enviou uma resposta que não pôde ser reconhecida.',
            statusCode: response.statusCode,
            kind: ApiErrorKind.invalidResponse,
          );
        }
      }
    }
    if (!success) {
      throw ApiException.fromResponse(
        response.statusCode,
        decoded,
        login: path == '/admin/login' || path == '/auth/professor/login',
        rfid: path == '/auth/rfid',
      );
    }
    return decoded;
  }
}
