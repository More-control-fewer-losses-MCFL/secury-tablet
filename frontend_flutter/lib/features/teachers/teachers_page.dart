import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/system_models.dart';
import '../../services/app_controller.dart';
import '../../widgets/common_widgets.dart';
import 'professor_credentials_dialog.dart';

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
        'Consulte o cadastro por crachá e mantenha os acessos atualizados.',
      ),
      if (error != null) ...[
        Semantics(
          liveRegion: true,
          child: SectionCard(
            child: Text(error!, style: const TextStyle(color: AppTheme.danger)),
          ),
        ),
        const SizedBox(height: 20),
      ],
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Localizar cadastro'),
            const SizedBox(height: 8),
            const Text(
              'Leia o crachá ou informe o UID para consultar o professor.',
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final field = TextField(
                  controller: badgeController,
                  enabled: !loading && !syncing,
                  autocorrect: false,
                  enableSuggestions: false,
                  onSubmitted: (_) => _lookup(),
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    labelText: 'UID do crachá',
                    prefixIcon: Icon(Icons.contactless),
                  ),
                );
                final button = FilledButton.icon(
                  onPressed: loading || syncing ? null : _lookup,
                  icon: const Icon(Icons.search),
                  label: Text(loading ? 'Consultando…' : 'Consultar'),
                );
                final stack =
                    constraints.maxWidth < 560 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.25;
                return stack
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [field, const SizedBox(height: 12), button],
                      )
                    : Row(
                        children: [
                          Expanded(child: field),
                          const SizedBox(width: 12),
                          button,
                        ],
                      );
              },
            ),
            if (professor != null) ...[
              const Divider(height: 36),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: AppTheme.paleBlue,
                    child: Icon(Icons.person_outline, color: AppTheme.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          professor!.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text('Matrícula ${professor!.registration}'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StatusPill(
                professor!.active ? 'Cadastro ativo' : 'Cadastro inativo',
                color: professor!.active ? AppTheme.success : AppTheme.warning,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: loading || syncing
                    ? null
                    : () async {
                        final value = await showDialog<String>(
                          context: context,
                          builder: (context) => ProfessorCredentialsDialog(
                            professor: professor!,
                            api: widget.controller.api,
                          ),
                        );
                        if (value != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Acesso do professor salvo: $value',
                              ),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.manage_accounts_outlined),
                label: const Text('Configurar usuário e senha'),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 20),
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Cadastro pela planilha'),
            const SizedBox(height: 8),
            const Text(
              'Atualize os professores autorizados a partir da planilha de cadastros. O histórico de empréstimos será preservado.',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: syncing || loading ? null : _syncProfessors,
                icon: const Icon(Icons.sync),
                label: Text(
                  syncing ? 'Sincronizando…' : 'Sincronizar professores',
                ),
              ),
            ),
            if (syncMessage != null) ...[
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: Text(
                  syncMessage!,
                  style: const TextStyle(color: AppTheme.success),
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      const StateMessage(
        message: 'A consulta é individual. Listagem geral e edição direta ainda não estão disponíveis.',
        icon: Icons.info_outline,
      ),
    ],
  );
}
