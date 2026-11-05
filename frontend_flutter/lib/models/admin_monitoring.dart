/// Leituras de monitoramento disponíveis apenas para a sessão administrativa.
/// O backend omite detalhes brutos e identificadores RFID sensíveis dos eventos.
class AlertRecord {
  const AlertRecord({
    required this.eventId,
    required this.type,
    required this.title,
    required this.severity,
    required this.occurredAt,
    required this.sessionId,
  });

  final String eventId;
  final String type;
  final String title;
  final String severity;
  final DateTime occurredAt;
  final int? sessionId;

  factory AlertRecord.fromJson(Map<String, dynamic> value) => AlertRecord(
    eventId: value['event_id'] as String,
    type: value['type'] as String,
    title: value['title'] as String,
    severity: value['severity'] as String,
    occurredAt: DateTime.parse(value['occurred_at'] as String).toLocal(),
    sessionId: value['session_id'] as int?,
  );
}

class AdminOverview {
  const AdminOverview({
    required this.total,
    required this.available,
    required this.checkedOut,
    required this.maintenance,
    required this.openSessions,
    required this.divergentSessions,
    required this.inFlightSessions,
    required this.alertEventsTotal,
    required this.recentAlerts,
  });

  final int total;
  final int available;
  final int checkedOut;
  final int maintenance;
  final int openSessions;
  final int divergentSessions;
  final int inFlightSessions;
  final int alertEventsTotal;
  final List<AlertRecord> recentAlerts;

  factory AdminOverview.fromJson(Map<String, dynamic> value) {
    final inventory = value['inventory'] as Map<String, dynamic>;
    final sessions = value['sessions'] as Map<String, dynamic>;
    return AdminOverview(
      total: inventory['total'] as int,
      available: inventory['available'] as int,
      checkedOut: inventory['checked_out'] as int,
      maintenance: inventory['maintenance'] as int,
      openSessions: sessions['open'] as int,
      divergentSessions: sessions['divergent'] as int,
      inFlightSessions: sessions['in_flight'] as int,
      alertEventsTotal: value['alert_events_total'] as int,
      recentAlerts: (value['recent_alerts'] as List<dynamic>)
          .map((item) => AlertRecord.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
