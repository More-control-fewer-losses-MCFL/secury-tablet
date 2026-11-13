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
  const AuthPage({required this.controller, this.adminMode = false, super.key});

  final AppController controller;
  final bool adminMode;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final badgeController = TextEditingController();
  final adminUsernameController = TextEditingController(text: 'admin');
  final adminPasswordController = TextEditingController();
  bool loading = false;
  bool passwordVisible = false;
  bool checkingApi = true;
  bool get adminMode => widget.adminMode;
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
      if (mounted) setState(() => error = exception.message);
    } on FormatException catch (exception) {
      if (mounted) setState(() => error = exception.message);
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
          adminPasswordController.clear();
          context.go('/login');
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
          final wide = constraints.maxWidth >= 980;
          return Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 32 : 16,
                  vertical: 18,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: AppTheme.border)),
                ),
                child: Row(
                  children: [
                    const Expanded(child: BrandMark()),
                    if (wide)
                      const Text(
                        'SECURY TABLET  /  ACESSO SEGURO',
                        style: TextStyle(
                          color: AppTheme.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Padding(
                        padding: EdgeInsets.all(wide ? 40 : 16),
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Expanded(
                                    flex: 6,
                                    child: _InstitutionPanel(),
                                  ),
                                  const SizedBox(width: 32),
                                  Expanded(flex: 5, child: _buildForm(context)),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildForm(context),
                                  const SizedBox(height: 20),
                                  const _InstitutionPanel(compact: true),
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
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 20 : 28),
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
          adminMode ? 'Acesse a gestão do armário com seu usuário e senha.' : 'Aproxime seu crachá para retirar, devolver e consultar seus tablets.',
          style: TextStyle(color: AppTheme.muted),
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
            autofillHints: const [AutofillHints.username],
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
            autofillHints: const [AutofillHints.password],
            obscureText: !passwordVisible,
            onSubmitted: (_) => _loginAdmin(),
            textInputAction: TextInputAction.go,
            decoration: InputDecoration(
              labelText: 'Senha de administrador',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: passwordVisible ? 'Ocultar senha' : 'Mostrar senha',
                onPressed: loading
                    ? null
                    : () => setState(() => passwordVisible = !passwordVisible),
                icon: Icon(
                  passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
        ] else ...[
          TextField(
            controller: badgeController,
            autocorrect: false,
            enableSuggestions: false,
            autofocus: true,
            enabled: !loading,
            onSubmitted: (_) => _identify(),
            textInputAction: TextInputAction.go,
            decoration: const InputDecoration(
              labelText: 'Leitura do crachá',
              hintText: 'Aproxime seu crachá',
              prefixIcon: Icon(Icons.rss_feed),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Após a leitura, pressione Enter ou selecione Validar crachá. '
            'No primeiro uso, solicite a autorização deste terminal à administração.',
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
        Center(
          child: TextButton(
            onPressed: loading
                ? null
                : () => context.go(adminMode ? '/login' : '/admin/login'),
            child: Text(
              adminMode
                  ? 'Voltar ao acesso por RFID'
                  : 'Entrar como administrador',
            ),
          ),
        ),
        const SizedBox(height: 8),
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
        Align(
          alignment: Alignment.centerLeft,
          child: StatusPill(
            checkingApi
                ? 'Verificando conexão'
                : health == null
                ? 'Sistema indisponível'
                : 'Sistema disponível',
            color: checkingApi
                ? AppTheme.warning
                : health == null
                ? AppTheme.danger
                : AppTheme.success,
          ),
        ),
        const SizedBox(height: 16),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 12),
          title: const Text(
            'Como funciona o acesso por crachá',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          children: [
            const Text(
              'O acesso por RFID exige um terminal autorizado pela administração. '
              'O crachá identifica o cadastro; um UID copiado ainda pode ser usado neste terminal. '
              'No primeiro uso, entre como administrador e marque a autorização do terminal.',
              style: TextStyle(color: AppTheme.warning, fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );
}

class _InstitutionPanel extends StatelessWidget {
  const _InstitutionPanel({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(compact ? 24 : 32),
    decoration: BoxDecoration(
      color: AppTheme.navy,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SEU ARMÁRIO DE TABLETS',
          style: TextStyle(
            color: Color(0xFFBDCEE8),
            fontSize: 12,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Retire com facilidade.\nDevolva com segurança.',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 12),
        const Text(
          'Um acesso para cada perfil e o registro de cada movimentação.',
          style: TextStyle(color: Color(0xFFDDE7F5), fontSize: 16, height: 1.5),
        ),
        if (!compact) ...[
          const SizedBox(height: 24),
          Center(
            child: Semantics(
              image: true,
              label: 'Armário com compartimentos individuais para tablets',
              child: const ExcludeSemantics(
                child: SizedBox(
                  width: 210,
                  height: 180,
                  child: LockerIllustration(light: true),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        const _AccessStep(
          icon: Icons.contactless_outlined,
          title: '1. Identifique-se',
          detail: 'Use seu crachá no terminal autorizado.',
        ),
        const SizedBox(height: 18),
        const _AccessStep(
          icon: Icons.tablet_android_outlined,
          title: '2. Escolha sua operação',
          detail: 'Solicite uma retirada ou registre uma devolução.',
        ),
        const SizedBox(height: 18),
        const _AccessStep(
          icon: Icons.fact_check_outlined,
          title: '3. Confira a confirmação',
          detail: 'Acompanhe os tablets confirmados e suas pendências.',
        ),
      ],
    ),
  );
}

class _AccessStep extends StatelessWidget {
  const _AccessStep({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              style: const TextStyle(color: Color(0xFFDDE7F5), height: 1.5),
            ),
          ],
        ),
      ),
    ],
  );
}
