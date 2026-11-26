import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/admin_monitoring.dart';
import '../../services/app_controller.dart';
import '../../widgets/common_widgets.dart';

/// Central administrativa somente leitura; não possui ação de abrir a porta.
class AdminAlertsPage extends StatefulWidget {
  const AdminAlertsPage({required this.controller, super.key});
  final AppController controller;

  @override
  State<AdminAlertsPage> createState() => _AdminAlertsPageState();
}

class _AdminAlertsPageState extends State<AdminAlertsPage> {
  late Future<List<AlertRecord>> alerts;

  @override
  void initState() {
    super.initState();
    alerts = widget.controller.api.adminAlerts();
  }

  void _refresh() =>
      setState(() => alerts = widget.controller.api.adminAlerts());

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PageHeading(
        'Central de alertas',
        'Eventos críticos persistidos pela API. Não representa alarmes ativos.',
      ),
      SectionCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: FutureBuilder<List<AlertRecord>>(
          future: alerts,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ErrorPanel(
                message: 'Falha ao consultar eventos. Verifique sua sessão.',
                onRetry: _refresh,
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final events = snapshot.requireData;
            final textTheme = Theme.of(context).textTheme;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionTitle(
                  '${events.length} eventos recentes',
                  action: IconButton(
                    tooltip: 'Atualizar alertas',
                    onPressed: _refresh,
                    color: AppTheme.muted,
                    icon: const Icon(Icons.refresh_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (events.isEmpty)
                  const StateMessage(
                    message: 'Nenhuma ocorrência crítica registrada.',
                    icon: Icons.verified_outlined,
                    color: AppTheme.success,
                  )
                else
                  for (final event in events) ...[
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      leading: Icon(
                        Icons.report_gmailerrorred_outlined,
                        color: event.severity == 'high'
                            ? AppTheme.danger
                            : AppTheme.warning,
                      ),
                      title: Text(event.title, style: textTheme.titleSmall),
                      subtitle: Text(
                        'ID: ${event.eventId}\nData: ${event.occurredAt.toLocal()}',
                        style: textTheme.bodySmall?.copyWith(
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                      isThreeLine: false,
                      trailing: event.sessionId == null
                          ? null
                          : Text(
                              '#${event.sessionId}',
                              style: textTheme.labelLarge?.copyWith(
                                color: AppTheme.muted,
                                fontFeatures: AppTheme.tabularFigures,
                              ),
                            ),
                    ),
                  ],
              ],
            );
          },
        ),
      ),
    ],
  );
}
