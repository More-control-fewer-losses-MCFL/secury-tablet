import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
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
          'O backend poderá acionar a fechadura configurada.',
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
      if (badgeUid == null) {
        throw const ApiException(
          'Identifique novamente o crachá antes de continuar.',
        );
      }
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
        'Confira a disponibilidade e confirme a operação junto à API.',
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
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.requireData;
          return Column(
            children: [
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('Disponibilidade atual'),
                    const SizedBox(height: 12),
                    Text(
                      '${data.available} disponível(is) de ${data.total} tablet(s)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    if (data.tablets.isEmpty)
                      const Text('Nenhum tablet disponível.')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: data.tablets
                            .map(
                              (tablet) => Chip(label: Text(tablet.assetCode)),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('Dados da solicitação'),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.badge_outlined,
                        color: AppTheme.blue,
                      ),
                      title: Text(
                        widget.controller.professor?.name ?? 'Professor',
                      ),
                      subtitle: Text(
                        'Matrícula ${widget.controller.professor?.registration ?? '—'}',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantidade de tablets',
                        prefixIcon: Icon(Icons.tablet_mac_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: purposeController,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        labelText: 'Finalidade',
                        hintText: 'Ex.: atividade em laboratório',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: classController,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Turma (opcional)',
                      ),
                    ),
                    if (error != null)
                      Text(
                        error!,
                        style: const TextStyle(color: AppTheme.danger),
                      ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: submitting || data.available == 0
                          ? null
                          : _submit,
                      icon: submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.lock_open_outlined),
                      label: Text(
                        submitting ? 'Enviando à API…' : 'Confirmar retirada',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      if (result != null) ...[
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StateMessage(
                message: 'A API confirmou a solicitação. A retirada física dos tablets será confirmada pelo inventário do hardware.',
                icon: Icons.check_circle_outline,
                color: AppTheme.success,
              ),
              Text('Solicitação #${result!.sessionId}'),
              Text('Situação: ${result!.status}'),
              Text('Professor: ${result!.professorName}'),
            ],
          ),
        ),
      ],
    ],
  );
}
