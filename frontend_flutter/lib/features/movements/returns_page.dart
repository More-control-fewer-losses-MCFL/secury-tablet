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
          'A API solicitará a leitura do inventário ao leitor RFID configurado. '
          'Nenhuma etiqueta será simulada pelo navegador.',
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
        'Solicitações em aberto carregadas do histórico da API.',
      ),
      if (error != null) ...[
        Text(error!, style: const TextStyle(color: AppTheme.danger)),
        const SizedBox(height: 12),
      ],
      if (result != null) ...[
        SectionCard(
          child: StateMessage(
            message:
                result!.divergence ??
                'Conciliação confirmada pela API: ${result!.status}.',
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
                    tooltip: 'Atualizar',
                    icon: const Icon(Icons.refresh),
                  ),
                ),
                const Divider(height: 24),
                ...rows.map(
                  (row) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.assignment_return_outlined,
                      color: AppTheme.blue,
                    ),
                    title: Text(row.professorName),
                    subtitle: Text(
                      'Solicitação #${row.sessionId} · '
                      'Retirados ${row.takenQuantity} · Pendentes ${row.pendingQuantity}\n'
                      '${formatDateTime(row.startedAt)} · ${row.purpose}',
                    ),
                    isThreeLine: true,
                    trailing: FilledButton(
                      onPressed: submitting ? null : () => _reconcile(row),
                      child: const Text('Ler devolução'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 14),
      const SectionCard(
        child: StateMessage(
          message:
              'A rota de devolução depende do leitor de inventário configurado no backend. '
              'Se o hardware não estiver disponível, a API rejeitará a operação; o app não marcará a devolução como concluída.',
          icon: Icons.info_outline,
        ),
      ),
    ],
  );
}
