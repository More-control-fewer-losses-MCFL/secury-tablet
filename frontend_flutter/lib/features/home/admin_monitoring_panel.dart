import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/display.dart';
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
          message: 'Não foi possível carregar os indicadores de ocorrências.',
          onRetry: _reload,
        );
      }
      if (!snapshot.hasData) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Carregando ocorrências',
            ),
          ),
        );
      }
      final data = snapshot.requireData;
      return SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitle(
              'Ocorrências e pendências',
              action: TextButton.icon(
                onPressed: () => context.go('/alerts'),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Ver todos os eventos'),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                StatusPill(
                  'Eventos registrados: ${data.alertEventsTotal}',
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
                  'Retiradas em andamento: ${data.openSessions}',
                  color: AppTheme.muted,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Este histórico não indica alarmes ativos. Uma abertura de porta isolada não caracteriza invasão.',
              style: TextStyle(color: AppTheme.muted),
            ),
            const SizedBox(height: 16),
            if (data.recentAlerts.isEmpty)
              const StateMessage(
                message: 'Nenhuma ocorrência crítica registrada.',
                icon: Icons.verified_outlined,
                color: AppTheme.success,
              )
            else
              ...data.recentAlerts.map(
                (event) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.warning_amber_outlined,
                          color: event.severity == 'high'
                              ? AppTheme.danger
                              : AppTheme.warning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatDateTime(event.occurredAt),
                              style: const TextStyle(color: AppTheme.muted),
                            ),
                            Text(
                              'Registro ${event.eventId}',
                              style: const TextStyle(color: AppTheme.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
