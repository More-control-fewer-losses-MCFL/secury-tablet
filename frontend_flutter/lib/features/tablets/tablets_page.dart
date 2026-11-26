import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/display.dart';
import '../../models/system_models.dart';
import '../../services/app_controller.dart';
import '../../widgets/common_widgets.dart';

class TabletsPage extends StatefulWidget {
  const TabletsPage({required this.controller, super.key});
  final AppController controller;

  @override
  State<TabletsPage> createState() => _TabletsPageState();
}

class _TabletsPageState extends State<TabletsPage> {
  late Future<List<Tablet>> tablets;

  @override
  void initState() {
    super.initState();
    tablets = widget.controller.api.tablets();
  }

  void _reload() => setState(() => tablets = widget.controller.api.tablets());

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PageHeading(
        'Tablets',
        'Inventário e disponibilidade informados pela API.',
      ),
      FutureBuilder<List<Tablet>>(
        future: tablets,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error! as ApiException).message
                : 'Não foi possível carregar os tablets.';
            return ErrorPanel(message: message, onRetry: _reload);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.requireData;
          if (data.isEmpty) {
            return const SectionCard(
              child: StateMessage(
                message: 'A API não retornou tablets cadastrados.',
                icon: Icons.tablet_android_outlined,
              ),
            );
          }
          final textTheme = Theme.of(context).textTheme;
          return SectionCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionTitle(
                  '${data.length} tablet(s)',
                  action: IconButton(
                    onPressed: _reload,
                    tooltip: 'Atualizar',
                    color: AppTheme.muted,
                    icon: const Icon(Icons.refresh_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final tablet in data) ...[
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    leading: const Icon(
                      Icons.tablet_mac_outlined,
                      color: AppTheme.muted,
                    ),
                    title: Text(
                      tablet.assetCode,
                      style: textTheme.titleSmall?.copyWith(
                        fontFeatures: AppTheme.tabularFigures,
                      ),
                    ),
                    subtitle: Text(
                      'Atualizado ${formatDateTime(tablet.updatedAt)}'
                      '${tablet.hasRfidTag ? ' · Etiqueta RFID cadastrada' : ''}',
                      style: textTheme.bodySmall,
                    ),
                    trailing: StatusPill(
                      tabletStatusLabel(tablet.status),
                      color: tabletStatusColor(tablet.status),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      const SizedBox(height: AppSpacing.lg),
      const HintNote(
        'A API atual informa patrimônio, estado e presença de etiqueta RFID. '
        'Não há integração disponível para sensores ou compartimentos físicos.',
      ),
    ],
  );
}
