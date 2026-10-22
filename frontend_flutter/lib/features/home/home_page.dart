import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/display.dart';
import '../../models/system_models.dart';
import '../../services/app_controller.dart';
import '../../widgets/common_widgets.dart';
import '../shell/locker_illustration.dart';

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
            padding: EdgeInsets.all(64),
            child: CircularProgressIndicator(),
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: PageHeading(
                  'Olá, ${widget.controller.displayName}',
                  'Resumo dos equipamentos e movimentações recentes.',
                ),
              ),
              IconButton(
                onPressed: _refresh,
                tooltip: 'Atualizar',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          _HeroBanner(
            onAgenda: () => context.go('/agenda'),
            onMovement: () => context.go('/movements'),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1000
                  ? 4
                  : constraints.maxWidth >= 620
                  ? 2
                  : 1;
              return GridView.count(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: columns == 1 ? 4.8 : 2.4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
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
                    AppTheme.buttonBlue,
                  ),
                  const _MetricCard(
                    'Professores',
                    '—',
                    Icons.badge_outlined,
                    AppTheme.warning,
                    footnote: 'Listagem não disponível na API',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final recent = _RecentMovements(data.history.rows);
              final access = _QuickAccess(onTap: (path) => context.go(path));
              if (constraints.maxWidth >= 850) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: recent),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: access),
                  ],
                );
              }
              return Column(
                children: [recent, const SizedBox(height: 16), access],
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

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onAgenda, required this.onMovement});

  final VoidCallback onAgenda;
  final VoidCallback onMovement;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 220),
    decoration: BoxDecoration(
      color: AppTheme.navy,
      borderRadius: BorderRadius.circular(11),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: Stack(
        children: [
          Positioned(
            right: 26,
            top: 8,
            bottom: 8,
            child: Opacity(
              opacity: .52,
              child: SizedBox(
                width: 245,
                child: LockerIllustration(light: true),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(26),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 590),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .13),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ARMÁRIO INTELIGENTE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Gestão inteligente de tablets',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Retiradas e devoluções controladas por identificação RFID.',
                    style: TextStyle(color: Color(0xFFD9E8FA)),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 9,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: onAgenda,
                        child: const Text('Acessar agenda'),
                      ),
                      OutlinedButton(
                        onPressed: onMovement,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                        child: const Text('Registrar movimentação'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
    this.title,
    this.value,
    this.icon,
    this.color, {
    this.footnote,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? footnote;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(color: AppTheme.muted)),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (footnote != null)
                Text(
                  footnote!,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 10),
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
      children: [
        SectionTitle(
          'Próximas movimentações',
          action: TextButton(
            onPressed: () => context.go('/history'),
            child: const Text('Ver histórico'),
          ),
        ),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          const StateMessage(
            message: 'A API não retornou movimentações recentes.',
            icon: Icons.event_note_outlined,
          )
        else
          ...rows
              .take(6)
              .map(
                (row) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: SizedBox(
                    width: 48,
                    child: Text(
                      formatTime(row.startedAt),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Text(
                    row.professorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${row.takenQuantity} tablet(s) · ${row.purpose}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: StatusPill(
                    sessionStatusLabel(row.status),
                    color: sessionStatusColor(row.status),
                  ),
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
        const SectionTitle('Acesso rápido'),
        const SizedBox(height: 12),
        _AccessTile(
          icon: Icons.calendar_month_outlined,
          title: 'Agenda de movimentações',
          action: 'Ver agenda',
          onTap: () => onTap('/agenda'),
        ),
        _AccessTile(
          icon: Icons.contactless,
          title: 'Identificação RFID',
          action: 'Realizar leitura',
          onTap: () => onTap('/teachers'),
        ),
        _AccessTile(
          icon: Icons.tablet_mac_outlined,
          title: 'Controle de tablets',
          action: 'Ver tablets',
          onTap: () => onTap('/tablets'),
        ),
        _AccessTile(
          icon: Icons.receipt_long_outlined,
          title: 'Histórico e relatórios',
          action: 'Ver relatórios',
          onTap: () => onTap('/history'),
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
    title: Text(title, style: const TextStyle(fontSize: 13)),
    trailing: TextButton(onPressed: onTap, child: Text(action)),
  );
}
