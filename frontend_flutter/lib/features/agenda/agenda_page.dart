import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/display.dart';
import '../../models/system_models.dart';
import '../../services/app_controller.dart';
import '../../widgets/common_widgets.dart';

enum AgendaRange { day, week, month }

class AgendaPage extends StatefulWidget {
  const AgendaPage({required this.controller, super.key});
  final AppController controller;

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  DateTime selectedDate = DateTime.now();
  AgendaRange range = AgendaRange.week;
  String status = '';
  late Future<HistoryResultPage> events;

  @override
  void initState() {
    super.initState();
    events = _load();
  }

  DateTime get _start {
    final date = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    return switch (range) {
      AgendaRange.day => date,
      AgendaRange.week => date.subtract(
        Duration(days: date.weekday - DateTime.monday),
      ),
      AgendaRange.month => DateTime(date.year, date.month),
    };
  }

  DateTime get _end => switch (range) {
    AgendaRange.day => _start.add(const Duration(days: 1)),
    AgendaRange.week => _start.add(const Duration(days: 7)),
    AgendaRange.month => DateTime(_start.year, _start.month + 1),
  };

  Future<HistoryResultPage> _load() => widget.controller.api.history(
    since: _start,
    until: _end.subtract(const Duration(microseconds: 1)),
    status: status.isEmpty ? null : status,
    limit: 100,
  );

  void _reload() => setState(() => events = _load());

  void _step(int direction) {
    final days = switch (range) {
      AgendaRange.day => 1,
      AgendaRange.week => 7,
      AgendaRange.month => 0,
    };
    setState(() {
      selectedDate = days == 0
          ? DateTime(selectedDate.year, selectedDate.month + direction, 1)
          : selectedDate.add(Duration(days: days * direction));
      events = _load();
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PageHeading(
        'Agenda de movimentações',
        'Eventos carregados do histórico persistido na API.',
      ),
      SectionCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              onPressed: () => _step(-1),
              tooltip: 'Período anterior',
              icon: const Icon(Icons.chevron_left_outlined),
            ),
            Text(
              _rangeLabel(),
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontFeatures: AppTheme.tabularFigures),
            ),
            IconButton(
              onPressed: () => _step(1),
              tooltip: 'Próximo período',
              icon: const Icon(Icons.chevron_right_outlined),
            ),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  selectedDate = DateTime.now();
                  events = _load();
                });
              },
              child: const Text('Hoje'),
            ),
            SegmentedButton<AgendaRange>(
              segments: const [
                ButtonSegment(value: AgendaRange.day, label: Text('Dia')),
                ButtonSegment(value: AgendaRange.week, label: Text('Semana')),
                ButtonSegment(value: AgendaRange.month, label: Text('Mês')),
              ],
              selected: {range},
              onSelectionChanged: (selection) => setState(() {
                range = selection.first;
                events = _load();
              }),
            ),
            SizedBox(
              width: 185,
              child: DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Situação'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Todas')),
                  DropdownMenuItem(value: 'OPEN', child: Text('Em andamento')),
                  DropdownMenuItem(
                    value: 'DIVERGENT',
                    child: Text('Divergente'),
                  ),
                  DropdownMenuItem(
                    value: 'COMPLETED',
                    child: Text('Concluída'),
                  ),
                ],
                onChanged: (value) => setState(() {
                  status = value ?? '';
                  events = _load();
                }),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      FutureBuilder<HistoryResultPage>(
        future: events,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error! as ApiException).message
                : 'Não foi possível carregar os eventos.';
            return ErrorPanel(message: message, onRetry: _reload);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snapshot.requireData.rows;
          if (rows.isEmpty) {
            return const SectionCard(
              child: StateMessage(
                message:
                    'Não há registros da API para o período selecionado. '
                    'A API não oferece agendamento futuro.',
                icon: Icons.event_busy_outlined,
              ),
            );
          }
          return SectionCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle('Movimentações do período'),
                const SizedBox(height: AppSpacing.xs),
                for (final row in rows) ...[
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    leading: SizedBox(
                      width: 48,
                      child: Text(
                        formatTime(row.startedAt),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.muted,
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                    ),
                    title: Text(
                      row.professorName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    subtitle: Text(
                      '${row.purpose} · ${row.takenQuantity} tablet(s)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: StatusPill(
                      sessionStatusLabel(row.status),
                      color: sessionStatusColor(row.status),
                    ),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Movimentação #${row.sessionId}'),
                        content: Text(
                          '${row.professorName}\n'
                          '${formatDateTime(row.startedAt)}\n'
                          '${row.purpose}\n'
                          'Tablets retirados: ${row.takenQuantity}\n'
                          'Pendentes: ${row.pendingQuantity}\n'
                          '${sessionStatusLabel(row.status)}',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Fechar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      const SizedBox(height: AppSpacing.sm),
      const Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          StatusPill('Retirada', color: AppTheme.blue),
          StatusPill('Devolução concluída', color: AppTheme.success),
          StatusPill('Divergência', color: AppTheme.warning),
          StatusPill('Operação rejeitada', color: AppTheme.danger),
        ],
      ),
    ],
  );

  String _rangeLabel() {
    final format =
        '${selectedDate.day.toString().padLeft(2, '0')}/'
        '${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
    return switch (range) {
      AgendaRange.day => format,
      AgendaRange.week =>
        'Semana de ${_start.day.toString().padLeft(2, '0')}/'
            '${_start.month.toString().padLeft(2, '0')}/${_start.year}',
      AgendaRange.month =>
        '${_start.month.toString().padLeft(2, '0')}/${_start.year}',
    };
  }
}
