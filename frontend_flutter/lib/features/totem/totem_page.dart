import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_surface.dart';
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
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          'Autoatendimento',
          'Olá, ${widget.controller.displayName}. Escolha o que deseja fazer.',
        ),
        // Kiosk band: availability and the three actions on opaque glass
        // (blur: false — totem hardware is not defined yet).
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.backdropFor(false),
            ),
            borderRadius: AppRadius.panel,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  }
                  final item = snapshot.requireData;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AGORA NO ARMÁRIO',
                              style: textTheme.labelSmall?.copyWith(
                                color: AppTheme.onBrandMuted,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${item.available} tablets disponíveis',
                              style: textTheme.headlineSmall?.copyWith(
                                color: AppTheme.onBrand,
                                fontFeatures: AppTheme.tabularFigures,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              'Total de tablets: ${item.total}',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppTheme.onBrandMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Atualizar disponibilidade',
                        onPressed: _refresh,
                        color: AppTheme.onBrand,
                        icon: const Icon(Icons.refresh_outlined),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns =
                      constraints.maxWidth >= 840 &&
                          MediaQuery.textScalerOf(context).scale(1) <= 1.3
                      ? 3
                      : 1;
                  final width =
                      (constraints.maxWidth - (columns - 1) * AppSpacing.md) /
                      columns;
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
                      Icons.history_outlined,
                      () => context.go('/history'),
                    ),
                  ];
                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      for (final action in actions)
                        SizedBox(width: width, child: action),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Sua segurança'),
              const SizedBox(height: AppSpacing.md),
              const _OperationStep(
                icon: Icons.checklist_outlined,
                title: 'Confira os tablets',
                description: 'A quantidade solicitada pode ser diferente da retirada. Aguarde a confirmação da conferência.',
              ),
              const SizedBox(height: AppSpacing.md),
              const _OperationStep(
                icon: Icons.logout_outlined,
                title: 'Encerre ao terminar',
                description: 'Finalize seu acesso antes de deixar o terminal para o próximo professor.',
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () {
                  final login = widget.controller.badgeUid == null
                      ? '/professor/login'
                      : '/login';
                  widget.controller.signOut();
                  context.go(login);
                },
                icon: const Icon(Icons.logout_outlined),
                label: const Text('Encerrar meu acesso'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Large kiosk action on an opaque glass panel; the primary one carries the
/// profile color so the first step stays obvious.
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
    final accent = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;
    return GlassSurface(
      blur: false,
      borderRadius: AppRadius.card,
      shadows: AppShadows.soft,
      borderColor: primary ? accent : null,
      child: Semantics(
        button: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: AppRadius.card,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 164),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Icon(icon, size: 28, color: accent),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: primary ? accent : AppTheme.text,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        ExcludeSemantics(
                          child: Icon(
                            Icons.arrow_forward_outlined,
                            size: 20,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
    ],
  );
}
