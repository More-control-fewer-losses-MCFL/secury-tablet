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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PageHeading(
        'Configurações',
        'Estado das integrações e limitações conhecidas da API atual.',
      ),
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              'API e banco de dados',
              action: IconButton(
                onPressed: _refresh,
                tooltip: 'Verificar novamente',
                icon: const Icon(Icons.refresh),
              ),
            ),
            const SizedBox(height: 8),
            Text('Endereço: ${AppConfig.apiBaseUrl}'),
            const SizedBox(height: 12),
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
                  spacing: 10,
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
      const SizedBox(height: 16),
      const SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle('Integrações não disponíveis na API atual'),
            SizedBox(height: 12),
            Text('• Não existe emissão de token ou sessão autenticada.'),
            Text('• Não existe listagem geral nem edição de professores.'),
            Text(
              '• Não existe endpoint de agenda futura ou lista de devoluções pendentes.',
            ),
            Text('• Não há contrato de integração com Google Sheets.'),
            Text(
              '• Leitor RFID e fechadura dependem de hardware/controlador configurado no backend.',
            ),
            SizedBox(height: 12),
            Text(
              'Identificação por UID RFID não é autenticação criptográfica e não deve proteger dados ou operações em produção sem autorização emitida pelo servidor.',
              style: TextStyle(color: AppTheme.warning),
            ),
          ],
        ),
      ),
    ],
  );
}
