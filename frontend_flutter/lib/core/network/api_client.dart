import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

class ApiClient {
  ApiClient({
    required this._baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 12),
  }) : _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  final Duration timeout;
  String? _accessToken;

  set accessToken(String? value) => _accessToken = value;

  Future<Object?> get(String path, {Map<String, String>? query}) async {
    final uri = _uri(path, query);
    return _send(() => _client.get(uri, headers: _headers));
  }

  Future<Object?> post(String path, Map<String, Object?> body) async {
    final uri = _uri(path);
    return _send(
      () => _client.post(uri, headers: _headers, body: jsonEncode(body)),
    );
  }

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$_baseUrl$path');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  Future<Object?> _send(Future<http.Response> Function() request) async {
    late final http.Response response;
    try {
      response = await request().timeout(timeout);
    } on TimeoutException {
      throw const ApiException('A API demorou para responder.');
    } on SocketException {
      throw const ApiException('Não foi possível conectar à API.');
    } on http.ClientException {
      throw const ApiException(
        'Falha de rede. Verifique a conexão e a configuração CORS da API.',
      );
    }

    Object? decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw ApiException(
          'A API retornou uma resposta inválida.',
          statusCode: response.statusCode,
        );
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['detail']?.toString() ?? decoded['code']?.toString()
          : null;
      throw ApiException(
        message ?? 'A API retornou HTTP ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }
}
