import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/display.dart';
import '../../models/system_models.dart';
import '../../services/app_controller.dart';
import '../../widgets/common_widgets.dart';

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
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: PageHeading(
              'Olá, ${widget.controller.displayName}',
              'Retire, devolva e acompanhe seus tablets em um só lugar.',
            ),
          ),
          IconButton(
            tooltip: 'Atualizar meus dados',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.paleBlue,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.tablet_android_outlined,
                            color: AppTheme.blue,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionTitle('Disponíveis agora'),
                              const SizedBox(height: 8),
                              Text(
                                '${result.availability.available}',
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(
                                      color: AppTheme.navy,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              Text(
                                'de ${result.availability.total} tablets cadastrados',
                                style: const TextStyle(color: AppTheme.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      result.availability.available == 0
                          ? 'Nenhum tablet disponível neste momento. Você ainda pode devolver tablets ou consultar seu histórico.'
                          : 'Escolha uma ação para começar. As movimentações são confirmadas após a conferência dos tablets.',
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final withdraw = FilledButton.icon(
                          onPressed: () => context.go('/movements'),
                          icon: const Icon(Icons.output_outlined),
                          label: const Text('Retirar tablets'),
                        );
                        final giveBack = OutlinedButton.icon(
                          onPressed: () => context.go('/returns'),
                          icon: const Icon(Icons.assignment_return_outlined),
                          label: const Text('Devolver tablets'),
                        );
                        if (constraints.maxWidth >= 560) {
                          return Row(
                            children: [
                              Expanded(child: withdraw),
                              const SizedBox(width: 12),
                              Expanded(child: giveBack),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            withdraw,
                            const SizedBox(height: 12),
                            giveBack,
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(
                      'Minhas movimentações recentes',
                      action: TextButton(
                        onPressed: () => context.go('/history'),
                        child: const Text('Ver histórico'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (result.history.rows.isEmpty)
                      const StateMessage(
                        message: 'Você ainda não tem movimentações registradas.\nSua próxima retirada aparecerá aqui.',
                        icon: Icons.history_outlined,
                      )
                    else
                      for (
                        var index = 0;
                        index < result.history.rows.length;
                        index++
                      ) ...[
                        _PersonalMovement(result.history.rows[index]),
                        if (index < result.history.rows.length - 1)
                          const Divider(height: 24),
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

class _PersonalMovement extends StatelessWidget {
  const _PersonalMovement(this.row);

  final HistoryRow row;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.tablet_android_outlined, color: AppTheme.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.purpose,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                formatDateTime(row.startedAt),
                style: const TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 10),
              StatusPill(
                sessionStatusLabel(row.status),
                color: sessionStatusColor(row.status),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
