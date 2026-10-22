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

  static const _items = [
    _NavItem('Início', Icons.home_outlined, '/home'),
    _NavItem('Agenda', Icons.calendar_month_outlined, '/agenda'),
    _NavItem('Retirada', Icons.output_outlined, '/movements'),
    _NavItem('Devolução', Icons.assignment_return_outlined, '/returns'),
    _NavItem('Professores', Icons.badge_outlined, '/teachers'),
    _NavItem('Tablets', Icons.tablet_mac_outlined, '/tablets'),
    _NavItem('Histórico e relatórios', Icons.receipt_long_outlined, '/history'),
    _NavItem('Configurações', Icons.settings_outlined, '/settings'),
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final selectedIndex = _items
        .indexWhere((item) => item.path == path)
        .clamp(0, _items.length - 1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 980;
        final sidebar = _Sidebar(
          items: _items,
          selectedIndex: selectedIndex,
          onSelect: (index) => context.go(_items[index].path),
          onLogout: () {
            widget.controller.signOut();
            context.go('/login');
          },
          name: widget.controller.displayName,
        );
        return Scaffold(
          drawer: desktop ? null : Drawer(child: SafeArea(child: sidebar)),
          body: Row(
            children: [
              if (desktop) SizedBox(width: 238, child: sidebar),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(
                      compact: !desktop,
                      api: widget.controller.api,
                      searchController: searchController,
                      onSearch: (query) {
                        widget.controller.searchQuery = query;
                        context.go('/history');
                      },
                      onMenu: desktop
                          ? null
                          : () => Scaffold.of(context).openDrawer(),
                      onLogout: () {
                        widget.controller.signOut();
                        context.go('/login');
                      },
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1440),
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(desktop ? 28 : 16),
                            child: widget.child,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.compact,
    required this.api,
    required this.searchController,
    required this.onSearch,
    required this.onMenu,
    required this.onLogout,
  });

  final bool compact;
  final SystemApi api;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final VoidCallback? onMenu;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => Container(
    height: 76,
    padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 28),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: AppTheme.border)),
    ),
    child: Row(
      children: [
        if (compact)
          Builder(
            builder: (context) => IconButton(
              onPressed: onMenu,
              icon: const Icon(Icons.menu),
              tooltip: 'Abrir menu',
            ),
          ),
        if (compact) const SizedBox(width: 4),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: onSearch,
              decoration: const InputDecoration(
                hintText: 'Pesquisar movimentações',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _ApiStatusIndicator(compact: compact, api: api),
        if (!compact) ...[
          const SizedBox(width: 8),
          const StatusPill('Leitor não detectável', color: AppTheme.warning),
          const SizedBox(width: 8),
        ],
        IconButton(
          tooltip: 'Notificações',
          onPressed: () => context.go('/history'),
          icon: const Icon(Icons.notifications_none),
        ),
        PopupMenuButton<String>(
          tooltip: 'Conta',
          onSelected: (value) {
            if (value == 'logout') onLogout();
            if (value == 'settings') context.go('/settings');
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'settings', child: Text('Configurações')),
            PopupMenuItem(value: 'logout', child: Text('Sair')),
          ],
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppTheme.paleBlue,
              child: Icon(Icons.person_outline, color: AppTheme.blue, size: 19),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ApiStatusIndicator extends StatefulWidget {
  const _ApiStatusIndicator({required this.compact, required this.api});

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
          ? 'Verificando API'
          : snapshot.data!
          ? 'API conectada'
          : 'API indisponível';
      return Tooltip(
        message: label,
        child: InkWell(
          onTap: () => setState(() => connected = _check()),
          borderRadius: BorderRadius.circular(20),
          child: widget.compact
              ? Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.circle, size: 10, color: color),
                )
              : StatusPill(label, color: color),
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
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  final String name;

  @override
  Widget build(BuildContext context) => Container(
    color: AppTheme.navy,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 22, 16, 24),
          child: BrandMark(inverted: true),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'GESTÃO DE EQUIPAMENTOS',
            style: TextStyle(
              color: Color(0xFFB8D4F5),
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final selected = index == selectedIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    selected: selected,
                    selectedTileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                    leading: Icon(
                      item.icon,
                      color: selected ? AppTheme.blue : Colors.white70,
                      size: 20,
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        color: selected ? AppTheme.blue : Colors.white,
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).maybePop();
                      onSelect(index);
                    },
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 15,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 17, color: AppTheme.blue),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              IconButton(
                onPressed: onLogout,
                tooltip: 'Sair',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.logout, color: Colors.white70, size: 17),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _NavItem {
  const _NavItem(this.title, this.icon, this.path);
  final String title;
  final IconData icon;
  final String path;
}
