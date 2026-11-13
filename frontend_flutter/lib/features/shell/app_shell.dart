import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../services/app_controller.dart';
import '../../services/system_api.dart';
import '../../widgets/common_widgets.dart';
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
    _NavItem('Início', Icons.space_dashboard_outlined, '/home', 'ACOMPANHAR'),
    _NavItem(
      'Alertas',
      Icons.notifications_active_outlined,
      '/alerts',
      'ACOMPANHAR',
    ),
    _NavItem(
      'Devoluções',
      Icons.assignment_return_outlined,
      '/returns',
      'GERENCIAR',
    ),
    _NavItem('Professores', Icons.badge_outlined, '/teachers', 'GERENCIAR'),
    _NavItem('Tablets', Icons.tablet_mac_outlined, '/tablets', 'GERENCIAR'),
    _NavItem(
      'Relatórios',
      Icons.receipt_long_outlined,
      '/history',
      'CONSULTAR',
    ),
    _NavItem('Agenda', Icons.calendar_month_outlined, '/agenda', 'CONSULTAR'),
    _NavItem('Configurações', Icons.settings_outlined, '/settings', 'SISTEMA'),
  ];
  static const _teacherItems = [
    _NavItem('Início', Icons.home_outlined, '/home', 'MEU ATENDIMENTO'),
    _NavItem('Totem', Icons.touch_app_outlined, '/totem', 'MEU ATENDIMENTO'),
    _NavItem(
      'Retirar tablets',
      Icons.output_outlined,
      '/movements',
      'MEU ATENDIMENTO',
    ),
    _NavItem(
      'Devolver tablets',
      Icons.assignment_return_outlined,
      '/returns',
      'MEU ATENDIMENTO',
    ),
    _NavItem(
      'Meu histórico',
      Icons.receipt_long_outlined,
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
            final desktop =
                constraints.maxWidth >= 1180 &&
                MediaQuery.textScalerOf(context).scale(1) <= 1.3;
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
            return Scaffold(
              key: scaffoldKey,
              drawer: desktop ? null : Drawer(child: SafeArea(child: sidebar)),
              bottomNavigationBar:
                  !desktop && !admin && _mobilePaths.contains(path)
                  ? NavigationBar(
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
                          label: 'Retirar',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.assignment_return_outlined),
                          label: 'Devolver',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.history),
                          label: 'Histórico',
                        ),
                      ],
                    )
                  : null,
              body: SafeArea(
                child: Column(
                  children: [
                    if (desktop)
                      _PortalNavigation(
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
                    else
                      _TopBar(
                        compact: true,
                        admin: admin,
                        title: items[selectedIndex].title,
                        api: widget.controller.api,
                        searchController: searchController,
                        onSearch: search,
                        onMenu: () => scaffoldKey.currentState?.openDrawer(),
                        onLogout: _signOut,
                      ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1360),
                          child: SingleChildScrollView(
                            key: PageStorageKey('page-$path'),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: EdgeInsets.all(desktop ? 32 : 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: widget.child,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) => ColoredBox(
    color: AppTheme.headerFor(admin),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1440),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              const SizedBox(
                width: 148,
                child: BrandMark(inverted: true, compact: true),
              ),
              const SizedBox(width: 20),
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Semantics(
                      selected: selectedIndex == index,
                      child: Material(
                        color: selectedIndex == index
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: ValueKey('portal-nav-${items[index].path}'),
                          onTap: () => onSelect(index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 4,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  items[index].icon,
                                  size: 21,
                                  color: selectedIndex == index
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  items[index].title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: selectedIndex == index
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.white,
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
              const SizedBox(width: 12),
              IconButton(
                onPressed: onSearch,
                tooltip: 'Pesquisar histórico',
                icon: const Icon(Icons.search, color: Colors.white),
              ),
              _ApiStatusIndicator(compact: true, api: api, inverted: true),
              if (admin)
                IconButton(
                  onPressed: () => context.go('/alerts'),
                  tooltip: 'Central de alertas',
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                  ),
                ),
              PopupMenuButton<String>(
                tooltip: 'Conta de $name',
                icon: const Icon(
                  Icons.account_circle_outlined,
                  color: Colors.white,
                  size: 30,
                ),
                onSelected: (value) {
                  if (value == 'logout') onLogout();
                  if (value == 'settings' && admin) context.go('/settings');
                },
                itemBuilder: (context) => [
                  if (admin)
                    const PopupMenuItem(
                      value: 'settings',
                      child: Text('Configurações'),
                    ),
                  const PopupMenuItem(value: 'logout', child: Text('Sair')),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.compact,
    required this.admin,
    required this.title,
    required this.api,
    required this.searchController,
    required this.onSearch,
    required this.onMenu,
    required this.onLogout,
  });
  final bool compact;
  final bool admin;
  final String title;
  final SystemApi api;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final VoidCallback onMenu;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 80),
    padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 28, vertical: 8),
    decoration: BoxDecoration(color: AppTheme.headerFor(admin)),
    child: Row(
      children: [
        if (compact)
          IconButton(
            onPressed: onMenu,
            icon: const Icon(Icons.menu, color: Colors.white),
            tooltip: 'Abrir menu',
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: Colors.white),
              ),
              Text(
                admin ? 'Área administrativa' : 'Área do professor',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        if (!compact) ...[
          SizedBox(
            width: 260,
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: onSearch,
              decoration: const InputDecoration(
                hintText: 'Pesquisar histórico',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        _ApiStatusIndicator(compact: compact, api: api, inverted: true),
        if (admin)
          IconButton(
            tooltip: 'Central de alertas',
            onPressed: () => context.go('/alerts'),
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
        PopupMenuButton<String>(
          tooltip: 'Conta',
          icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
          onSelected: (value) {
            if (value == 'logout') onLogout();
            if (value == 'settings' && admin) context.go('/settings');
          },
          itemBuilder: (context) => [
            if (admin)
              const PopupMenuItem(
                value: 'settings',
                child: Text('Configurações'),
              ),
            const PopupMenuItem(value: 'logout', child: Text('Sair')),
          ],
        ),
      ],
    ),
  );
}

class _ApiStatusIndicator extends StatefulWidget {
  const _ApiStatusIndicator({
    required this.compact,
    required this.api,
    this.inverted = false,
  });
  final bool inverted;
  final bool compact;
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
      void refresh() => setState(() => connected = _check());
      return widget.compact
          ? IconButton(
              tooltip: '$label. Verificar conexão',
              onPressed: refresh,
              icon: Icon(
                snapshot.data == false ? Icons.wifi_off : Icons.wifi,
                color: widget.inverted ? Colors.white : color,
                size: 20,
              ),
            )
          : TextButton(
              onPressed: refresh,
              child: StatusPill(label, color: color),
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
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.primary,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 28, 20, 24),
          child: BrandMark(inverted: true),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final selected = index == selectedIndex;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (index == 0 || item.group != items[index - 1].group)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 18, 8, 8),
                      child: Text(
                        item.group,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .8,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      selected: selected,
                      selectedTileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: Icon(
                        item.icon,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                        size: 22,
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white,
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
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white24)),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_circle_outlined, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      role,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onLogout,
                tooltip: 'Sair',
                icon: const Icon(Icons.logout, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _NavItem {
  const _NavItem(this.title, this.icon, this.path, this.group);
  final String title;
  final IconData icon;
  final String path;
  final String group;
}
