import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/system_models.dart';
import '../../services/app_controller.dart';
import '../../widgets/common_widgets.dart';
import '../shell/brand_mark.dart';
import '../shell/locker_illustration.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({required this.controller, super.key});

  final AppController controller;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final badgeController = TextEditingController();
  final adminUsernameController = TextEditingController(text: 'admin');
  final adminPasswordController = TextEditingController();
  bool loading = false;
  bool checkingApi = true;
  bool adminMode = false;
  bool authorizeTerminal = false;
  String? error;
  ApiHealth? health;
  Professor? identified;

  @override
  void initState() {
    super.initState();
    _checkApi();
  }

  @override
  void dispose() {
    badgeController.dispose();
    adminUsernameController.dispose();
    adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkApi() async {
    try {
      final result = await widget.controller.api.health();
      if (mounted) setState(() => health = result);
    } on ApiException {
      if (mounted) setState(() => health = null);
    } finally {
      if (mounted) setState(() => checkingApi = false);
    }
  }

  Future<void> _identify() async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
      identified = null;
    });
    try {
      identified = await widget.controller.identify(badgeController.text);
      if (mounted) context.go('/home');
    } on ApiException catch (exception) {
      setState(() => error = exception.message);
    } on FormatException catch (exception) {
      setState(() => error = exception.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loginAdmin() async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (authorizeTerminal) {
        await widget.controller.authorizeTerminal(
          adminUsernameController.text,
          adminPasswordController.text,
        );
        if (mounted) {
          setState(() {
            adminMode = false;
            authorizeTerminal = false;
            adminPasswordController.clear();
          });
        }
        return;
      }
      await widget.controller.loginAdmin(
        adminUsernameController.text,
        adminPasswordController.text,
      );
      if (mounted) context.go('/home');
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } on FormatException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return Column(
            children: [
              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                color: Colors.white,
                child: const Row(
                  children: [
                    BrandMark(),
                    Spacer(),
                    Text(
                      'ACESSO AO SISTEMA',
                      style: TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Padding(
                      padding: EdgeInsets.all(wide ? 32 : 16),
                      child: wide
                          ? Row(
                              children: [
                                const Expanded(child: _InstitutionPanel()),
                                const SizedBox(width: 24),
                                SizedBox(
                                  width: 430,
                                  child: SingleChildScrollView(
                                    child: _buildForm(context),
                                  ),
                                ),
                              ],
                            )
                          : SingleChildScrollView(
                              child: Column(
                                children: [
                                  const SizedBox(
                                    height: 360,
                                    child: _InstitutionPanel(),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildForm(context),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _buildForm(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          adminMode ? Icons.admin_panel_settings_outlined : Icons.contactless,
          color: AppTheme.blue,
          size: 30,
        ),
        const SizedBox(height: 14),
        Text(
          adminMode ? 'Acesso administrativo' : 'Identificação por RFID',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 7),
        Text(
          adminMode
              ? 'Entre com as credenciais de administrador configuradas no servidor.'
              : 'Aproxime seu crachá do leitor para consultar o cadastro.',
          style: TextStyle(color: AppTheme.muted),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: loading
                ? null
                : () => setState(() {
                    adminMode = !adminMode;
                    error = null;
                  }),
            child: Text(
              adminMode
                  ? 'Voltar ao acesso por RFID'
                  : 'Entrar como administrador',
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (adminMode) ...[
          CheckboxListTile(
            value: authorizeTerminal,
            contentPadding: EdgeInsets.zero,
            title: const Text('Autorizar este terminal e voltar ao RFID'),
            onChanged: loading
                ? null
                : (value) => setState(() => authorizeTerminal = value ?? false),
          ),
          TextField(
            controller: adminUsernameController,
            enabled: !loading,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Usuário',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: adminPasswordController,
            enabled: !loading,
            obscureText: true,
            onSubmitted: (_) => _loginAdmin(),
            textInputAction: TextInputAction.go,
            decoration: const InputDecoration(
              labelText: 'Senha de administrador',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
        ] else ...[
          TextField(
            controller: badgeController,
            autofocus: true,
            enabled: !loading,
            onSubmitted: (_) => _identify(),
            textInputAction: TextInputAction.go,
            decoration: const InputDecoration(
              labelText: 'Leitura do crachá',
              hintText: 'Aguardando leitura do leitor USB',
              prefixIcon: Icon(Icons.rss_feed),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Leitor configurado como teclado USB: os dados são processados ao pressionar Enter. '
            'O navegador não consegue verificar se um leitor físico está conectado.',
            style: TextStyle(color: AppTheme.muted, fontSize: 12),
          ),
        ],
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: loading
                ? null
                : adminMode
                ? _loginAdmin
                : _identify,
            icon: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.verified_user_outlined),
            label: Text(
              loading
                  ? adminMode
                        ? 'Validando acesso…'
                        : 'Validando cadastro…'
                  : adminMode
                  ? 'Entrar como administrador'
                  : 'Validar crachá',
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          StateMessage(
            message: error!,
            icon: Icons.error_outline,
            color: AppTheme.danger,
          ),
        ],
        if (!adminMode && identified != null) ...[
          const SizedBox(height: 16),
          StateMessage(
            message: 'Crachá identificado: ${identified!.name}',
            icon: Icons.check_circle_outline,
            color: AppTheme.success,
          ),
        ],
        Row(
          children: [
            StatusPill(
              checkingApi
                  ? 'Verificando API'
                  : health == null
                  ? 'API indisponível'
                  : 'API e banco conectados',
              color: checkingApi
                  ? AppTheme.warning
                  : health == null
                  ? AppTheme.danger
                  : AppTheme.success,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'O acesso por RFID exige um terminal autorizado pela administração. '
          'O crachá identifica o cadastro; um UID copiado ainda pode ser usado neste terminal. '
          'No primeiro uso, entre como administrador e marque a autorização do terminal.',
          style: TextStyle(color: AppTheme.warning, fontSize: 12),
        ),
      ],
    ),
  );
}

class _InstitutionPanel extends StatelessWidget {
  const _InstitutionPanel();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: AppTheme.navy,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -10,
          bottom: -25,
          child: Opacity(
            opacity: 0.45,
            child: SizedBox(
              width: 230,
              height: 230,
              child: LockerIllustration(light: true),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SENAI  |  TABLET DE SEGURANÇA',
                  style: TextStyle(
                    color: Color(0xFFBBD9FF),
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Mais segurança para o seu dia a dia',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Controle de retiradas e devoluções, identificação por RFID e gestão completa dos equipamentos.',
                  style: TextStyle(
                    color: Color(0xFFD6E6F8),
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 26),
                const Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.white70, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Acesso controlado por cadastro institucional',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
