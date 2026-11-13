import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/system_models.dart';
import '../../services/system_api.dart';

class ProfessorCredentialsDialog extends StatefulWidget {
  const ProfessorCredentialsDialog({
    required this.professor,
    required this.api,
    super.key,
  });
  final Professor professor;
  final SystemApi api;

  @override
  State<ProfessorCredentialsDialog> createState() =>
      _ProfessorCredentialsDialogState();
}

class _ProfessorCredentialsDialogState
    extends State<ProfessorCredentialsDialog> {
  final username = TextEditingController();
  final password = TextEditingController();
  bool saving = false;
  bool visible = false;
  String? error;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (saving) return;
    if (username.text.trim().isEmpty || password.text.length < 12) {
      setState(
        () => error =
            'Informe um usuário e uma senha com pelo menos 12 caracteres.',
      );
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final value = await widget.api.setProfessorCredentials(
        professorId: widget.professor.id,
        username: username.text,
        password: password.text,
      );
      password.clear();
      if (mounted) Navigator.of(context).pop(value);
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } on FormatException {
      if (mounted) {
        setState(() => error = 'Não foi possível confirmar o novo acesso.');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Acesso do professor'),
    content: SizedBox(
      width: 400,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.professor.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Ao salvar, o acesso por senha anterior será substituído e suas sessões serão encerradas.',
            ),
            const SizedBox(height: 24),
            TextField(
              key: const Key('professor-credential-username'),
              controller: username,
              enabled: !saving,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Usuário do professor',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              key: const Key('professor-credential-password'),
              controller: password,
              enabled: !saving,
              obscureText: !visible,
              enableSuggestions: false,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: 'Nova senha',
                helperText: 'Mínimo de 12 caracteres.',
                suffixIcon: IconButton(
                  tooltip: visible ? 'Ocultar senha' : 'Mostrar senha',
                  onPressed: saving
                      ? null
                      : () => setState(() => visible = !visible),
                  icon: Icon(
                    visible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: Text(
                  error!,
                  style: const TextStyle(color: AppTheme.danger),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: saving ? null : _save,
        child: Text(saving ? 'Salvando…' : 'Salvar acesso'),
      ),
    ],
  );
}
