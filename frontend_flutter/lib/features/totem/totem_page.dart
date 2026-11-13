import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/system_models.dart';
import '../../services/app_controller.dart';
import '../../widgets/common_widgets.dart';

/// Actions keep using the existing authenticated operational flows.
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
        'Olá, ${widget.controller.displayName}. Escolha o que deseja fazer.',
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
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = snapshot.requireData;
          return SectionCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.tablet_android_outlined,
                    size: 28,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.available} tablets disponíveis',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
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
      const SizedBox(height: 24),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 840 ? 3 : 1;
          final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
          final actions = [
            _TotemAction(
              'Solicitar retirada',
              'Escolha a quantidade e a finalidade dos tablets.',
              Icons.output_outlined,
              () => context.go('/movements'),
              primary: true,
            ),
            _TotemAction(
              'Registrar devolução',
              'Localize sua retirada e devolva os tablets.',
              Icons.assignment_return_outlined,
              () => context.go('/returns'),
            ),
            _TotemAction(
              'Meu histórico',
              'Consulte suas movimentações e pendências.',
              Icons.history,
              () => context.go('/history'),
            ),
          ];
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final action in actions)
                SizedBox(width: width, child: action),
            ],
          );
        },
      ),
      const SizedBox(height: 24),
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Sua segurança'),
            const SizedBox(height: 16),
            const _OperationStep(
              icon: Icons.checklist_outlined,
              title: 'Confira os tablets',
              description: 'A quantidade solicitada pode ser diferente da retirada. Aguarde a confirmação da conferência.',
            ),
            const SizedBox(height: 16),
            const _OperationStep(
              icon: Icons.logout,
              title: 'Encerre ao terminar',
              description: 'Finalize seu acesso antes de deixar o terminal para o próximo professor.',
            ),
            const SizedBox(height: 20),
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
  const _TotemAction(
    this.label,
    this.description,
    this.icon,
    this.onPressed, {
    this.primary = false,
  });
  final String label;
  final String description;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: Icon(icon, size: 30)),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const ExcludeSemantics(
                child: Icon(Icons.arrow_forward, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: primary ? Colors.white : AppTheme.muted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 164),
      child: primary
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(20),
              ),
              child: content,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(20),
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppTheme.border),
              ),
              child: content,
            ),
    );
  }
}

class _OperationStep extends StatelessWidget {
  const _OperationStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ExcludeSemantics(
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(color: AppTheme.muted)),
          ],
        ),
      ),
    ],
  );
}
