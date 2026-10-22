class AdminSession {
  const AdminSession({
    required this.username,
    required this.accessToken,
    required this.expiresIn,
  });

  final String username;
  final String accessToken;
  final int expiresIn;

  factory AdminSession.fromJson(Map<String, dynamic> json) => AdminSession(
    username: _asString(json['username']),
    accessToken: _asString(json['access_token']),
    expiresIn: _asInt(json['expires_in']),
  );
}

class Professor {
  const Professor({
    required this.id,
    required this.name,
    required this.registration,
    required this.active,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String registration;
  final bool active;
  final DateTime createdAt;

  factory Professor.fromJson(Map<String, dynamic> json) => Professor(
    id: _asInt(json['id']),
    name: _asString(json['name']),
    registration: _asString(json['registration']),
    active: json['active'] == true,
    createdAt: _asDate(json['created_at']),
  );
}

class Tablet {
  const Tablet({
    required this.id,
    required this.assetCode,
    required this.hasRfidTag,
    required this.status,
    required this.updatedAt,
  });

  final int id;
  final String assetCode;
  final bool hasRfidTag;
  final String status;
  final DateTime updatedAt;

  factory Tablet.fromJson(Map<String, dynamic> json) => Tablet(
    id: _asInt(json['id']),
    assetCode: _asString(json['asset_code']),
    hasRfidTag: json['has_rfid_tag'] == true,
    status: _asString(json['status']),
    updatedAt: _asDate(json['updated_at']),
  );
}

class Availability {
  const Availability({
    required this.available,
    required this.total,
    required this.tablets,
  });

  final int available;
  final int total;
  final List<Tablet> tablets;

  factory Availability.fromJson(Map<String, dynamic> json) => Availability(
    available: _asInt(json['available']),
    total: _asInt(json['total']),
    tablets: _asList(json['tablets'])
        .map((item) => Tablet.fromJson(item))
        .toList(growable: false),
  );
}

class HistoryRow {
  const HistoryRow({
    required this.sessionId,
    required this.professorName,
    required this.registration,
    required this.requestedQuantity,
    required this.takenQuantity,
    required this.pendingQuantity,
    required this.purpose,
    required this.className,
    required this.status,
    required this.startedAt,
    required this.completedAt,
  });

  final int sessionId;
  final String professorName;
  final String registration;
  final int requestedQuantity;
  final int takenQuantity;
  final int pendingQuantity;
  final String purpose;
  final String? className;
  final String status;
  final DateTime startedAt;
  final DateTime? completedAt;

  factory HistoryRow.fromJson(Map<String, dynamic> json) => HistoryRow(
    sessionId: _asInt(json['session_id']),
    professorName: _asString(json['professor_name']),
    registration: _asString(json['registration']),
    requestedQuantity: _asInt(json['requested_quantity']),
    takenQuantity: _asInt(json['taken_quantity']),
    pendingQuantity: _asInt(json['pending_quantity']),
    purpose: _asString(json['purpose']),
    className: json['class_name']?.toString(),
    status: _asString(json['status']),
    startedAt: _asDate(json['started_at']),
    completedAt: json['completed_at'] == null
        ? null
        : _asDate(json['completed_at']),
  );
}

class HistoryResultPage {
  const HistoryResultPage({
    required this.total,
    required this.limit,
    required this.offset,
    required this.rows,
  });

  final int total;
  final int limit;
  final int offset;
  final List<HistoryRow> rows;

  factory HistoryResultPage.fromJson(Map<String, dynamic> json) =>
      HistoryResultPage(
        total: _asInt(json['total']),
        limit: _asInt(json['limit']),
        offset: _asInt(json['offset']),
        rows: _asList(json['rows'])
            .map((item) => HistoryRow.fromJson(item))
            .toList(growable: false),
      );
}

class CheckoutItem {
  const CheckoutItem({
    required this.assetCode,
    required this.status,
    required this.checkedOutAt,
    required this.returnedAt,
  });

  final String assetCode;
  final String status;
  final DateTime checkedOutAt;
  final DateTime? returnedAt;

  factory CheckoutItem.fromJson(Map<String, dynamic> json) => CheckoutItem(
    assetCode: _asString(json['asset_code']),
    status: _asString(json['status']),
    checkedOutAt: _asDate(json['checked_out_at']),
    returnedAt: json['returned_at'] == null
        ? null
        : _asDate(json['returned_at']),
  );
}

class CheckoutResult {
  const CheckoutResult({
    required this.sessionId,
    required this.status,
    required this.professorName,
    required this.requestedQuantity,
    required this.takenQuantity,
    required this.pendingQuantity,
    required this.items,
    required this.duplicateEvent,
    required this.divergence,
  });

  final int sessionId;
  final String status;
  final String professorName;
  final int requestedQuantity;
  final int takenQuantity;
  final int pendingQuantity;
  final List<CheckoutItem> items;
  final bool duplicateEvent;
  final String? divergence;

  factory CheckoutResult.fromJson(Map<String, dynamic> json) => CheckoutResult(
    sessionId: _asInt(json['session_id']),
    status: _asString(json['status']),
    professorName: _asString(json['professor_name']),
    requestedQuantity: _asInt(json['requested_quantity']),
    takenQuantity: _asInt(json['taken_quantity']),
    pendingQuantity: _asInt(json['pending_quantity']),
    items: _asList(json['items'])
        .map((item) => CheckoutItem.fromJson(item))
        .toList(growable: false),
    duplicateEvent: json['duplicate_event'] == true,
    divergence: json['divergence']?.toString(),
  );
}

class ApiHealth {
  const ApiHealth({required this.status, required this.database});

  final String status;
  final String database;

  factory ApiHealth.fromJson(Map<String, dynamic> json) => ApiHealth(
    status: _asString(json['status']),
    database: _asString(json['database']),
  );
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  throw const FormatException('Formato inesperado recebido da API.');
}

List<Map<String, dynamic>> _asList(Object? value) {
  if (value is! List) {
    throw const FormatException('Formato inesperado recebido da API.');
  }
  return value.map(_asMap).toList(growable: false);
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw const FormatException('Número inválido recebido da API.');
}

String _asString(Object? value) {
  if (value is String) return value;
  throw const FormatException('Texto inválido recebido da API.');
}

DateTime _asDate(Object? value) {
  if (value is String) {
    final date = DateTime.tryParse(value);
    if (date != null) return date.toLocal();
  }
  throw const FormatException('Data inválida recebida da API.');
}
