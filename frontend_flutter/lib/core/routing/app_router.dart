import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/agenda/agenda_page.dart';
import '../../features/alerts/admin_alerts_page.dart';
import '../../features/auth/auth_page.dart';
import '../../features/home/home_page.dart';
import '../../features/home/teacher_home_page.dart';
import '../../features/movements/checkout_page.dart';
import '../../features/movements/returns_page.dart';
import '../../features/records/history_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/shell/app_shell.dart';
import '../../features/tablets/tablets_page.dart';
import '../../features/teachers/teachers_page.dart';
import '../../features/totem/totem_page.dart';
import '../../services/app_controller.dart';

GoRouter createAppRouter(AppController controller) => GoRouter(
  initialLocation: '/login',
  refreshListenable: controller,
  redirect: (context, state) {
    final onLogin = state.matchedLocation == '/login';
    if (!controller.hasIdentity && !onLogin) return '/login';
    if (controller.hasIdentity && onLogin) return '/home';
    // The backend remains the authority: this is a second, UX-level guard.
    if (controller.hasIdentity &&
        !controller.canAccessRoute(state.matchedLocation)) {
      return '/home';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => AuthPage(controller: controller),
    ),
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(controller: controller, child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => controller.isAdmin
              ? HomePage(controller: controller)
              : TeacherHomePage(controller: controller),
        ),
        GoRoute(
          path: '/agenda',
          builder: (context, state) => AgendaPage(controller: controller),
        ),
        GoRoute(
          path: '/movements',
          builder: (context, state) => CheckoutPage(controller: controller),
        ),
        GoRoute(
          path: '/returns',
          builder: (context, state) => ReturnsPage(controller: controller),
        ),
        GoRoute(
          path: '/teachers',
          builder: (context, state) => TeachersPage(controller: controller),
        ),
        GoRoute(
          path: '/tablets',
          builder: (context, state) => TabletsPage(controller: controller),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => HistoryPage(controller: controller),
        ),
        GoRoute(
          path: '/alerts',
          builder: (context, state) => AdminAlertsPage(controller: controller),
        ),
        GoRoute(
          path: '/totem',
          builder: (context, state) => TotemPage(controller: controller),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => SettingsPage(controller: controller),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Página não encontrada: ${state.error}')),
  ),
);
