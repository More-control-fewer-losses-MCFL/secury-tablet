import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/display.dart';
import '../../models/system_models.dart';
import '../../services/app_controller.dart';
import '../../widgets/common_widgets.dart';
import 'portal_welcome.dart';

/// Personal self-service overview. Ownership remains enforced by the API.
class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({required this.controller, super.key});
  final AppController controller;

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  late Future<({Availability availability, HistoryResultPage history})> data;

  @override
  void initState() {
    super.initState();
    data = _load();
  }

  Future<({Availability availability, HistoryResultPage history})>
  _load() async {
    final result = await Future.wait<Object>([
      widget.controller.api.availability(),
      widget.controller.api.history(limit: 5),
    ]);
    return (
      availability: result[0] as Availability,
      history: result[1] as HistoryResultPage,
    );
  }

  void _refresh() => setState(() => data = _load());

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FutureBuilder<({Availability availability, HistoryResultPage history})>(
        future: data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error! as ApiException).message
                : 'Não foi possível carregar seus dados.';
            return ErrorPanel(message: message, onRetry: _refresh);
          }
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(36),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final result = snapshot.requireData;
          final rows = result.history.rows;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PortalWelcome(
                controller: widget.controller,
                summary: '${result.availability.available} tablets disponíveis',
                detail: rows.isEmpty
                    ? 'Seu próximo registro de retirada ou devolução aparecerá aqui.'
                    : 'Última movimentação: ${formatDateTime(rows.first.startedAt)}. '
                          'Consulte seu histórico para acompanhar os detalhes e as pendências.',
                onRefresh: _refresh,
                shortcuts: const [
                  PortalShortcut(
                    'Iniciar retirada',
                    Icons.output_outlined,
                    '/movements',
                  ),
                  PortalShortcut(
                    'Registrar devolução',
                    Icons.assignment_return_outlined,
                    '/returns',
                  ),
                  PortalShortcut(
                    'Consultar histórico',
                    Icons.history_outlined,
                    '/history',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _AvailabilityFocus(availability: result.availability),
              const SizedBox(height: AppSpacing.lg),
              SectionCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionTitle(
                      'Minhas movimentações recentes',
                      action: TextButton(
                        onPressed: () => context.go('/history'),
                        child: const Text('Ver histórico'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (rows.isEmpty)
                      const StateMessage(
                        message: 'Você ainda não tem movimentações registradas.\nSua próxima retirada aparecerá aqui.',
                        icon: Icons.history_outlined,
                      )
                    else
                      for (var index = 0; index < rows.length; index++) ...[
                        if (index > 0) const Divider(height: 1),
                        _PersonalMovement(rows[index]),
                      ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ],
  );
}

/// Focus card: available balance and the two primary actions.
class _AvailabilityFocus extends StatelessWidget {
  const _AvailabilityFocus({required this.availability});

  final Availability availability;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SectionCard(
      accent: scheme.primary,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final balance = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Disponíveis agora'),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  Text(
                    '${availability.available}',
                    style: textTheme.displaySmall?.copyWith(
                      fontSize: 64,
                      height: 1,
                      color: AppTheme.navy,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      'de ${availability.total} tablets cadastrados',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppTheme.muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                availability.available == 0
                    ? 'Nenhum tablet disponível neste momento. Você ainda pode devolver tablets ou consultar seu histórico.'
                    : 'Escolha uma ação para começar. As movimentações são confirmadas após a conferência dos tablets.',
                style: textTheme.bodyMedium,
              ),
            ],
          );
          final actions = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(48, 56)),
                onPressed: () => context.go('/movements'),
                icon: const Icon(Icons.output_outlined),
                label: const Text('Retirar tablets'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 56),
                ),
                onPressed: () => context.go('/returns'),
                icon: const Icon(Icons.assignment_return_outlined),
                label: const Text('Devolver tablets'),
              ),
            ],
          );
          if (constraints.maxWidth >= 720 &&
              MediaQuery.textScalerOf(context).scale(1) <= 1.3) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: balance),
                const SizedBox(width: AppSpacing.xl),
                SizedBox(width: 320, child: actions),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              balance,
              const SizedBox(height: AppSpacing.lg),
              actions,
            ],
          );
        },
      ),
    );
  }
}

/// List row for the professor's own history.
class _PersonalMovement extends StatelessWidget {
  const _PersonalMovement(this.row);

  final HistoryRow row;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
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
              Text(row.purpose, style: textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                formatDateTime(row.startedAt),
                style: textTheme.bodySmall?.copyWith(
                  fontFeatures: AppTheme.tabularFigures,
                ),
              ),
            ],
          ),
          StatusPill(
            sessionStatusLabel(row.status),
            color: sessionStatusColor(row.status),
          ),
        ],
      ),
    );
  }
}
