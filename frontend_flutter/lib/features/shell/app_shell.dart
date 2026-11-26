import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_surface.dart';
import '../../services/app_controller.dart';
import '../../services/system_api.dart';
import 'brand_mark.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.controller, required this.child, super.key});
  final AppController controller;
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final searchController = TextEditingController();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  static const _adminItems = [
    _NavItem(
      'Início',
      Icons.space_dashboard_outlined,
      Icons.space_dashboard,
      '/home',
      'ACOMPANHAR',
    ),
    _NavItem(
      'Alertas',
      Icons.notifications_active_outlined,
      Icons.notifications_active,
      '/alerts',
      'ACOMPANHAR',
    ),
    _NavItem(
      'Devoluções',
      Icons.assignment_return_outlined,
      Icons.assignment_return,
      '/returns',
      'GERENCIAR',
    ),
    _NavItem(
      'Professores',
      Icons.badge_outlined,
      Icons.badge,
      '/teachers',
      'GERENCIAR',
    ),
    _NavItem(
      'Tablets',
      Icons.tablet_mac_outlined,
      Icons.tablet_mac,
      '/tablets',
      'GERENCIAR',
    ),
    _NavItem(
      'Relatórios',
      Icons.receipt_long_outlined,
      Icons.receipt_long,
      '/history',
      'CONSULTAR',
    ),
    _NavItem(
      'Agenda',
      Icons.calendar_month_outlined,
      Icons.calendar_month,
      '/agenda',
      'CONSULTAR',
    ),
    _NavItem(
      'Configurações',
      Icons.settings_outlined,
      Icons.settings,
      '/settings',
      'SISTEMA',
    ),
  ];
  static const _teacherItems = [
    _NavItem(
      'Início',
      Icons.home_outlined,
      Icons.home,
      '/home',
      'MEU ATENDIMENTO',
    ),
    _NavItem(
      'Totem',
      Icons.touch_app_outlined,
      Icons.touch_app,
      '/totem',
      'MEU ATENDIMENTO',
    ),
    _NavItem(
      'Retirar tablets',
      Icons.output_outlined,
      Icons.output,
      '/movements',
      'MEU ATENDIMENTO',
    ),
    _NavItem(
      'Devolver tablets',
      Icons.assignment_return_outlined,
      Icons.assignment_return,
      '/returns',
      'MEU ATENDIMENTO',
    ),
    _NavItem(
      'Meu histórico',
      Icons.receipt_long_outlined,
      Icons.receipt_long,
      '/history',
      'MEU ATENDIMENTO',
    ),
  ];
  static const _mobilePaths = ['/home', '/movements', '/returns', '/history'];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _signOut() {
    final login = widget.controller.isAdmin
        ? '/admin/login'
        : widget.controller.badgeUid == null
        ? '/professor/login'
        : '/login';
    widget.controller.signOut();
    context.go(login);
  }

  @override
  Widget build(BuildContext context) {
    final admin = widget.controller.isAdmin;
    final items = admin ? _adminItems : _teacherItems;
    final path = GoRouterState.of(context).uri.path;
    final selectedIndex = items
        .indexWhere((item) => item.path == path)
        .clamp(0, items.length - 1);
    return Theme(
      data: admin ? AppTheme.light : AppTheme.teacher,
      child: Builder(
        builder: (context) => LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final desktop = constraints.maxWidth >= 1180 && textScale <= 1.3;
            void select(int index) {
              if (!desktop) scaffoldKey.currentState?.closeDrawer();
              context.go(items[index].path);
            }

            void search(String query) {
              widget.controller.searchQuery = query;
              context.go('/history');
            }

            final sidebar = _Sidebar(
              items: items,
              selectedIndex: selectedIndex,
              role: admin ? 'Administrador' : 'Professor',
              name: widget.controller.displayName,
              onSelect: select,
              onLogout: _signOut,
            );
            // The bar grows with the text scale so titles never clip.
            final barHeight = desktop
                ? 72.0
                : (AppSpacing.lg + 40 * textScale).clamp(64.0, 180.0);
            return Scaffold(
              key: scaffoldKey,
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(barHeight),
                child: desktop
                    ? _PortalNavigation(
                        admin: admin,
                        items: items,
                        selectedIndex: selectedIndex,
                        api: widget.controller.api,
                        name: widget.controller.displayName,
                        onSelect: select,
                        onLogout: _signOut,
                        onSearch: () => showDialog<void>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Pesquisar histórico'),
                            content: TextField(
                              controller: searchController,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              decoration: const InputDecoration(
                                labelText: 'Termo de pesquisa',
                              ),
                              onSubmitted: (query) {
                                Navigator.of(dialogContext).pop();
                                search(query);
                              },
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                  search(searchController.text);
                                },
                                child: const Text('Pesquisar'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _TopBar(
                        admin: admin,
                        title: items[selectedIndex].title,
                        api: widget.controller.api,
                        onMenu: () => scaffoldKey.currentState?.openDrawer(),
                        onLogout: _signOut,
                      ),
              ),
              drawer: desktop
                  ? null
                  : Drawer(
                      backgroundColor: Colors.white,
                      surfaceTintColor: Colors.transparent,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(AppRadius.lg),
                        ),
                      ),
                      child: SafeArea(child: sidebar),
                    ),
              bottomNavigationBar:
                  !desktop && !admin && _mobilePaths.contains(path)
                  ? DecoratedBox(
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppTheme.border)),
                      ),
                      child: NavigationBar(
                        selectedIndex: _mobilePaths.indexOf(path).clamp(0, 3),
                        onDestinationSelected: (index) =>
                            context.go(_mobilePaths[index]),
                        destinations: const [
                          NavigationDestination(
                            icon: Icon(Icons.home_outlined),
                            selectedIcon: Icon(Icons.home),
                            label: 'Início',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.output_outlined),
                            selectedIcon: Icon(Icons.output),
                            label: 'Retirar',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.assignment_return_outlined),
                            selectedIcon: Icon(Icons.assignment_return),
                            label: 'Devolver',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.history_outlined),
                            selectedIcon: Icon(Icons.history),
                            label: 'Histórico',
                          ),
                        ],
                      ),
                    )
                  : null,
              // The viewport starts below the bar (focus, ensureVisible and taps
              // stay correct); Clip.none keeps scrolled content painted under
              // the translucent bar so the glass blurs it.
              body: Builder(
                builder: (context) {
                  final gutter = desktop ? AppSpacing.xl : AppSpacing.md;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1360),
                      child: SingleChildScrollView(
                        key: PageStorageKey('page-$path'),
                        clipBehavior: Clip.none,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.all(gutter),
                        child: SizedBox(
                          width: double.infinity,
                          child: widget.child,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Light glass bar shared by desktop and mobile headers.
class _GlassBar extends StatelessWidget {
  const _GlassBar({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => GlassSurface(
    borderRadius: BorderRadius.zero,
    borderColor: Colors.transparent,
    shadows: const [],
    child: DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(bottom: false, child: child),
    ),
  );
}

class _PortalNavigation extends StatelessWidget {
  const _PortalNavigation({
    required this.admin,
    required this.items,
    required this.selectedIndex,
    required this.api,
    required this.name,
    required this.onSelect,
    required this.onLogout,
    required this.onSearch,
  });
  final bool admin;
  final List<_NavItem> items;
  final int selectedIndex;
  final SystemApi api;
  final String name;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => _GlassBar(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1440),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              const BrandMark(compact: true, tagline: false),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Narrow desktops keep the icon only on the active item.
                    final showIcons = constraints.maxWidth >= 900;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var index = 0; index < items.length; index++)
                            _NavButton(
                              item: items[index],
                              selected: index == selectedIndex,
                              showIcon: showIcons,
                              onTap: () => onSelect(index),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: onSearch,
                tooltip: 'Pesquisar histórico',
                color: AppTheme.muted,
                icon: const Icon(Icons.search_outlined),
              ),
              _ApiStatusIndicator(api: api),
              if (admin)
                IconButton(
                  onPressed: () => context.go('/alerts'),
                  tooltip: 'Central de alertas',
                  color: AppTheme.muted,
                  icon: const Icon(Icons.notifications_outlined),
                ),
              _AccountMenu(
                tooltip: 'Conta de $name',
                name: name,
                admin: admin,
                onLogout: onLogout,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.showIcon,
    required this.onTap,
  });
  final _NavItem item;
  final bool selected;
  final bool showIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected ? scheme.primary : AppTheme.text;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Semantics(
        selected: selected,
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.curve,
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : Colors.transparent,
            borderRadius: AppRadius.control,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: ValueKey('portal-nav-${item.path}'),
              onTap: onTap,
              borderRadius: AppRadius.control,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected || showIcon) ...[
                        Icon(
                          selected ? item.selectedIcon : item.icon,
                          size: 18,
                          color: selected ? scheme.primary : AppTheme.muted,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
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
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.admin,
    required this.title,
    required this.api,
    required this.onMenu,
    required this.onLogout,
  });
  final bool admin;
  final String title;
  final SystemApi api;
  final VoidCallback onMenu;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => _GlassBar(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenu,
            color: AppTheme.text,
            icon: const Icon(Icons.menu_outlined),
            tooltip: 'Abrir menu',
          ),
          const SizedBox(width: AppSpacing.xxs),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  admin ? 'Área administrativa' : 'Área do professor',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          _ApiStatusIndicator(api: api),
          if (admin)
            IconButton(
              tooltip: 'Central de alertas',
              color: AppTheme.muted,
              onPressed: () => context.go('/alerts'),
              icon: const Icon(Icons.notifications_outlined),
            ),
          _AccountMenu(
            tooltip: 'Conta',
            name: null,
            admin: admin,
            onLogout: onLogout,
          ),
        ],
      ),
    ),
  );
}

/// Account button: initials avatar on desktop, generic icon on mobile.
class _AccountMenu extends StatelessWidget {
  const _AccountMenu({
    required this.tooltip,
    required this.name,
    required this.admin,
    required this.onLogout,
  });
  final String tooltip;
  final String? name;
  final bool admin;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: tooltip,
    icon: name == null
        ? const Icon(Icons.account_circle_outlined, color: AppTheme.muted)
        : _Initials(name!),
    onSelected: (value) {
      if (value == 'logout') onLogout();
      if (value == 'settings' && admin) context.go('/settings');
    },
    itemBuilder: (context) => [
      if (admin)
        const PopupMenuItem(value: 'settings', child: Text('Configurações')),
      const PopupMenuItem(value: 'logout', child: Text('Sair')),
    ],
  );
}

class _Initials extends StatelessWidget {
  const _Initials(this.name);
  final String name;

  @override
  Widget build(BuildContext context) {
    final words = name
        .split(RegExp(r'\s+'))
        .where(
          (word) =>
              word.isNotEmpty &&
              RegExp(r'^\p{L}', unicode: true).hasMatch(word),
        )
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: 16,
        backgroundColor: scheme.primaryContainer,
        child: Text(
          words.isEmpty ? '?' : words,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ApiStatusIndicator extends StatefulWidget {
  const _ApiStatusIndicator({required this.api});
  final SystemApi api;
  @override
  State<_ApiStatusIndicator> createState() => _ApiStatusIndicatorState();
}

class _ApiStatusIndicatorState extends State<_ApiStatusIndicator> {
  late Future<bool> connected;
  @override
  void initState() {
    super.initState();
    connected = _check();
  }

  Future<bool> _check() async {
    try {
      await widget.api.health();
      return true;
    } on ApiException {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: connected,
    builder: (context, snapshot) {
      final color = !snapshot.hasData
          ? AppTheme.warning
          : snapshot.data!
          ? AppTheme.success
          : AppTheme.danger;
      final label = !snapshot.hasData
          ? 'Verificando conexão'
          : snapshot.data!
          ? 'Sistema disponível'
          : 'Sistema indisponível';
      return IconButton(
        tooltip: '$label. Verificar conexão',
        onPressed: () => setState(() => connected = _check()),
        icon: Icon(
          snapshot.data == false
              ? Icons.wifi_off_outlined
              : Icons.wifi_outlined,
          color: color,
          size: 20,
        ),
      );
    },
  );
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
    required this.name,
    required this.role,
  });
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: Align(alignment: Alignment.centerLeft, child: BrandMark()),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final selected = index == selectedIndex;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (index == 0 || item.group != items[index - 1].group)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.xs,
                      ),
                      child: Text(
                        item.group,
                        style: textTheme.labelSmall?.copyWith(
                          color: AppTheme.muted,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: ListTile(
                      selected: selected,
                      selectedTileColor: scheme.primaryContainer,
                      selectedColor: scheme.primary,
                      iconColor: AppTheme.muted,
                      textColor: AppTheme.text,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.control,
                      ),
                      leading: Icon(
                        selected ? item.selectedIcon : item.icon,
                        size: 22,
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      onTap: () => onSelect(index),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppTheme.border)),
          ),
          child: Row(
            children: [
              _Initials(name),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall,
                    ),
                    Text(role, style: textTheme.bodySmall),
                  ],
                ),
              ),
              IconButton(
                onPressed: onLogout,
                tooltip: 'Sair',
                color: AppTheme.muted,
                icon: const Icon(Icons.logout_outlined),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavItem {
  const _NavItem(
    this.title,
    this.icon,
    this.selectedIcon,
    this.path,
    this.group,
  );
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
  final String group;
}
