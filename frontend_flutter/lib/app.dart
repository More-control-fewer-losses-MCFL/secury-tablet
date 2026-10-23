import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/app_controller.dart';
import 'services/system_api.dart';

class SystemApp extends StatefulWidget {
  const SystemApp({required this.api, super.key});

  final SystemApi api;

  @override
  State<SystemApp> createState() => _SystemAppState();
}

class _SystemAppState extends State<SystemApp> {
  late final AppController controller;
  late final GoRouter router;

  @override
  void initState() {
    super.initState();
    controller = AppController(widget.api);
    router = createAppRouter(controller);
  }

  @override
  void dispose() {
    router.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Tablet de Segurança',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    routerConfig: router,
  );
}
