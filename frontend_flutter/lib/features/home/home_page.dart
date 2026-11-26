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
      final total = data.tablets.length;
      final available = data.tablets
          .where((tablet) => tablet.status == 'AVAILABLE')
          .length;
      final checkedOut = data.tablets
          .where((tablet) => tablet.status == 'CHECKED_OUT')
          .length;
      final maintenance = data.tablets
          .where((tablet) => tablet.status == 'MAINTENANCE')
          .length;
      String share(int value) => total == 0
          ? 'Sem tablets cadastrados'
          : '${value * 100 ~/ total}% do total';
      final metrics = [
        MetricCard(
          label: 'Tablets cadastrados',
          value: '$total',
          caption: 'no patrimônio',
        ),
        MetricCard(
          label: 'Disponíveis',
          value: '$available',
          caption: share(available),
          color: AppTheme.success,
        ),
        MetricCard(
          label: 'Emprestados',
          value: '$checkedOut',
          caption: share(checkedOut),
          color: AppTheme.blue,
        ),
        MetricCard(
          label: 'Em manutenção',
          value: '$maintenance',
          caption: share(maintenance),
          color: AppTheme.warning,
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
          const SizedBox(height: AppSpacing.xl),
          const SectionTitle('Visão geral do patrimônio'),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final enlargedText =
                  MediaQuery.textScalerOf(context).scale(14) > 19;
              final columns = constraints.maxWidth >= 1050 && !enlargedText
                  ? 4
                  : constraints.maxWidth >= 600 || !enlargedText
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - AppSpacing.sm * (columns - 1)) /
                  columns;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final metric in metrics)
                    SizedBox(width: width, child: metric),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          // Attention first: occurrences/pending items outrank history.
          LayoutBuilder(
            builder: (context, constraints) {
              final monitoring = AdminMonitoringPanel(
                key: ObjectKey(dashboard),
                api: widget.controller.api,
              );
              final operations = _OperationsCard(
                onAlerts: () => context.go('/alerts'),
                onReturns: () => context.go('/returns'),
              );
              final enlargedText =
                  MediaQuery.textScalerOf(context).scale(14) > 19;
              if (constraints.maxWidth >= 1000 && !enlargedText) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: monitoring),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(flex: 2, child: operations),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  monitoring,
                  const SizedBox(height: AppSpacing.lg),
                  operations,
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
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
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(flex: 2, child: access),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  recent,
                  const SizedBox(height: AppSpacing.lg),
                  access,
                ],
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

/// Action card: the two operational follow-ups, with the cabinet cue.
class _OperationsCard extends StatelessWidget {
  const _OperationsCard({required this.onAlerts, required this.onReturns});

  final VoidCallback onAlerts;
  final VoidCallback onReturns;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle('Acompanhamento do armário'),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Consulte as ocorrências registradas e acompanhe a devolução dos tablets em uso.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onAlerts,
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Central de alertas'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: onReturns,
              icon: const Icon(Icons.assignment_return_outlined),
              label: const Text('Acompanhar devoluções'),
            ),
          ],
        );
        if (constraints.maxWidth < 420) return content;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: content),
            const SizedBox(width: AppSpacing.lg),
            Semantics(
              image: true,
              label: 'Armário para guardar e conferir os tablets',
              child: const ExcludeSemantics(
                child: SizedBox(
                  width: 96,
                  height: 108,
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

/// List card: recent movements separated by dividers.
class _RecentMovements extends StatelessWidget {
  const _RecentMovements(this.rows);

  final List<HistoryRow> rows;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final visible = rows.take(6).toList();
    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
          const SizedBox(height: AppSpacing.xs),
          if (visible.isEmpty)
            const StateMessage(
              message: 'As retiradas e devoluções aparecerão aqui quando forem registradas.',
              icon: Icons.receipt_long_outlined,
            )
          else
            for (var index = 0; index < visible.length; index++) ...[
              if (index > 0) const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visible[index].professorName,
                          style: textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${visible[index].takenQuantity} tablet(s) · ${visible[index].purpose}',
                          style: textTheme.bodyMedium,
                        ),
                        Text(
                          formatDateTime(visible[index].startedAt),
                          style: textTheme.bodySmall?.copyWith(
                            fontFeatures: AppTheme.tabularFigures,
                          ),
                        ),
                      ],
                    ),
                    StatusPill(
                      sessionStatusLabel(visible[index].status),
                      color: sessionStatusColor(visible[index].status),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}

class _QuickAccess extends StatelessWidget {
  const _QuickAccess({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Gerenciar e consultar'),
        const SizedBox(height: AppSpacing.xs),
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
    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
    title: Text(title, style: Theme.of(context).textTheme.titleSmall),
    subtitle: Text(action, style: Theme.of(context).textTheme.bodySmall),
    trailing: const Icon(Icons.chevron_right_outlined, color: AppTheme.muted),
    onTap: onTap,
  );
}
