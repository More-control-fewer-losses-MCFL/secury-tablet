import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/display.dart';
import '../../core/utils/csv_download.dart';
import '../../models/system_models.dart';
import '../../services/app_controller.dart';
import '../../widgets/common_widgets.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({required this.controller, super.key});
  final AppController controller;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  static const pageSize = 20;
  String status = '';
  DateTime? since;
  DateTime? until;
  int? professorId;
  int offset = 0;
  late Future<HistoryResultPage> page;

  @override
  void initState() {
    super.initState();
    page = _load();
  }

  Future<HistoryResultPage> _load() => widget.controller.api.history(
    status: status.isEmpty ? null : status,
    since: since,
    until: until,
    professorId: professorId,
    limit: pageSize,
    offset: offset,
  );

  void _refresh() => setState(() => page = _load());

  Future<void> _selectDates() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: since == null || until == null
          ? null
          : DateTimeRange(start: since!, end: until!),
    );
    if (range == null) return;
    setState(() {
      since = DateTime(range.start.year, range.start.month, range.start.day);
      until = DateTime(
        range.end.year,
        range.end.month,
        range.end.day,
        23,
        59,
        59,
      );
      offset = 0;
      page = _load();
    });
  }

  List<HistoryRow> _filteredRows(List<HistoryRow> rows) {
    final query = widget.controller.searchQuery.trim().toLowerCase();
    if (query.isEmpty) return rows;
    return rows
        .where((row) {
          return row.professorName.toLowerCase().contains(query) ||
              row.registration.toLowerCase().contains(query) ||
              row.purpose.toLowerCase().contains(query) ||
              '${row.sessionId}'.contains(query);
        })
        .toList(growable: false);
  }

  void _downloadCsv(List<HistoryRow> rows) {
    final lines = <List<String>>[
      [
        'Solicitação',
        'Data e horário',
        'Professor',
        'Matrícula',
        'Operação',
        'Tablets retirados',
        'Pendentes',
        'Finalidade',
        'Situação',
      ],
      ...rows.map(
        (row) => [
          '${row.sessionId}',
          formatDateTime(row.startedAt),
          row.professorName,
          row.registration,
          'Retirada/devolução',
          '${row.takenQuantity}',
          '${row.pendingQuantity}',
          row.purpose,
          sessionStatusLabel(row.status),
        ],
      ),
    ];
    final csv = lines.map((line) => line.map(_csvCell).join(';')).join('\r\n');
    downloadCsv('\uFEFF$csv', 'historico_movimentacoes.csv');
  }

  String _csvCell(String value) => '"${value.replaceAll('"', '""')}"';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      PageHeading(
        'Histórico e relatórios',
        widget.controller.searchQuery.isEmpty
            ? 'Consulte as movimentações persistidas pela API.'
            : 'Resultados locais da página atual para “${widget.controller.searchQuery}”.',
      ),
      // Filter bar.
      Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 210,
            child: DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Situação'),
              items: const [
                DropdownMenuItem(value: '', child: Text('Todas')),
                DropdownMenuItem(value: 'OPEN', child: Text('Em andamento')),
                DropdownMenuItem(value: 'DIVERGENT', child: Text('Divergente')),
                DropdownMenuItem(value: 'COMPLETED', child: Text('Concluída')),
                DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelada')),
                DropdownMenuItem(value: 'FAILED', child: Text('Falhou')),
              ],
              onChanged: (value) => setState(() {
                status = value ?? '';
                offset = 0;
                page = _load();
              }),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _selectDates,
            style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
            icon: const Icon(Icons.date_range_outlined),
            label: Text(
              since == null
                  ? 'Filtrar período'
                  : '${formatDateTime(since!).substring(0, 10)} — '
                        '${formatDateTime(until!).substring(0, 10)}',
            ),
          ),
          TextButton.icon(
            onPressed: () => setState(() {
              since = null;
              until = null;
              offset = 0;
              page = _load();
            }),
            icon: const Icon(Icons.close_outlined),
            label: const Text('Limpar'),
          ),
          IconButton(
            onPressed: _refresh,
            tooltip: 'Atualizar',
            color: AppTheme.muted,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      FutureBuilder<HistoryResultPage>(
        future: page,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error! as ApiException).message
                : 'Não foi possível carregar o histórico.';
            return ErrorPanel(message: message, onRetry: _refresh);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.requireData;
          final rows = _filteredRows(data.rows);
          return SectionCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionTitle(
                  '${data.total} registro(s)',
                  action: Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      OutlinedButton.icon(
                        onPressed: rows.isEmpty
                            ? null
                            : () => _downloadCsv(rows),
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Exportar CSV'),
                      ),
                      TextButton(
                        onPressed: offset == 0
                            ? null
                            : () => setState(() {
                                offset = (offset - pageSize).clamp(
                                  0,
                                  data.total,
                                );
                                page = _load();
                              }),
                        child: const Text('Anterior'),
                      ),
                      TextButton(
                        onPressed: offset + pageSize >= data.total
                            ? null
                            : () => setState(() {
                                offset += pageSize;
                                page = _load();
                              }),
                        child: const Text('Próxima'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (rows.isEmpty)
                  const StateMessage(
                    message: 'Nenhum registro encontrado para os filtros.',
                    icon: Icons.search_off_outlined,
                  )
                else
                  for (var index = 0; index < rows.length; index++) ...[
                    const Divider(height: 1),
                    _HistoryTile(
                      row: rows[index],
                      showDetails: () => _showDetails(context, rows[index]),
                    ),
                  ],
              ],
            ),
          );
        },
      ),
    ],
  );

  void _showDetails(BuildContext context, HistoryRow row) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Movimentação #${row.sessionId}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Professor: ${row.professorName}'),
            Text('Matrícula: ${row.registration}'),
            Text('Início: ${formatDateTime(row.startedAt)}'),
            Text('Finalidade: ${row.purpose}'),
            Text('Solicitados: ${row.requestedQuantity}'),
            Text('Retirados: ${row.takenQuantity}'),
            Text('Pendentes: ${row.pendingQuantity}'),
            Text('Situação: ${sessionStatusLabel(row.status)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

/// List row: request number, who, when and status.
class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.row, required this.showDetails});

  final HistoryRow row;
  final VoidCallback showDetails;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pill = StatusPill(
      sessionStatusLabel(row.status),
      color: sessionStatusColor(row.status),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // Narrow rows put the status below the text instead of squeezing it.
        final stacked =
            constraints.maxWidth < 520 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
        return InkWell(
          onTap: showDetails,
          borderRadius: AppRadius.control,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: stacked
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      '#${row.sessionId}',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppTheme.muted,
                        fontFeatures: AppTheme.tabularFigures,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row.professorName, style: textTheme.titleSmall),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${formatDateTime(row.startedAt)} · ${row.takenQuantity} tablet(s) · ${row.purpose}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall,
                        ),
                        if (stacked) ...[
                          const SizedBox(height: AppSpacing.xs),
                          pill,
                        ],
                      ],
                    ),
                  ),
                  if (!stacked) ...[const SizedBox(width: AppSpacing.md), pill],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
