import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
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
  Color get accessColor =>
      professorPasswordMode ? AppTheme.teacherPrimary : AppTheme.blue;
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
    final stops = AppTheme.backdropFor(!professorPasswordMode);
    return Scaffold(
      backgroundColor: stops.first,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: stops,
          ),
        ),
        child: CustomPaint(
          painter: const _AccessBackdrop(),
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
                                horizontal: wide
                                    ? AppSpacing.xxl
                                    : AppSpacing.md,
                                vertical: wide ? AppSpacing.xxl : AppSpacing.lg,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 440,
                                  ),
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
                                        padding: EdgeInsets.all(
                                          wide ? AppSpacing.xl : AppSpacing.lg,
                                        ),
                                        child: _buildForm(context),
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
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final helpStyle = textTheme.bodySmall?.copyWith(height: 1.6);
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
          style: textTheme.labelSmall?.copyWith(color: accessColor),
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
          style: textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
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
          _ReaderVisual(color: accessColor),
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
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: accessColor),
            onPressed: loading
                ? null
                : credentialMode
                ? _loginCredentials
                : _identify,
            child: AnimatedSwitcher(
              duration: AppMotion.medium,
              child: loading
                  ? const Row(
                      key: ValueKey('access-loading'),
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
                        SizedBox(width: AppSpacing.sm),
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
        ),
        const SizedBox(height: AppSpacing.lg),
        const _OrDivider(),
        const SizedBox(height: AppSpacing.lg),
        if (adminMode) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('professor-password-access'),
              style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
              onPressed: loading ? null : () => context.go('/professor/login'),
              icon: const Icon(Icons.school_outlined),
              label: const Text('Entrar como professor'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (credentialMode)
          _BadgePrompt(onTap: loading ? null : () => context.go('/login'))
        else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('professor-password-access'),
              style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
              onPressed: loading ? null : () => context.go('/professor/login'),
              icon: const Icon(Icons.person_outline),
              label: const Text('Entrar com usuário e senha'),
            ),
          ),
        if (!adminMode) ...[
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: TextButton(
              onPressed: loading ? null : () => context.go('/admin/login'),
              child: const Text('Acesso administrativo'),
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
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider(height: 1, color: AppTheme.borderStrong)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Text('ou', style: Theme.of(context).textTheme.bodySmall),
      ),
      const Expanded(child: Divider(height: 1, color: AppTheme.borderStrong)),
    ],
  );
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
        color: Color.alphaBlend(color.withValues(alpha: .04), Colors.white),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppTheme.border),
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
                    (88.0, .08),
                    (66.0, .14),
                    (44.0, .22),
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

class _BadgePrompt extends StatefulWidget {
  const _BadgePrompt({required this.onTap});
  final VoidCallback? onTap;

  @override
  State<_BadgePrompt> createState() => _BadgePromptState();
}

class _BadgePromptState extends State<_BadgePrompt> {
  bool hovered = false;
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;
    final active = hovered || focused;
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.curve,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: active ? .08 : .04),
          Colors.white,
        ),
        borderRadius: AppRadius.card,
        border: Border.all(
          color: active ? accent.withValues(alpha: .6) : AppTheme.border,
        ),
        boxShadow: focused
            ? [BoxShadow(color: accent.withValues(alpha: .28), spreadRadius: 3)]
            : const [],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const Key('badge-access'),
          onTap: widget.onTap,
          onHover: (value) => setState(() => hovered = value),
          onFocusChange: (value) => setState(() => focused = value),
          borderRadius: AppRadius.card,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(Icons.contactless_outlined, color: accent),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Passe o crachá', style: textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Acesso para professores pelo leitor.',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                ExcludeSemantics(
                  child: AnimatedSlide(
                    duration: AppMotion.fast,
                    curve: AppMotion.curve,
                    offset: active ? const Offset(.2, 0) : Offset.zero,
                    child: Icon(
                      Icons.arrow_forward_outlined,
                      color: accent,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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

/// Full-bleed decoration: soft glows and thin concentric arcs that evoke the
/// contactless reader. Every shape stays within [AppTheme.backdropGlowOpacity].
class _AccessBackdrop extends CustomPainter {
  const _AccessBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    const glow = AppTheme.backdropGlowOpacity;
    void radial(Offset center, double radius) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: glow),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    final shortest = size.shortestSide;
    radial(Offset(size.width * .82, size.height * .08), shortest * .7);
    radial(Offset(size.width * .1, size.height * .95), shortest * .55);

    final arcs = Paint()
      ..color = Colors.white.withValues(alpha: glow * .8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final origin = Offset(size.width * .04, size.height * 1.02);
    for (var index = 1; index <= 7; index++) {
      canvas.drawCircle(origin, shortest * .14 * index, arcs);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AccessBackdrop oldDelegate) => false;
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
        opacity: AppTheme.backdropGlowOpacity,
        fallbackOpacity: AppTheme.backdropGlowOpacity,
        borderColor: Colors.white.withValues(alpha: .18),
        borderRadius: AppRadius.card,
        shadows: const [],
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
