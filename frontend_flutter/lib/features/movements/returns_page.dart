import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/display.dart';
import '../../models/system_models.dart';
import '../../services/app_controller.dart';
import '../../widgets/common_widgets.dart';

class ReturnsPage extends StatefulWidget {
  const ReturnsPage({required this.controller, super.key});
  final AppController controller;

  @override
  State<ReturnsPage> createState() => _ReturnsPageState();
}

class _ReturnsPageState extends State<ReturnsPage> {
  late Future<List<HistoryRow>> sessions;
  bool submitting = false;
  String? error;
  CheckoutResult? result;
  final Set<int> reconciling = {};

  @override
  void initState() {
    super.initState();
    sessions = _load();
  }

  Future<List<HistoryRow>> _load() async {
    final pages = await Future.wait([
      widget.controller.api.history(status: 'OPEN', limit: 100),
      widget.controller.api.history(status: 'DIVERGENT', limit: 100),
    ]);
    final combined = <int, HistoryRow>{};
    for (final page in pages) {
      for (final row in page.rows) {
        combined[row.sessionId] = row;
      }
    }
    final rows = combined.values.toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return rows;
  }

  void _reload() => setState(() {
    error = null;
    sessions = _load();
  });

  Future<void> _reconcile(HistoryRow row) async {
    if (submitting || reconciling.contains(row.sessionId)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar devolução #${row.sessionId}'),
        content: const Text(
          'Os tablets devolvidos serão conferidos pelo inventário. '
          'Itens não identificados continuarão pendentes nesta solicitação.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ler inventário e conciliar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      submitting = true;
      reconciling.add(row.sessionId);
      error = null;
      result = null;
    });
    try {
      result = await widget.controller.api.reconcileReturn(
        sessionId: row.sessionId,
        eventId: 'flutter-web-${DateTime.now().toUtc().microsecondsSinceEpoch}',
      );
      sessions = _load();
    } on ApiException catch (exception) {
      error = exception.message;
    } on FormatException catch (exception) {
      error = exception.message;
    } finally {
      if (mounted) {
        setState(() {
          submitting = false;
          reconciling.remove(row.sessionId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      PageHeading(
        'Registrar devolução',
        widget.controller.isAdmin
            ? 'Acompanhe as solicitações pendentes e registre os tablets devolvidos.'
            : 'Confira suas solicitações pendentes e registre os tablets devolvidos.',
      ),
      if (error != null) ...[
        InlineNotice(message: error!),
        const SizedBox(height: AppSpacing.md),
      ],
      if (result != null) ...[
        InlineNotice(
          message:
              result!.divergence ??
              'Devolução registrada: ${sessionStatusLabel(result!.status)}.',
          icon: result!.divergence == null
              ? Icons.check_circle_outline
              : Icons.warning_amber_outlined,
          color: result!.divergence == null
              ? AppTheme.success
              : AppTheme.warning,
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      FutureBuilder<List<HistoryRow>>(
        future: sessions,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error! as ApiException).message
                : 'Não foi possível consultar solicitações em aberto.';
            return ErrorPanel(message: message, onRetry: _reload);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snapshot.requireData;
          if (rows.isEmpty) {
            return const SectionCard(
              child: StateMessage(
                message: 'Não há tablets pendentes de devolução.',
                icon: Icons.task_alt_outlined,
                color: AppTheme.success,
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle(
                'Pendentes (${rows.length})',
                action: IconButton(
                  onPressed: _reload,
                  tooltip: 'Atualizar devoluções',
                  icon: const Icon(Icons.refresh_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns =
                      constraints.maxWidth >= 900 &&
                          MediaQuery.textScalerOf(context).scale(1) <= 1.3
                      ? 2
                      : 1;
                  final width =
                      (constraints.maxWidth - AppSpacing.md * (columns - 1)) /
                      columns;
                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      for (final row in rows)
                        SizedBox(
                          width: width,
                          child: _pendingSession(context, row),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
      const SizedBox(height: AppSpacing.lg),
      const HintNote(
        'Somente os tablets identificados na conferência são registrados como devolvidos. '
        'Se houver itens faltando ou falha na leitura, as pendências serão preservadas.',
      ),
    ],
  );

  /// Action card: one pending request, its counters and its own action.
  Widget _pendingSession(BuildContext context, HistoryRow row) {
    final textTheme = Theme.of(context).textTheme;
    return SectionCard(
      // Strip reserved on every card so a grid row stays aligned; the
      // status pill below repeats the meaning in text.
      accent: row.status == 'DIVERGENT' ? AppTheme.warning : Colors.transparent,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(row.professorName, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Solicitação #${row.sessionId} · ${formatDateTime(row.startedAt)}',
            style: textTheme.bodySmall?.copyWith(
              fontFeatures: AppTheme.tabularFigures,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(row.purpose),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusPill(
                sessionStatusLabel(row.status),
                color: sessionStatusColor(row.status),
              ),
              StatusPill(
                '${row.pendingQuantity} pendentes',
                color: AppTheme.warning,
              ),
              Text(
                '${row.takenQuantity} retirados',
                style: textTheme.bodySmall?.copyWith(
                  fontFeatures: AppTheme.tabularFigures,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: submitting ? null : () => _reconcile(row),
            icon: reconciling.contains(row.sessionId)
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.assignment_return_outlined),
            label: Text(
              reconciling.contains(row.sessionId)
                  ? 'Conferindo devolução…'
                  : 'Ler devolução',
            ),
          ),
        ],
      ),
    );
  }
}
