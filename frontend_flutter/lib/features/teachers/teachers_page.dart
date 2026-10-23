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
  String? error;

  @override
  void dispose() {
    badgeController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    if (loading) return;
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
                  onPressed: loading ? null : _lookup,
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
              'A API atual oferece apenas consulta por crachá. Ela não disponibiliza '
              'listagem geral, pesquisa por nome ou matrícula, cadastro ou edição de professores.',
          icon: Icons.info_outline,
        ),
      ),
    ],
  );
}
