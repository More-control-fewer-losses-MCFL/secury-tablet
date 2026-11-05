import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/admin_monitoring.dart';
import '../../services/system_api.dart';
import '../../widgets/common_widgets.dart';

/// Mostra eventos históricos, não o estado de um alarme físico.
class AdminMonitoringPanel extends StatefulWidget {
  const AdminMonitoringPanel({required this.api, super.key});
  final SystemApi api;

  @override
  State<AdminMonitoringPanel> createState() => _AdminMonitoringPanelState();
}

class _AdminMonitoringPanelState extends State<AdminMonitoringPanel> {
  late Future<AdminOverview> overview;

  @override
  void initState() {
    super.initState();
    overview = widget.api.adminOverview();
  }

  void _reload() => setState(() => overview = widget.api.adminOverview());

  @override
  Widget build(BuildContext context) => FutureBuilder<AdminOverview>(
    future: overview,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return ErrorPanel(
          message: 'Não foi possível carregar indicadores de incidentes.',
          onRetry: _reload,
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final data = snapshot.requireData;
      return SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              'Monitoramento e ocorrências',
              action: TextButton.icon(
                onPressed: () => context.go('/alerts'),
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Central de alertas'),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusPill(
                  'Alertas registrados: ${data.alertEventsTotal}',
                  color: data.alertEventsTotal > 0
                      ? AppTheme.warning
                      : AppTheme.success,
                ),
                StatusPill(
                  'Sessões divergentes: ${data.divergentSessions}',
                  color: data.divergentSessions > 0
                      ? AppTheme.danger
                      : AppTheme.success,
                ),
                StatusPill(
                  'Solicitações em curso: ${data.inFlightSessions}',
                  color: AppTheme.blue,
                ),
                StatusPill(
                  'Em manutenção: ${data.maintenance}',
                  color: AppTheme.muted,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Eventos históricos, não alarmes ativos. Abertura de porta isolada não indica invasão.',
              style: TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            if (data.recentAlerts.isEmpty)
              const Text('Nenhum evento de alerta registrado.')
            else
              ...data.recentAlerts.map(
                (event) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.warning_amber_outlined,
                    color: event.severity == 'high'
                        ? AppTheme.danger
                        : AppTheme.warning,
                  ),
                  title: Text(event.title),
                  subtitle: Text(
                    'Registro: ${event.occurredAt.day}/${event.occurredAt.month}/${event.occurredAt.year} · ${event.eventId}',
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
