import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/display.dart';
import '../../models/system_models.dart';
import '../../services/app_controller.dart';
import '../../widgets/common_widgets.dart';

/// Self-service landing page; the server only returns this teacher's history.
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
      PageHeading(
        'Olá, ${widget.controller.displayName}',
        'Seu painel de retiradas e devoluções de tablets.',
      ),
      const SizedBox(height: 16),
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
                    const SectionTitle('Disponíveis agora'),
                    const SizedBox(height: 8),
                    Text(
                      '${result.availability.available} de ${result.availability.total} tablets',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.go('/movements'),
                          icon: const Icon(Icons.output_outlined),
                          label: const Text('Retirar tablets'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.go('/returns'),
                          icon: const Icon(Icons.assignment_return_outlined),
                          label: const Text('Devolver tablets'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                    if (result.history.rows.isEmpty)
                      const StateMessage(
                        message:
                            'Você ainda não tem movimentações registradas.',
                        icon: Icons.receipt_long_outlined,
                      )
                    else
                      ...result.history.rows.map(
                        (row) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.history,
                            color: AppTheme.blue,
                          ),
                          title: Text(row.purpose),
                          subtitle: Text(formatDateTime(row.startedAt)),
                          trailing: Text(sessionStatusLabel(row.status)),
                        ),
                      ),
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
