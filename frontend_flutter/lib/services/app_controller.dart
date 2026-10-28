import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/system_models.dart';
import 'system_api.dart';

class AppController extends ChangeNotifier {
  AppController(this.api);

  final SystemApi api;
  Professor? professor;
  AdminSession? adminSession;
  Timer? _adminSessionExpiry;
  String? _badgeUid;
  String searchQuery = '';

  bool get hasIdentity => professor != null || adminSession != null;
  String get displayName =>
      adminSession?.username ?? professor?.name ?? 'Usuário';
  String? get badgeUid => _badgeUid;

  Future<Professor> identify(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      throw const FormatException('Aproxime o crachá ou informe o UID.');
    }
    final session = await api.loginTeacher(normalizedUid);
    _adminSessionExpiry?.cancel();
    _adminSessionExpiry = Timer(Duration(seconds: session.expiresIn), signOut);
    adminSession = null;
    professor = session.professor;
    _badgeUid = normalizedUid;
    notifyListeners();
    return session.professor;
  }

  Future<void> loginAdmin(String username, String password) async {
    final session = await api.loginAdmin(username.trim(), password);
    _adminSessionExpiry?.cancel();
    professor = null;
    _badgeUid = null;
    adminSession = session;
    _adminSessionExpiry = Timer(Duration(seconds: session.expiresIn), signOut);
    notifyListeners();
  }

  Future<void> authorizeTerminal(String username, String password) async {
    await api.loginAdmin(username.trim(), password);
    try {
      await api.authorizeTerminal();
    } finally {
      api.clearAdminSession();
    }
  }

  void signOut() {
    _adminSessionExpiry?.cancel();
    _adminSessionExpiry = null;
    api.clearAdminSession();
    professor = null;
    adminSession = null;
    _badgeUid = null;
    searchQuery = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _adminSessionExpiry?.cancel();
    super.dispose();
  }
}
