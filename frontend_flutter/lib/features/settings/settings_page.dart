import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/system_models.dart';
import '../../services/app_controller.dart';
import '../../widgets/common_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({required this.controller, super.key});
  final AppController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<ApiHealth> health;

  @override
  void initState() {
    super.initState();
    health = widget.controller.api.health();
  }

  void _refresh() => setState(() => health = widget.controller.api.health());

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeading(
          'Configurações',
          'Estado das integrações e limitações conhecidas da API atual.',
        ),
        SectionCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(
                'API e banco de dados',
                action: IconButton(
                  onPressed: _refresh,
                  tooltip: 'Verificar novamente',
                  color: AppTheme.muted,
                  icon: const Icon(Icons.refresh_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Endereço: ${AppConfig.apiBaseUrl}',
                style: textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
              ),
              const SizedBox(height: AppSpacing.sm),
              FutureBuilder<ApiHealth>(
                future: health,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    final message = snapshot.error is ApiException
                        ? (snapshot.error! as ApiException).message
                        : 'Falha ao verificar a API.';
                    return StatusPill(message, color: AppTheme.danger);
                  }
                  if (!snapshot.hasData) {
                    return const LinearProgressIndicator();
                  }
                  final data = snapshot.requireData;
                  return Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      StatusPill(
                        'API: ${data.status}',
                        color: data.status == 'ok'
                            ? AppTheme.success
                            : AppTheme.danger,
                      ),
                      StatusPill(
                        'Banco: ${data.database}',
                        color: data.database == 'ok'
                            ? AppTheme.success
                            : AppTheme.danger,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Integrações não disponíveis na API atual'),
              const SizedBox(height: AppSpacing.sm),
              for (final item in const [
                'Existem sessões de administrador e professor; uso de crachá exige terminal autorizado.',
                'Não existe listagem geral nem edição de professores.',
                'Não existe endpoint de agenda futura ou lista de devoluções pendentes.',
                'Não há contrato de integração com Google Sheets.',
                'Leitor RFID e fechadura dependem de hardware/controlador configurado no backend.',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                  child: Text('• $item', style: textTheme.bodyMedium),
                ),
              const SizedBox(height: AppSpacing.sm),
              const InlineNotice(
                message: 'Identificação por UID RFID não é autenticação criptográfica e não deve proteger dados ou operações em produção sem autorização emitida pelo servidor.',
                color: AppTheme.warning,
                icon: Icons.warning_amber_outlined,
                live: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
