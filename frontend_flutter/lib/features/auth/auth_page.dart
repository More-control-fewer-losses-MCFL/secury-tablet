import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/system_models.dart';
import '../../services/app_controller.dart';
import '../../widgets/common_widgets.dart';
import '../shell/brand_mark.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({
    required this.controller,
    this.adminMode = false,
    this.professorPasswordMode = false,
    super.key,
  }) : assert(!(adminMode && professorPasswordMode));

  final AppController controller;
  final bool adminMode;
  final bool professorPasswordMode;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final badgeController = TextEditingController();
  final adminUsernameController = TextEditingController();
  final adminPasswordController = TextEditingController();
  final usernameFocus = FocusNode(debugLabel: 'access-username');
  final passwordFocus = FocusNode(debugLabel: 'access-password');
  final badgeFocus = FocusNode(debugLabel: 'access-badge');
  String? usernameError;
  String? passwordError;
  String? badgeError;
  bool loading = false;
  bool passwordVisible = false;
  bool checkingApi = true;
  bool get adminMode => widget.adminMode;
  bool get professorPasswordMode => widget.professorPasswordMode;
  bool get credentialMode => adminMode || professorPasswordMode;
  Color get accessColor =>
      professorPasswordMode ? AppTheme.teacherPrimary : _accessBlue;
  bool authorizeTerminal = false;
  ApiException? error;
  ApiHealth? health;
  Professor? identified;

  @override
  void initState() {
    super.initState();
    if (adminMode) adminUsernameController.text = 'admin';
    _checkApi();
  }

  @override
  void dispose() {
    usernameFocus.dispose();
    passwordFocus.dispose();
    badgeFocus.dispose();
    badgeController.dispose();
    adminUsernameController.dispose();
    adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkApi() async {
    setState(() => checkingApi = true);
    try {
      final result = await widget.controller.api.health();
      if (mounted) setState(() => health = result);
    } on ApiException {
      if (mounted) setState(() => health = null);
    } on FormatException {
      if (mounted) setState(() => health = null);
    } finally {
      if (mounted) setState(() => checkingApi = false);
    }
  }

  Future<void> _identify() async {
    if (loading) return;
    if (badgeController.text.trim().isEmpty) {
      setState(() => badgeError = 'Aproxime o crachá ou informe a leitura.');
      badgeFocus.requestFocus();
      return;
    }
    setState(() {
      loading = true;
      error = null;
      identified = null;
    });
    try {
      identified = await widget.controller.identify(badgeController.text);
      if (mounted) context.go('/home');
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception);
    } on FormatException {
      if (mounted) {
        setState(
          () => error = const ApiException(
            'Não foi possível confirmar o acesso. Tente entrar novamente.',
            kind: ApiErrorKind.invalidResponse,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loginCredentials() async {
    if (loading) return;
    final missingUser = adminUsernameController.text.trim().isEmpty;
    final missingPassword = adminPasswordController.text.isEmpty;
    setState(() {
      usernameError = missingUser ? 'Informe seu usuário.' : null;
      passwordError = missingPassword ? 'Informe sua senha.' : null;
      error = null;
    });
    if (missingUser || missingPassword) {
      (missingUser ? usernameFocus : passwordFocus).requestFocus();
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (adminMode && authorizeTerminal) {
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
      if (professorPasswordMode) {
        await widget.controller.loginProfessor(
          adminUsernameController.text,
          adminPasswordController.text,
        );
      } else {
        await widget.controller.loginAdmin(
          adminUsernameController.text,
          adminPasswordController.text,
        );
      }
      adminPasswordController.clear();
      if (mounted) context.go('/home');
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception);
    } on FormatException {
      if (mounted) {
        setState(
          () => error = const ApiException(
            'Não foi possível confirmar o acesso. Tente entrar novamente.',
            kind: ApiErrorKind.invalidResponse,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: professorPasswordMode ? AppTheme.teacher : AppTheme.light,
    child: Builder(builder: _buildScaffold),
  );

  Widget _buildScaffold(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;
          return Row(
            children: [
              if (wide)
                Expanded(
                  child: _InstitutionPanel(
                    color: professorPasswordMode
                        ? AppTheme.teacherHeader
                        : _accessBlue,
                  ),
                ),
              Expanded(
                key: const ValueKey('access-form-pane'),
                child: LayoutBuilder(
                  builder: (context, pane) => SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.manual,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: pane.maxHeight),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: wide ? 56 : 24,
                          vertical: wide ? 48 : 28,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: Material(
                              color: Colors.white,
                              elevation: 2,
                              shadowColor: AppTheme.navy.withValues(alpha: .12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: const BorderSide(color: AppTheme.border),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(wide ? 32 : 20),
                                child: _buildForm(context, wide: wide),
                              ),
                            ),
                          ),
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

  Widget _buildForm(BuildContext context, {required bool wide}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (!wide) ...[
        const BrandMark(compact: true),
        const SizedBox(height: 36),
      ],
      Text(
        professorPasswordMode
            ? 'ACESSO DO PROFESSOR'
            : adminMode
            ? 'ACESSO COM CADASTRO'
            : 'ACESSO POR CRACHÁ',
        style: TextStyle(
          color: accessColor,
          fontSize: 11,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 12),
      Semantics(
        header: true,
        child: Text(
          professorPasswordMode
              ? 'Bem-vindo, professor'
              : adminMode
              ? 'Bem-vindo ao Secury Tablet'
              : 'Passe o crachá',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.25,
            letterSpacing: -.6,
          ),
        ),
      ),
      const SizedBox(height: 10),
      Text(
        professorPasswordMode
            ? 'Entre com seu usuário e senha para acessar seus tablets.'
            : adminMode
            ? 'Entre com seu usuário e senha para acessar a gestão de tablets.'
            : 'Aproxime seu crachá do leitor para acessar seus tablets.',
        style: const TextStyle(color: AppTheme.muted, height: 1.6),
      ),
      const SizedBox(height: 28),
      if (credentialMode)
        AutofillGroup(
          key: const ValueKey('credential-form'),
          child: Column(
            children: [
              TextField(
                key: const Key('access-username'),
                controller: adminUsernameController,
                focusNode: usernameFocus,
                autofillHints: const [AutofillHints.username],
                autocorrect: false,
                enableSuggestions: false,
                readOnly: loading,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => passwordFocus.requestFocus(),
                onChanged: (_) {
                  if (usernameError != null) {
                    setState(() => usernameError = null);
                  }
                },
                decoration: InputDecoration(
                  errorText: usernameError,
                  labelText: 'Usuário',
                  hintText: 'Informe seu usuário',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                key: const Key('access-password'),
                controller: adminPasswordController,
                focusNode: passwordFocus,
                readOnly: loading,
                autofillHints: const [AutofillHints.password],
                obscureText: !passwordVisible,
                onEditingComplete: () {},
                onSubmitted: (_) => _loginCredentials(),
                onChanged: (_) {
                  if (passwordError != null) {
                    setState(() => passwordError = null);
                  }
                },
                textInputAction: TextInputAction.go,
                decoration: InputDecoration(
                  errorText: passwordError,
                  labelText: 'Senha',
                  hintText: 'Informe sua senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: passwordVisible
                        ? 'Ocultar senha'
                        : 'Mostrar senha',
                    onPressed: loading
                        ? null
                        : () {
                            setState(() => passwordVisible = !passwordVisible);
                            passwordFocus.requestFocus();
                          },
                    icon: Icon(
                      passwordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
      else ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _accessBlue.withValues(alpha: .05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _accessBlue.withValues(alpha: .16)),
          ),
          child: const Column(
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.contactless_outlined,
                  size: 52,
                  color: _accessBlue,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Aproxime do leitor',
                style: TextStyle(
                  color: AppTheme.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Retire, devolva e acompanhe seus tablets.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.muted, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          key: const Key('access-badge'),
          controller: badgeController,
          focusNode: badgeFocus,
          autocorrect: false,
          enableSuggestions: false,
          autofocus: true,
          readOnly: loading,
          onEditingComplete: () {},
          onSubmitted: (_) => _identify(),
          onChanged: (_) {
            if (badgeError != null) setState(() => badgeError = null);
          },
          textInputAction: TextInputAction.go,
          decoration: InputDecoration(
            errorText: badgeError,
            labelText: 'Leitura do crachá',
            hintText: 'Aguardando leitura',
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Após a leitura, pressione Enter ou selecione Validar crachá.',
          style: TextStyle(color: AppTheme.muted, fontSize: 12),
        ),
      ],
      if (error != null) ...[
        const SizedBox(height: 12),
        InlineNotice(
          title: error!.title,
          message: error!.message,
          hint: error!.recoveryHint,
        ),
      ],
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: accessColor),
          onPressed: loading
              ? null
              : credentialMode
              ? _loginCredentials
              : _identify,
          child: loading
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Flexible(child: Text('Verificando acesso…')),
                  ],
                )
              : Text(
                  credentialMode
                      ? adminMode && authorizeTerminal
                            ? 'Autorizar terminal'
                            : 'Acessar'
                      : 'Validar crachá',
                ),
        ),
      ),
      const SizedBox(height: 24),
      const Divider(height: 1),
      const SizedBox(height: 24),
      if (adminMode) ...[
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const Key('professor-password-access'),
            onPressed: loading ? null : () => context.go('/professor/login'),
            icon: const Icon(Icons.school_outlined),
            label: const Text('Entrar como professor'),
          ),
        ),
        const SizedBox(height: 16),
      ],
      if (credentialMode)
        _BadgePrompt(onTap: loading ? null : () => context.go('/login'))
      else
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const Key('professor-password-access'),
            onPressed: loading ? null : () => context.go('/professor/login'),
            icon: const Icon(Icons.person_outline),
            label: const Text('Entrar com usuário e senha'),
          ),
        ),
      if (!adminMode)
        Center(
          child: TextButton(
            onPressed: loading ? null : () => context.go('/admin/login'),
            child: const Text('Acesso administrativo'),
          ),
        ),
      const SizedBox(height: 20),
      Text(
        credentialMode
            ? 'Precisa de um cadastro ou esqueceu a senha? Procure a administração.'
            : 'Primeiro acesso? Solicite à administração a autorização deste terminal.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.muted,
          fontSize: 12,
          height: 1.6,
        ),
      ),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
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
          IconButton(
            tooltip: 'Verificar conexão',
            onPressed: checkingApi ? null : _checkApi,
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (adminMode)
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text(
            'Configurar acesso por crachá',
            style: TextStyle(color: AppTheme.muted, fontSize: 12),
          ),
          children: [
            CheckboxListTile(
              value: authorizeTerminal,
              contentPadding: EdgeInsets.zero,
              title: const Text('Autorizar este terminal e voltar ao RFID'),
              onChanged: loading
                  ? null
                  : (value) =>
                        setState(() => authorizeTerminal = value ?? false),
            ),
          ],
        )
      else if (!professorPasswordMode)
        const Text(
          'O crachá identifica seu cadastro. O acesso depende de um terminal autorizado.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.muted, fontSize: 12, height: 1.6),
        ),
    ],
  );
}

const _accessBlue = Color(0xFF075DA8);

class _BadgePrompt extends StatelessWidget {
  const _BadgePrompt({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF2F7FC),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFD8E5F2)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: const Key('badge-access'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const ExcludeSemantics(
              child: Icon(
                Icons.contactless_outlined,
                color: _accessBlue,
                size: 36,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Passe o crachá',
                    style: TextStyle(
                      color: AppTheme.navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Acesso para professores pelo leitor.',
                    style: TextStyle(
                      color: AppTheme.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const ExcludeSemantics(
              child: Icon(Icons.arrow_forward, color: _accessBlue, size: 20),
            ),
          ],
        ),
      ),
    ),
  );
}

class _InstitutionPanel extends StatelessWidget {
  const _InstitutionPanel({this.color = _accessBlue});
  final Color color;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: color,
    child: CustomPaint(
      painter: const _AccessBackdrop(),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight > 680
                  ? constraints.maxHeight
                  : 680,
            ),
            child: Padding(
              padding: const EdgeInsets.all(56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BrandMark(inverted: true),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 64),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TECNOLOGIA A SERVIÇO DA EDUCAÇÃO',
                          style: TextStyle(
                            color: Color(0xFFD3E7FA),
                            fontSize: 11,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Seus tablets.\nSempre em\nboas mãos.',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                                letterSpacing: -1.4,
                              ),
                        ),
                        const SizedBox(height: 24),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: const Text(
                            'Mais praticidade para retirar, devolver e acompanhar '
                            'os tablets da sua instituição.',
                            style: TextStyle(
                              color: Color(0xFFE1EEFA),
                              fontSize: 16,
                              height: 1.7,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const _AccessFeatures(),
                      ],
                    ),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(color: Color(0xFF6C9FCB)),
                      SizedBox(height: 12),
                      Text(
                        'SECURY TABLET',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Controle e cuidado em cada movimentação.',
                        style: TextStyle(
                          color: Color(0xFFD3E7FA),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _AccessBackdrop extends CustomPainter {
  const _AccessBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final wave = Path()
      ..moveTo(size.width * .1, 0)
      ..cubicTo(
        size.width * .5,
        size.height * .25,
        size.width * .95,
        -size.height * .1,
        size.width,
        size.height * .3,
      )
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(wave, Paint()..color = Colors.white.withValues(alpha: .06));
    final rings = Paint()
      ..color = Colors.white.withValues(alpha: .055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 48;
    final center = Offset(-size.width * .18, size.height * 1.03);
    canvas.drawCircle(center, size.width * .48, rings);
    canvas.drawCircle(center, size.width * .7, rings);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AccessBackdrop oldDelegate) => false;
}

class _AccessFeatures extends StatelessWidget {
  const _AccessFeatures();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: .24)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in const [
          (Icons.output_outlined, 'Retire para sua aula'),
          (Icons.fact_check_outlined, 'Devolva com conferência'),
          (Icons.history_outlined, 'Acompanhe suas movimentações'),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(item.$1, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.$2,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
