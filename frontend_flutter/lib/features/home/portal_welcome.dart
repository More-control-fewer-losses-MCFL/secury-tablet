import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_surface.dart';
import '../../services/app_controller.dart';

class PortalShortcut {
  const PortalShortcut(this.label, this.icon, this.path);
  final String label;
  final IconData icon;
  final String path;
}

/// Presentation of the authenticated profile; permissions remain in the API.
///
/// Compact highlight band: identity and shortcuts on the profile gradient,
/// cabinet summary on glass. Page metrics stay the main focus below it.
class PortalWelcome extends StatelessWidget {
  const PortalWelcome({
    required this.controller,
    required this.summary,
    required this.detail,
    required this.shortcuts,
    required this.onRefresh,
    super.key,
  });

  final AppController controller;
  final String summary;
  final String detail;
  final List<PortalShortcut> shortcuts;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final admin = controller.isAdmin;
    final textTheme = Theme.of(context).textTheme;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Container(
      key: const Key('portal-welcome'),
      padding: EdgeInsets.all(narrow ? AppSpacing.lg : AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.backdropFor(admin),
        ),
        borderRadius: AppRadius.panel,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Narrow screens drop the overview card: its numbers are repeated
          // right below (metrics / balance), so the band stays short.
          final compact = constraints.maxWidth < 600;
          final refreshTooltip = admin
              ? 'Atualizar painel'
              : 'Atualizar meus dados';
          final eyebrow = Text(
            admin
                ? 'SECURY TABLET / ADMINISTRAÇÃO'
                : 'SECURY TABLET / PROFESSOR',
            style: textTheme.labelSmall?.copyWith(color: AppTheme.onBrandMuted),
          );
          final shortcutButtons = [
            for (final shortcut in shortcuts)
              TextButton.icon(
                onPressed: () => context.go(shortcut.path),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.onBrand,
                  backgroundColor: Colors.white.withValues(alpha: .12),
                  overlayColor: Colors.white,
                  textStyle: textTheme.labelMedium?.copyWith(
                    fontFamily: 'Roboto',
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                ),
                icon: Icon(shortcut.icon, size: 18),
                label: Text(shortcut.label),
              ),
          ];
          final identity = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact)
                Row(
                  children: [
                    Expanded(child: eyebrow),
                    IconButton(
                      tooltip: refreshTooltip,
                      onPressed: onRefresh,
                      color: AppTheme.onBrand,
                      icon: const Icon(Icons.refresh_outlined, size: 20),
                    ),
                  ],
                )
              else
                eyebrow,
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                header: true,
                child: Text(
                  admin ? 'Seu espaço de gestão.' : 'Seu espaço de professor.',
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppTheme.onBrand,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Olá, ${controller.displayName}',
                style: textTheme.titleMedium?.copyWith(color: AppTheme.onBrand),
              ),
              Text(
                admin
                    ? 'Perfil administrativo'
                    : 'Matrícula: ${controller.professor?.registration ?? '—'}',
                style: textTheme.bodySmall?.copyWith(
                  color: AppTheme.onBrandMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (compact)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final button in shortcutButtons) ...[
                        button,
                        const SizedBox(width: AppSpacing.xs),
                      ],
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: shortcutButtons,
                ),
            ],
          );
          final overview = GlassSurface(
            borderRadius: AppRadius.card,
            shadows: AppShadows.soft,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        admin ? 'Visão do armário' : 'Seu atendimento',
                        style: textTheme.labelLarge?.copyWith(
                          color: AppTheme.muted,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: refreshTooltip,
                      onPressed: onRefresh,
                      color: AppTheme.muted,
                      icon: const Icon(Icons.refresh_outlined, size: 20),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(detail, style: textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          );
          if (constraints.maxWidth >= 840 &&
              MediaQuery.textScalerOf(context).scale(1) <= 1.3) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 3, child: identity),
                const SizedBox(width: AppSpacing.xl),
                Expanded(flex: 2, child: overview),
              ],
            );
          }
          if (compact) return identity;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              identity,
              const SizedBox(height: AppSpacing.lg),
              overview,
            ],
          );
        },
      ),
    );
  }
}
