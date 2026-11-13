import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/display.dart';
import '../../models/system_models.dart';
import '../../services/app_controller.dart';
import '../../widgets/common_widgets.dart';
import '../shell/locker_illustration.dart';
import 'admin_monitoring_panel.dart';
import 'portal_welcome.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.controller, super.key});

  final AppController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<_DashboardData> dashboard;

  @override
  void initState() {
    super.initState();
    dashboard = _load();
  }

  Future<_DashboardData> _load() async {
    final results = await Future.wait<Object>([
      widget.controller.api.tablets(),
      widget.controller.api.history(limit: 8),
    ]);
    return _DashboardData(
      results[0] as List<Tablet>,
      results[1] as HistoryResultPage,
    );
  }

  void _refresh() => setState(() => dashboard = _load());

  @override
  Widget build(BuildContext context) => FutureBuilder<_DashboardData>(
    future: dashboard,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        final message = snapshot.error is ApiException
            ? (snapshot.error! as ApiException).message
            : 'Não foi possível carregar os dados da API.';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeading('Início', 'Visão geral do sistema'),
            ErrorPanel(message: message, onRetry: _refresh),
          ],
        );
      }
      if (!snapshot.hasData) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(
              semanticsLabel: 'Carregando painel',
            ),
          ),
        );
      }
      final data = snapshot.requireData;
      final available = data.tablets
          .where((tablet) => tablet.status == 'AVAILABLE')
          .length;
      final checkedOut = data.tablets
          .where((tablet) => tablet.status == 'CHECKED_OUT')
          .length;
      final maintenance = data.tablets
          .where((tablet) => tablet.status == 'MAINTENANCE')
          .length;
      final metrics = [
        _MetricCard(
          'Tablets cadastrados',
          '${data.tablets.length}',
          Icons.tablet_mac_outlined,
          AppTheme.blue,
        ),
        _MetricCard(
          'Disponíveis',
          '$available',
          Icons.check_circle_outline,
          AppTheme.success,
        ),
        _MetricCard(
          'Emprestados',
          '$checkedOut',
          Icons.output_outlined,
          AppTheme.blue,
        ),
        _MetricCard(
          'Em manutenção',
          '$maintenance',
          Icons.build_outlined,
          AppTheme.warning,
        ),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PortalWelcome(
            controller: widget.controller,
            summary: '$available tablets disponíveis',
            detail:
                '$checkedOut em circulação e $maintenance em manutenção. '
                'Acompanhe as ocorrências e as devoluções nos painéis abaixo.',
            onRefresh: _refresh,
            shortcuts: const [
              PortalShortcut(
                'Consultar patrimônio',
                Icons.tablet_mac_outlined,
                '/tablets',
              ),
              PortalShortcut(
                'Ver ocorrências',
                Icons.notifications_active_outlined,
                '/alerts',
              ),
              PortalShortcut(
                'Ver devoluções',
                Icons.assignment_return_outlined,
                '/returns',
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionTitle('Visão geral do patrimônio'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final enlargedText =
                  MediaQuery.textScalerOf(context).scale(14) > 19;
              final columns = constraints.maxWidth >= 1050 && !enlargedText
                  ? 4
                  : constraints.maxWidth >= 600
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - 12 * (columns - 1)) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final metric in metrics)
                    SizedBox(width: width, child: metric),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _OperationsCard(
            onAlerts: () => context.go('/alerts'),
            onReturns: () => context.go('/returns'),
          ),
          const SizedBox(height: 24),
          AdminMonitoringPanel(
            key: ObjectKey(dashboard),
            api: widget.controller.api,
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final recent = _RecentMovements(data.history.rows);
              final access = _QuickAccess(onTap: (path) => context.go(path));
              final enlargedText =
                  MediaQuery.textScalerOf(context).scale(14) > 19;
              if (constraints.maxWidth >= 1000 && !enlargedText) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: recent),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: access),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [recent, const SizedBox(height: 20), access],
              );
            },
          ),
        ],
      );
    },
  );
}

class _DashboardData {
  const _DashboardData(this.tablets, this.history);
  final List<Tablet> tablets;
  final HistoryResultPage history;
}

class _OperationsCard extends StatelessWidget {
  const _OperationsCard({required this.onAlerts, required this.onReturns});

  final VoidCallback onAlerts;
  final VoidCallback onReturns;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Acompanhamento do armário'),
            const SizedBox(height: 8),
            const Text(
              'Consulte as ocorrências registradas e acompanhe a devolução dos tablets em uso.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: onAlerts,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Central de alertas'),
                ),
                OutlinedButton.icon(
                  onPressed: onReturns,
                  icon: const Icon(Icons.assignment_return_outlined),
                  label: const Text('Acompanhar devoluções'),
                ),
              ],
            ),
          ],
        );
        if (constraints.maxWidth < 850) return content;
        return Row(
          children: [
            Expanded(child: content),
            const SizedBox(width: 24),
            Semantics(
              image: true,
              label: 'Armário para guardar e conferir os tablets',
              child: const ExcludeSemantics(
                child: SizedBox(
                  width: 125,
                  height: 140,
                  child: LockerIllustration(),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.title, this.value, this.icon, this.color);

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppTheme.muted)),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RecentMovements extends StatelessWidget {
  const _RecentMovements(this.rows);

  final List<HistoryRow> rows;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          'Movimentações recentes',
          action: TextButton(
            onPressed: () => context.go('/history'),
            child: const Text('Ver histórico'),
          ),
        ),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          const StateMessage(
            message: 'As retiradas e devoluções aparecerão aqui quando forem registradas.',
            icon: Icons.receipt_long_outlined,
          )
        else
          for (final row in rows.take(6))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.professorName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text('${row.takenQuantity} tablet(s) · ${row.purpose}'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        formatDateTime(row.startedAt),
                        style: const TextStyle(color: AppTheme.muted),
                      ),
                      StatusPill(
                        sessionStatusLabel(row.status),
                        color: sessionStatusColor(row.status),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      ],
    ),
  );
}

class _QuickAccess extends StatelessWidget {
  const _QuickAccess({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      children: [
        const SectionTitle('Gerenciar e consultar'),
        const SizedBox(height: 12),
        _AccessTile(
          icon: Icons.badge_outlined,
          title: 'Cadastro de professores',
          action: 'Consultar e sincronizar cadastros',
          onTap: () => onTap('/teachers'),
        ),
        _AccessTile(
          icon: Icons.tablet_mac_outlined,
          title: 'Patrimônio de tablets',
          action: 'Consultar equipamentos e situação',
          onTap: () => onTap('/tablets'),
        ),
        _AccessTile(
          icon: Icons.receipt_long_outlined,
          title: 'Histórico e relatórios',
          action: 'Consultar movimentações registradas',
          onTap: () => onTap('/history'),
        ),
        _AccessTile(
          icon: Icons.calendar_month_outlined,
          title: 'Agenda de movimentações',
          action: 'Consultar a visão por período',
          onTap: () => onTap('/agenda'),
        ),
      ],
    ),
  );
}

class _AccessTile extends StatelessWidget {
  const _AccessTile({
    required this.icon,
    required this.title,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: AppTheme.blue),
    title: Text(title),
    subtitle: Text(action),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
