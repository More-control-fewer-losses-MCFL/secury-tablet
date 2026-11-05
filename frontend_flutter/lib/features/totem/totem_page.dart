import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/system_models.dart';
import '../../services/app_controller.dart';
import '../../widgets/common_widgets.dart';

/// O RFID e a autorização do terminal são realizados pela página de login.
/// Esta tela não simula leituras nem aciona a fechadura por conta própria.
class TotemPage extends StatefulWidget {
  const TotemPage({required this.controller, super.key});
  final AppController controller;

  @override
  State<TotemPage> createState() => _TotemPageState();
}

class _TotemPageState extends State<TotemPage> {
  late Future<Availability> availability;

  @override
  void initState() {
    super.initState();
    availability = widget.controller.api.availability();
  }

  void _refresh() =>
      setState(() => availability = widget.controller.api.availability());

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      PageHeading(
        'Autoatendimento',
        'Professor: ${widget.controller.displayName}. Sessão RFID e terminal autorizado.',
      ),
      FutureBuilder<Availability>(
        future: availability,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorPanel(
              message: 'Não foi possível consultar a disponibilidade.',
              onRetry: _refresh,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = snapshot.requireData;
          return SectionCard(
            child: Row(
              children: [
                const Icon(
                  Icons.tablet_android_outlined,
                  size: 42,
                  color: AppTheme.blue,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.available} tablets disponíveis',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Total de tablets: ${item.total}',
                        style: const TextStyle(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Atualizar disponibilidade',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 18),
      LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 680;
          final actions = [
            _TotemAction(
              'Solicitar retirada',
              Icons.output_outlined,
              () => context.go('/movements'),
            ),
            _TotemAction(
              'Registrar devolução',
              Icons.assignment_return_outlined,
              () => context.go('/returns'),
            ),
            _TotemAction(
              'Meu histórico',
              Icons.history,
              () => context.go('/history'),
            ),
          ];
          return wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final action in actions)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: action,
                        ),
                      ),
                  ],
                )
              : Column(
                  children: [
                    for (final action in actions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: action,
                      ),
                  ],
                );
        },
      ),
      const SizedBox(height: 18),
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sua segurança',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'A operação é confirmada somente após leitura do inventário físico ou simulado pelo backend.',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                widget.controller.signOut();
                context.go('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Encerrar meu acesso'),
            ),
          ],
        ),
      ),
    ],
  );
}

class _TotemAction extends StatelessWidget {
  const _TotemAction(this.label, this.icon, this.onPressed);
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 132,
    child: FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 34),
      label: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
