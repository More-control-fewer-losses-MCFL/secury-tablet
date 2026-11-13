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
        Semantics(
          liveRegion: true,
          child: Text(error!, style: const TextStyle(color: AppTheme.danger)),
        ),
        const SizedBox(height: 12),
      ],
      if (result != null) ...[
        SectionCard(
          child: StateMessage(
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
        ),
        const SizedBox(height: 12),
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
                icon: Icons.task_alt,
                color: AppTheme.success,
              ),
            );
          }
          return SectionCard(
            child: Column(
              children: [
                SectionTitle(
                  'Pendentes (${rows.length})',
                  action: IconButton(
                    onPressed: _reload,
                    tooltip: 'Atualizar devoluções',
                    icon: const Icon(Icons.refresh),
                  ),
                ),
                const Divider(height: 24),
                for (final row in rows) _pendingSession(context, row),
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 14),
      const SectionCard(
        child: StateMessage(
          message:
              'Somente os tablets identificados na conferência são registrados como devolvidos. '
              'Se houver itens faltando ou falha na leitura, as pendências serão preservadas.',
          icon: Icons.info_outline,
        ),
      ),
    ],
  );

  Widget _pendingSession(BuildContext context, HistoryRow row) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.assignment_return_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.professorName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Solicitação #${row.sessionId} · ${formatDateTime(row.startedAt)}',
                        style: const TextStyle(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(row.purpose),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusPill(
                  '${row.pendingQuantity} pendentes',
                  color: AppTheme.warning,
                ),
                Text('${row.takenQuantity} retirados'),
              ],
            ),
            const SizedBox(height: 16),
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
      ),
    ),
  );
}
