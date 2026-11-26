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
      final textTheme = Theme.of(context).textTheme;
      // Strip marks pending attention; the counters repeat it in text.
      final accent = data.divergentSessions > 0
          ? AppTheme.danger
          : data.alertEventsTotal > 0
          ? AppTheme.warning
          : null;
      final counters = [
        (
          'Eventos registrados',
          data.alertEventsTotal,
          data.alertEventsTotal > 0 ? AppTheme.warning : AppTheme.text,
        ),
        (
          'Sessões divergentes',
          data.divergentSessions,
          data.divergentSessions > 0 ? AppTheme.danger : AppTheme.text,
        ),
        ('Solicitações em curso', data.inFlightSessions, AppTheme.text),
        ('Retiradas em andamento', data.openSessions, AppTheme.text),
      ];
      return SectionCard(
        accent: accent,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitle(
              'Ocorrências e pendências',
              action: TextButton.icon(
                onPressed: () => context.go('/alerts'),
                icon: const Icon(Icons.arrow_forward_outlined),
                label: const Text('Ver todos os eventos'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 560 ? 4 : 2;
                final width =
                    (constraints.maxWidth - AppSpacing.md * (columns - 1)) /
                    columns;
                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final (label, value, color) in counters)
                      SizedBox(
                        width: width,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$value',
                              style: textTheme.headlineMedium?.copyWith(
                                color: color,
                                height: 1.1,
                                fontFeatures: AppTheme.tabularFigures,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(label, style: textTheme.bodySmall),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Este histórico não indica alarmes ativos. Uma abertura de porta isolada não caracteriza invasão.',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (data.recentAlerts.isEmpty)
              const StateMessage(
                message: 'Nenhuma ocorrência crítica registrada.',
                icon: Icons.verified_outlined,
                color: AppTheme.success,
              )
            else
              for (final event in data.recentAlerts) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.title, style: textTheme.titleSmall),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              formatDateTime(event.occurredAt),
                              style: textTheme.bodySmall?.copyWith(
                                fontFeatures: AppTheme.tabularFigures,
                              ),
                            ),
                            Text(
                              'Registro ${event.eventId}',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
          ],
        ),
      );
    },
  );
}
