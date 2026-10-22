import 'package:http/http.dart' as http;

import '../core/network/api_client.dart';
import '../models/system_models.dart';

class SystemApi {
  SystemApi({
    required String baseUrl,
    ApiClient? client,
    http.Client? httpClient,
  }) : _client = client ?? ApiClient(baseUrl: baseUrl, client: httpClient);

  final ApiClient _client;

  Future<AdminSession> loginAdmin(String username, String password) async {
    final session = AdminSession.fromJson(
      _asMap(
        await _client.post('/admin/login', {
          'username': username,
          'password': password,
        }),
      ),
    );
    _client.accessToken = session.accessToken;
    try {
      final verified = _asMap(await _client.get('/admin/session'));
      if (verified['username'] != session.username ||
          verified['role'] != 'admin') {
        throw const FormatException(
          'A API não confirmou a sessão administrativa.',
        );
      }
      return session;
    } catch (_) {
      _client.accessToken = null;
      rethrow;
    }
  }

  void clearAdminSession() => _client.accessToken = null;

  Future<ApiHealth> health() async =>
      ApiHealth.fromJson(_asMap(await _client.get('/health')));

  Future<Professor> identifyBadge(String uid) async {
    final encodedUid = Uri.encodeComponent(uid.trim());
    return Professor.fromJson(
      _asMap(await _client.get('/professors/by-badge/$encodedUid')),
    );
  }

  Future<List<Tablet>> tablets({String? status}) async {
    final query = status == null ? null : {'status': status};
    final value = await _client.get('/tablets', query: query);
    if (value is! List) {
      throw const FormatException(
        'Formato de tablets inválido recebido da API.',
      );
    }
    return value
        .map((item) => Tablet.fromJson(_asMap(item)))
        .toList(growable: false);
  }

  Future<Availability> availability() async =>
      Availability.fromJson(_asMap(await _client.get('/tablets/available')));

  Future<HistoryResultPage> history({
    int? professorId,
    String? status,
    DateTime? since,
    DateTime? until,
    int limit = 20,
    int offset = 0,
  }) async {
    final query = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
      if (professorId != null) 'professor_id': '$professorId',
      if (status != null && status.isNotEmpty) 'status': status,
      if (since != null) 'since': since.toUtc().toIso8601String(),
      if (until != null) 'until': until.toUtc().toIso8601String(),
    };
    return HistoryResultPage.fromJson(
      _asMap(await _client.get('/history', query: query)),
    );
  }

  Future<CheckoutResult> createCheckout({
    required String badgeUid,
    required int quantity,
    required String purpose,
    String? className,
  }) async => CheckoutResult.fromJson(
    _asMap(
      await _client.post('/checkout-requests', {
        'badge_uid': badgeUid,
        'quantity': quantity,
        'purpose': purpose,
        if (className != null && className.isNotEmpty) 'class_name': className,
      }),
    ),
  );

  Future<CheckoutResult> reconcileReturn({
    required int sessionId,
    required String eventId,
  }) async => CheckoutResult.fromJson(
    _asMap(
      await _client.post('/returns/reconcile', {
        'session_id': sessionId,
        'event_id': eventId,
      }),
    ),
  );

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    throw const FormatException('Formato inesperado recebido da API.');
  }
}
