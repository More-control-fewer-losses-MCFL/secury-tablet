import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../models/admin_monitoring.dart';
import '../../services/system_api.dart';
import '../../widgets/common_widgets.dart';

class AdminRfidPanel extends StatefulWidget {
  const AdminRfidPanel({required this.api, super.key});

  final SystemApi api;

  @override
  State<AdminRfidPanel> createState() => _AdminRfidPanelState();
}

class _AdminRfidPanelState extends State<AdminRfidPanel> {
  Future<List<RfidReading>>? _readings;

  void _load() => setState(() => _readings = widget.api.adminRfidReadings());

  @override
  Widget build(BuildContext context) => SectionCard(
    child: FutureBuilder<List<RfidReading>>(
      future: _readings,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final error = snapshot.error;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitle(
              'Leituras RFID do carrinho',
              action: OutlinedButton.icon(
                onPressed: loading ? null : _load,
                icon: const Icon(Icons.refresh),
                label: Text(_readings == null ? 'Consultar' : 'Atualizar'),
              ),
            ),
            if (loading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(
                semanticsLabel: 'Carregando leituras RFID',
              ),
            ] else if (error != null)
              InlineNotice(
                title: 'Consulta indisponível',
                message: error is ApiException
                    ? error.message
                    : 'Não foi possível carregar as leituras RFID.',
              )
            else if (snapshot.hasData)
              if (snapshot.requireData.isEmpty)
                const StateMessage(
                  message: 'Nenhuma leitura RFID registrada.',
                  icon: Icons.nfc_outlined,
                )
              else
                for (final reading in snapshot.requireData)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(reading.uid ?? 'UID indisponível'),
                    subtitle: Text(
                      [reading.dateTime, reading.terminal, reading.status]
                          .whereType<String>()
                          .where((value) => value.isNotEmpty)
                          .join(' · '),
                    ),
                  ),
          ],
        );
      },
    ),
  );
}
