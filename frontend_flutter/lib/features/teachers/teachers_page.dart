import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/system_models.dart';
import '../../services/app_controller.dart';
import '../../widgets/common_widgets.dart';

class TeachersPage extends StatefulWidget {
  const TeachersPage({required this.controller, super.key});
  final AppController controller;

  @override
  State<TeachersPage> createState() => _TeachersPageState();
}

class _TeachersPageState extends State<TeachersPage> {
  final badgeController = TextEditingController();
  Professor? professor;
  bool loading = false;
  bool syncing = false;
  String? syncMessage;
  String? error;

  @override
  void dispose() {
    badgeController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    if (loading || syncing) return;
    setState(() {
      loading = true;
      error = null;
      professor = null;
    });
    try {
      professor = await widget.controller.api.identifyBadge(
        badgeController.text,
      );
    } on ApiException catch (exception) {
      error = exception.message;
    } on FormatException catch (exception) {
      error = exception.message;
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _syncProfessors() async {
    if (syncing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sincronizar professores?'),
        content: const Text(
          'Os cadastros e a situação ativo/inativo serão atualizados conforme a planilha. O histórico será preservado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sincronizar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      syncing = true;
      syncMessage = null;
      error = null;
      professor = null;
    });
    try {
      final result = await widget.controller.api.syncProfessors();
      if (mounted) {
        setState(
          () => syncMessage =
              '${result.created} criados, ${result.updated} atualizados e ${result.unchanged} sem alteração.',
        );
      }
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } on FormatException {
      if (mounted) {
        setState(() => error = 'Resposta de sincronização inválida.');
      }
    } finally {
      if (mounted) setState(() => syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PageHeading(
        'Professores',
        'Consulta individual por crachá RFID cadastrado.',
      ),
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Cadastro pela planilha'),
            const SizedBox(height: 8),
            const Text(
              'Importe os professores autorizados e mantenha seus cadastros atualizados.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: syncing || loading ? null : _syncProfessors,
              icon: const Icon(Icons.sync),
              label: Text(
                syncing ? 'Sincronizando…' : 'Sincronizar professores',
              ),
            ),
            if (syncMessage != null) Text(syncMessage!),
          ],
        ),
      ),
      const SizedBox(height: 16),
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Localizar cadastro'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: badgeController,
                    onSubmitted: (_) => _lookup(),
                    decoration: const InputDecoration(
                      labelText: 'UID do crachá',
                      prefixIcon: Icon(Icons.contactless),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: loading || syncing ? null : _lookup,
                  child: Text(loading ? 'Consultando…' : 'Consultar'),
                ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: const TextStyle(color: AppTheme.danger)),
            ],
            if (professor != null) ...[
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.paleBlue,
                  child: Icon(Icons.person_outline, color: AppTheme.blue),
                ),
                title: Text(professor!.name),
                subtitle: Text(
                  'Matrícula ${professor!.registration} · '
                  'Cadastro ${professor!.active ? 'ativo' : 'inativo'}',
                ),
                trailing: const StatusPill(
                  'Identificado pela API',
                  color: AppTheme.success,
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      const SectionCard(
        child: StateMessage(
          message:
              'Os cadastros podem ser sincronizados pela planilha e consultados por crachá. '
              'Listagem geral e edição direta ainda não estão disponíveis nesta tela.',
          icon: Icons.info_outline,
        ),
      ),
    ],
  );
}
