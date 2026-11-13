import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/display.dart';
import '../../models/system_models.dart';
import '../../services/app_controller.dart';
import '../../widgets/common_widgets.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({required this.controller, super.key});
  final AppController controller;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final purposeController = TextEditingController();
  final classController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  late Future<Availability> availability;
  CheckoutResult? result;
  bool submitting = false;
  String? error;

  @override
  void initState() {
    super.initState();
    availability = widget.controller.api.availability();
  }

  @override
  void dispose() {
    purposeController.dispose();
    classController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (submitting) return;
    final quantity = int.tryParse(quantityController.text);
    if (quantity == null || quantity < 1) {
      setState(() => error = 'Informe uma quantidade válida.');
      return;
    }
    if (purposeController.text.trim().length < 3) {
      setState(() => error = 'Informe a finalidade da retirada.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar retirada'),
        content: Text(
          'Solicitar $quantity tablet(s) em nome de '
          '${widget.controller.professor?.name ?? 'professor identificado'}? '
          'A retirada só será registrada após a conferência do inventário.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      submitting = true;
      error = null;
      result = null;
    });
    try {
      final badgeUid = widget.controller.badgeUid;
      result = await widget.controller.api.createCheckout(
        badgeUid: badgeUid,
        quantity: quantity,
        purpose: purposeController.text.trim(),
        className: classController.text.trim().isEmpty
            ? null
            : classController.text.trim(),
      );
      availability = widget.controller.api.availability();
    } on ApiException catch (exception) {
      error = exception.message;
    } on FormatException catch (exception) {
      error = exception.message;
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PageHeading(
        'Registrar retirada',
        'Confira os tablets disponíveis e informe o que precisa para sua aula.',
      ),
      FutureBuilder<Availability>(
        future: availability,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error! as ApiException).message
                : 'Não foi possível consultar a disponibilidade.';
            return ErrorPanel(
              message: message,
              onRetry: () => setState(
                () => availability = widget.controller.api.availability(),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final data = snapshot.requireData;
          return LayoutBuilder(
            builder: (context, constraints) {
              final sideBySide = constraints.maxWidth >= 900;
              final summary = _availabilitySummary(context, data);
              final form = _requestForm(context, data);
              return sideBySide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: summary),
                        const SizedBox(width: 24),
                        Expanded(flex: 7, child: form),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [summary, const SizedBox(height: 20), form],
                    );
            },
          );
        },
      ),
      if (result != null) ...[
        const SizedBox(height: 20),
        Semantics(
          liveRegion: true,
          child: SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StateMessage(
                  message: 'Solicitação enviada. A retirada dos tablets será confirmada pela conferência do inventário.',
                  icon: Icons.check_circle_outline,
                  color: AppTheme.success,
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text('Solicitação #${result!.sessionId}'),
                    StatusPill(
                      sessionStatusLabel(result!.status),
                      color: sessionStatusColor(result!.status),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Professor: ${result!.professorName}'),
              ],
            ),
          ),
        ),
      ],
    ],
  );

  Widget _availabilitySummary(BuildContext context, Availability data) =>
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Disponibilidade atual'),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.tablet_android_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data.available}',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      Text(
                        data.available == 1
                            ? 'tablet disponível'
                            : 'tablets disponíveis',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'De ${data.total} tablets cadastrados',
                        style: const TextStyle(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (data.available == 0)
              const Text('Nenhum tablet disponível no momento.')
            else
              const Text(
                'Informe a quantidade desejada. Os itens retirados serão conferidos individualmente.',
              ),
            if (data.tablets.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: data.tablets
                    .map((tablet) => Chip(label: Text(tablet.assetCode)))
                    .toList(),
              ),
            ],
          ],
        ),
      );

  Widget _requestForm(BuildContext context, Availability data) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Dados da solicitação'),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.badge_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.controller.professor?.name ?? 'Professor',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Matrícula ${widget.controller.professor?.registration ?? '—'}',
                    style: const TextStyle(color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 32),
        TextField(
          controller: quantityController,
          enabled: !submitting,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Quantidade de tablets',
            prefixIcon: Icon(Icons.tablet_mac_outlined),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: purposeController,
          enabled: !submitting,
          textInputAction: TextInputAction.next,
          maxLength: 200,
          decoration: const InputDecoration(
            labelText: 'Finalidade',
            hintText: 'Ex.: atividade em laboratório',
            prefixIcon: Icon(Icons.edit_note_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: classController,
          enabled: !submitting,
          maxLength: 100,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Turma (opcional)',
            prefixIcon: Icon(Icons.groups_outlined),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(error!, style: const TextStyle(color: AppTheme.danger)),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: submitting || data.available == 0 ? null : _submit,
          icon: submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.output_outlined),
          label: Text(
            submitting ? 'Enviando solicitação…' : 'Confirmar retirada',
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'A quantidade solicitada pode ser diferente da quantidade efetivamente retirada.',
          style: TextStyle(color: AppTheme.muted),
        ),
      ],
    ),
  );
}
