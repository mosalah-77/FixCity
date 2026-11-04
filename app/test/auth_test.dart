import 'dart:async';
import 'dart:convert';

import 'package:fixcity/admin/admin_login_page.dart';
import 'package:fixcity/governor/governor_login_page.dart';
import 'package:fixcity/login_page.dart';
import 'package:fixcity/main.dart';
import 'package:fixcity/signup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => appLocale.value = const Locale('en'));
  tearDown(() async => Supabase.instance.dispose());

  for (final entry in <String, Widget>{
    'citizen': const LoginPage(),
    'admin': const AdminLoginPage(),
    'district': const GovernorLoginPage(),
  }.entries) {
    testWidgets('${entry.key} login preserves password whitespace', (
      tester,
    ) async {
      String? sentPassword;
      await initializeBackend((request) {
        if (request.url.path == '/auth/v1/token') {
          sentPassword = jsonDecode(request.body)['password'] as String;
          return jsonResponse({'msg': 'Invalid login credentials'}, 400);
        }
        return unexpectedRequest(request);
      });
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: entry.value));
      await tester.enterText(
        find.byType(TextField).at(0),
        'citizen@example.test',
      );
      await tester.enterText(
        find.byType(TextField).at(1),
        '  deliberate spaces  ',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(sentPassword, '  deliberate spaces  ');
    });
  }

  testWidgets(
    'signup awaiting email verification succeeds without a profile write',
    (tester) async {
      Map<String, dynamic>? signup;
      var profileWrites = 0;
      await initializeBackend((request) {
        if (request.url.path == '/auth/v1/signup') {
          signup = jsonDecode(request.body) as Map<String, dynamic>;
          return jsonResponse(testUser());
        }
        if (request.url.path == '/rest/v1/profiles') {
          profileWrites++;
          return jsonResponse({
            'message': 'No authenticated session',
            'code': '42501',
          }, 403);
        }
        return unexpectedRequest(request);
      });
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: const SignupPage(),
          routes: {
            '/login': (_) =>
                const Scaffold(body: Text('verification complete')),
          },
        ),
      );
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Demo Citizen');
      await tester.enterText(fields.at(1), '01000000000');
      await tester.enterText(fields.at(2), 'citizen@example.test');
      await tester.enterText(fields.at(3), '  deliberate spaces  ');
      await tester.ensureVisible(find.byType(FixGreenButton));
      await tester.tap(find.byType(FixGreenButton));
      await tester.pumpAndSettle();
      expect(find.text('verification complete'), findsOneWidget);
      expect(profileWrites, 0);
      expect(signup?['password'], '  deliberate spaces  ');
      expect(signup?['data'], {
        'full_name': 'Demo Citizen',
        'phone': '01000000000',
      });
    },
  );

  testWidgets(
    'admin auth failure after leaving page does not update disposed state',
    (tester) async {
      final response = Completer<http.Response>();
      var authStarted = false;
      await initializeBackend((request) {
        if (request.url.path == '/auth/v1/token') {
          authStarted = true;
          return response.future;
        }
        return unexpectedRequest(request);
      });
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: AdminLoginPage()));
      await tester.enterText(
        find.byType(TextField).at(0),
        'staff@example.test',
      );
      await tester.enterText(find.byType(TextField).at(1), 'password');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(authStarted, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      response.complete(
        jsonResponse({'msg': 'Invalid login credentials'}, 400),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
