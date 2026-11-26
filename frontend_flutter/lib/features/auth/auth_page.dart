import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_backdrop.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_surface.dart';
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

  Widget _buildScaffold(BuildContext context) {
    final admin = !professorPasswordMode;
    final stops = AppBackdrop.loginStopsFor(admin);
    return Scaffold(
      backgroundColor: stops.first,
      body: GlassBackdrop(
        stops: stops,
        glows: AppBackdrop.loginGlowsFor(admin),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              return Row(
                children: [
                  if (wide) const Expanded(child: _InstitutionPanel()),
                  Expanded(
                    key: const ValueKey('access-form-pane'),
                    child: LayoutBuilder(
                      builder: (context, pane) => SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.manual,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: pane.maxHeight,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: wide ? AppSpacing.xxl : AppSpacing.md,
                              vertical: wide ? AppSpacing.xxl : AppSpacing.lg,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 440,
                                ),
                                child: _Entrance(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!wide) ...[
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: AppSpacing.xs,
                                          ),
                                          child: BrandMark(
                                            inverted: true,
                                            compact: true,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.lg),
                                      ],
                                      GlassSurface(
                                        key: const ValueKey('access-glass'),
                                        tone: GlassTone.dark,
                                        fallbackColor: stops.first,
                                        padding: EdgeInsets.all(
                                          wide ? AppSpacing.xl : AppSpacing.lg,
                                        ),
                                        child: Theme(
                                          data: AppTheme.onDarkGlass(
                                            Theme.of(context),
                                            admin: admin,
                                          ),
                                          child: Builder(builder: _buildForm),
                                        ),
                                      ),
                                    ],
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
      ),
    );
  }

  /// Built under [AppTheme.onDarkGlass]: white text, translucent fields.
  Widget _buildForm(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final helpStyle = textTheme.bodySmall?.copyWith(height: 1.6);
    final glowColor = AppTheme.focusGlowFor(!professorPasswordMode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          professorPasswordMode
              ? 'ACESSO DO PROFESSOR'
              : adminMode
              ? 'ACESSO COM CADASTRO'
              : 'ACESSO POR CRACHÁ',
          style: textTheme.labelSmall?.copyWith(color: AppTheme.onBrandMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          header: true,
          child: Text(
            professorPasswordMode
                ? 'Bem-vindo, professor'
                : adminMode
                ? 'Bem-vindo ao Secury Tablet'
                : 'Passe o crachá',
            style: textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          professorPasswordMode
              ? 'Entre com seu usuário e senha para acessar seus tablets.'
              : adminMode
              ? 'Entre com seu usuário e senha para acessar a gestão de tablets.'
              : 'Aproxime seu crachá do leitor para acessar seus tablets.',
          style: textTheme.bodyMedium?.copyWith(color: AppTheme.onBrandMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
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
                const SizedBox(height: AppSpacing.lg),
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
                              setState(
                                () => passwordVisible = !passwordVisible,
                              );
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
          _ReaderVisual(color: glowColor),
          const SizedBox(height: AppSpacing.lg),
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
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Após a leitura, pressione Enter ou selecione Validar crachá.',
            style: textTheme.bodySmall,
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: AppSpacing.md),
          InlineNotice(
            title: error!.title,
            message: error!.message,
            hint: error!.recoveryHint,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: GlassButton(
            key: const Key('access-submit'),
            variant: GlassButtonVariant.primary,
            loading: loading,
            loadingLabel: 'Verificando acesso…',
            onPressed: credentialMode ? _loginCredentials : _identify,
            label: credentialMode
                ? adminMode && authorizeTerminal
                      ? 'Autorizar terminal'
                      : 'Acessar'
                : 'Validar crachá',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _OrDivider(),
        const SizedBox(height: AppSpacing.lg),
        if (adminMode) ...[
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              key: const Key('professor-password-access'),
              onPressed: loading ? null : () => context.go('/professor/login'),
              icon: Icons.school_outlined,
              label: 'Entrar como professor',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (credentialMode)
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              key: const Key('badge-access'),
              onPressed: loading ? null : () => context.go('/login'),
              icon: Icons.contactless_outlined,
              label: 'Passe o crachá',
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              key: const Key('professor-password-access'),
              onPressed: loading ? null : () => context.go('/professor/login'),
              icon: Icons.person_outline,
              label: 'Entrar com usuário e senha',
            ),
          ),
        if (!adminMode) ...[
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: GlassButton(
              variant: GlassButtonVariant.ghost,
              onPressed: loading ? null : () => context.go('/admin/login'),
              label: 'Acesso administrativo',
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(
          credentialMode
              ? 'Precisa de um cadastro ou esqueceu a senha? Procure a administração.'
              : 'Primeiro acesso? Solicite à administração a autorização deste terminal.',
          textAlign: TextAlign.center,
          style: helpStyle,
        ),
        const SizedBox(height: AppSpacing.md),
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
              icon: const Icon(Icons.refresh_outlined, size: 20),
            ),
          ],
        ),
        if (adminMode) ...[
          const SizedBox(height: AppSpacing.xs),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text(
              'Configurar acesso por crachá',
              style: textTheme.bodySmall,
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
          ),
        ] else if (!professorPasswordMode) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'O crachá identifica seu cadastro. O acesso depende de um terminal autorizado.',
            textAlign: TextAlign.center,
            style: helpStyle,
          ),
        ],
      ],
    );
  }
}

/// "ou" separator between the primary access and the alternatives.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Divider(height: 1, color: Colors.white.withValues(alpha: .22)),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text('ou', style: Theme.of(context).textTheme.bodySmall),
        ),
        line,
      ],
    );
  }
}

/// Discreet one-time entrance: fade plus a short upward slide. Skipped when
/// the platform asks for reduced motion.
class _Entrance extends StatelessWidget {
  const _Entrance({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.entrance,
      curve: AppMotion.curve,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * AppMotion.entranceOffset),
          child: child,
        ),
      ),
    );
  }
}

/// Contactless reader cue for the badge flow (decorative, text carries meaning).
class _ReaderVisual extends StatelessWidget {
  const _ReaderVisual({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppGlass.darkControlFill(tint: AppGlass.fieldTint),
        borderRadius: AppRadius.card,
        border: Border.all(color: Colors.white.withValues(alpha: .22)),
      ),
      child: Column(
        children: [
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: 88,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (final (size, alpha) in const [
                    (88.0, .18),
                    (66.0, .30),
                    (44.0, .45),
                  ])
                    Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withValues(alpha: alpha),
                        ),
                      ),
                    ),
                  Icon(Icons.contactless_outlined, size: 28, color: color),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Aproxime do leitor', style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Retire, devolva e acompanhe seus tablets.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _InstitutionPanel extends StatelessWidget {
  const _InstitutionPanel();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight > 680
                ? constraints.maxHeight
                : 680,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BrandMark(inverted: true),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TECNOLOGIA A SERVIÇO DA EDUCAÇÃO',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppTheme.onBrandMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Seus tablets.\nSempre em\nboas mãos.',
                        style: textTheme.displaySmall?.copyWith(
                          color: AppTheme.onBrand,
                          fontSize: 52,
                          height: 1.05,
                          letterSpacing: -1.8,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: Text(
                          'Mais praticidade para retirar, devolver e acompanhar '
                          'os tablets da sua instituição.',
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppTheme.onBrandMuted,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const _AccessFeatures(),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: .2),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'SECURY TABLET',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppTheme.onBrand,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Controle e cuidado em cada movimentação.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppTheme.onBrandMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccessFeatures extends StatelessWidget {
  const _AccessFeatures();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.output_outlined, 'Retire para sua aula'),
      (Icons.fact_check_outlined, 'Devolva com conferência'),
      (Icons.history_outlined, 'Acompanhe suas movimentações'),
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: GlassSurface(
        key: const ValueKey('access-features-glass'),
        tone: GlassTone.dark,
        fallbackColor: AppBackdrop.loginStopsFor(
          AppTheme.isAdminTheme(Theme.of(context)),
        ).first,
        borderRadius: AppRadius.card,
        shadows: AppShadows.soft,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0)
                Divider(height: 1, color: Colors.white.withValues(alpha: .14)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        items[index].$1,
                        color: AppTheme.onBrand,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        items[index].$2,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppTheme.onBrand),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
