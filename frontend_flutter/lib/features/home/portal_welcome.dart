import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../services/app_controller.dart';

class PortalShortcut {
  const PortalShortcut(this.label, this.icon, this.path);
  final String label;
  final IconData icon;
  final String path;
}

/// Presentation of the authenticated profile; permissions remain in the API.
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
    return Container(
      key: const Key('portal-welcome'),
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 24 : 36),
      decoration: BoxDecoration(
        color: AppTheme.headerFor(admin),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final identity = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                admin
                    ? 'SECURY TABLET / ADMINISTRAÇÃO'
                    : 'SECURY TABLET / PROFESSOR',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Semantics(
                header: true,
                child: Text(
                  admin ? 'Seu espaço de gestão.' : 'Seu espaço de professor.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: constraints.maxWidth < 600 ? 28 : 36,
                    height: 1.15,
                    letterSpacing: -.7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person_outline, color: AppTheme.text),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, ${controller.displayName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 19,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          admin
                              ? 'Perfil administrativo'
                              : 'Matrícula: ${controller.professor?.registration ?? '—'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final shortcut in shortcuts)
                    OutlinedButton.icon(
                      onPressed: () => context.go(shortcut.path),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        textStyle: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                      icon: Icon(shortcut.icon, size: 18),
                      label: Text(shortcut.label),
                    ),
                ],
              ),
            ],
          );
          final overview = Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: .3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        admin ? 'Visão do armário' : 'Seu atendimento',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: admin
                          ? 'Atualizar painel'
                          : 'Atualizar meus dados',
                      onPressed: onRefresh,
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  summary,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.6,
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
                const SizedBox(width: 40),
                Expanded(flex: 2, child: overview),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [identity, const SizedBox(height: 24), overview],
          );
        },
      ),
    );
  }
}
