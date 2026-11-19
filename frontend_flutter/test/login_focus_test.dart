import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/app.dart';
import 'package:frontend_flutter/services/system_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets(
    'professor keeps focus through health updates and keyboard scrolling until Enter',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewInsets();
      });
      final pendingHealth = Completer<http.Response>();
      var healthCalls = 0;
      final submissions = <http.Request>[];
      final api = SystemApi(
        baseUrl: 'http://test.local',
        httpClient: MockClient((request) async {
          if (request.url.path == '/health') {
            healthCalls++;
            if (healthCalls > 1) return pendingHealth.future;
            return http.Response('{"status":"ok","database":"ok"}', 200);
          }
          if (request.url.path == '/auth/professor/login') {
            submissions.add(request);
            return http.Response(
              jsonEncode({'detail': 'Usuário ou senha inválidos.'}),
              401,
            );
          }
          return http.Response('{}', 404);
        }),
      );
      await tester.pumpWidget(SystemApp(api: api));
      await tester.pumpAndSettle();
      final access = find.byKey(const Key('professor-password-access'));
      await tester.ensureVisible(access);
      await tester.tap(access);
      await tester.pumpAndSettle();
      final username = find.byType(TextField).first;
      final password = find.byType(TextField).at(1);
      await tester.ensureVisible(username);
      await tester.tap(username);
      await tester.pump();
      final usernameFocus = tester
          .widget<EditableText>(
            find.descendant(of: username, matching: find.byType(EditableText)),
          )
          .focusNode;
      expect(usernameFocus.hasFocus, isTrue);
      tester.testTextInput.enterText('teacher.');
      await tester.pump();
      pendingHealth.complete(
        http.Response('{"status":"ok","database":"ok"}', 200),
      );
      await tester.pumpAndSettle();
      expect(usernameFocus.hasFocus, isTrue);
      tester.testTextInput.enterText('teacher.ana');
      await tester.pump();
      expect(submissions, isEmpty);
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      final passwordFocus = tester
          .widget<EditableText>(
            find.descendant(of: password, matching: find.byType(EditableText)),
          )
          .focusNode;
      expect(passwordFocus.hasFocus, isTrue);
      tester.testTextInput.enterText('fictional-professor-password');
      await tester.pump();
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView).last,
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();
      expect(passwordFocus.hasFocus, isTrue);
      expect(
        tester.widget<TextField>(password).controller!.text,
        'fictional-professor-password',
      );
      expect(submissions, isEmpty);
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pumpAndSettle();
      expect(submissions, hasLength(1));
      expect(jsonDecode(submissions.single.body), {
        'username': 'teacher.ana',
        'password': 'fictional-professor-password',
      });
      expect(
        tester.widget<TextField>(username).controller!.text,
        'teacher.ana',
      );
      expect(find.byKey(const Key('portal-welcome')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'required fields stay local and password visibility preserves editing',
    (tester) async {
      final posts = <http.Request>[];
      final api = SystemApi(
        baseUrl: 'http://test.local',
        httpClient: MockClient((request) async {
          if (request.method == 'POST') posts.add(request);
          return http.Response('{"status":"ok","database":"ok"}', 200);
        }),
      );
      await _openProfessor(tester, api);
      final user = find.byKey(const Key('access-username'));
      final password = find.byKey(const Key('access-password'));
      await tester.tap(find.text('Acessar'));
      await tester.pumpAndSettle();
      expect(find.text('Informe seu usuário.'), findsOneWidget);
      expect(find.text('Informe sua senha.'), findsOneWidget);
      expect(tester.widget<TextField>(user).focusNode!.hasFocus, isTrue);
      tester.testTextInput.enterText('teacher.ana');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pumpAndSettle();
      expect(find.text('Informe seu usuário.'), findsNothing);
      expect(find.text('Informe sua senha.'), findsOneWidget);
      final field = tester.widget<TextField>(password);
      expect(field.focusNode!.hasFocus, isTrue);
      tester.testTextInput.enterText('fictional-professor-password');
      await tester.pump();
      const selection = TextSelection(baseOffset: 2, extentOffset: 8);
      field.controller!.selection = selection;
      await tester.pump();
      await tester.tap(find.byTooltip('Mostrar senha'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(password).obscureText, isFalse);
      expect(field.focusNode!.hasFocus, isTrue);
      expect(field.controller!.selection, selection);
      await tester.tap(find.byTooltip('Ocultar senha'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(password).obscureText, isTrue);
      expect(field.focusNode!.hasFocus, isTrue);
      expect(field.controller!.selection, selection);
      expect(posts, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'repeated Enter during pending login sends once and preserves input',
    (tester) async {
      final pendingLogin = Completer<http.Response>();
      final submissions = <http.Request>[];
      final api = SystemApi(
        baseUrl: 'http://test.local',
        httpClient: MockClient((request) async {
          if (request.url.path == '/auth/professor/login') {
            submissions.add(request);
            return pendingLogin.future;
          }
          return http.Response('{"status":"ok","database":"ok"}', 200);
        }),
      );
      addTearDown(() {
        if (!pendingLogin.isCompleted) {
          pendingLogin.complete(http.Response('{}', 503));
        }
      });
      await _openProfessor(tester, api);
      final user = find.byKey(const Key('access-username'));
      final password = find.byKey(const Key('access-password'));
      await tester.enterText(user, 'teacher.ana');
      await tester.enterText(password, 'fictional-professor-password');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(submissions, hasLength(1));
      expect(tester.widget<TextField>(password).readOnly, isTrue);
      expect(tester.widget<TextField>(password).focusNode!.hasFocus, isTrue);
      expect(tester.widget<TextField>(user).controller!.text, 'teacher.ana');
      expect(
        tester.widget<TextField>(password).controller!.text,
        'fictional-professor-password',
      );
      pendingLogin.complete(
        http.Response(
          jsonEncode({'detail': 'Usuário ou senha inválidos.'}),
          401,
        ),
      );
      await tester.pumpAndSettle();
      expect(submissions, hasLength(1));
      expect(tester.widget<TextField>(password).readOnly, isFalse);
      expect(
        tester.widget<TextField>(password).controller!.text,
        'fictional-professor-password',
      );
      expect(tester.widget<TextField>(password).focusNode!.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

Future<void> _openProfessor(WidgetTester tester, SystemApi api) async {
  tester.view.physicalSize = const Size(1440, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(SystemApp(api: api));
  await tester.pumpAndSettle();
  final access = find.byKey(const Key('professor-password-access'));
  await tester.ensureVisible(access);
  await tester.tap(access);
  await tester.pumpAndSettle();
}
