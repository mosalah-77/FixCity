import 'dart:convert';
import 'package:fixcity/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'support/backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'replacing a demo identity clears the old profile navigation stack',
    (tester) async {
      appLocale.value = const Locale('en');
      var signups = 0, starts = 0;
      const secondId = '22222222-2222-4222-8222-222222222222';
      await initializeBackend((request) {
        if (request.url.path == '/auth/v1/signup') {
          signups++;
          final body =
              jsonDecode(sessionResponse(anonymous: true).body)
                  as Map<String, dynamic>;
          if (signups == 2) {
            body['user']['id'] = secondId;
            final payload = base64Url
                .encode(
                  utf8.encode(
                    jsonEncode({
                      'sub': secondId,
                      'exp': 4102444800,
                      'role': 'authenticated',
                    }),
                  ),
                )
                .replaceAll('=', '');
            body['access_token'] = 'eyJhbGciOiJIUzI1NiJ9.$payload.test';
          }
          return jsonResponse(body);
        }
        if (request.url.path == '/auth/v1/logout') return jsonResponse(null);
        if (request.url.path == '/rest/v1/rpc/start_demo') {
          starts++;
          if (starts == 2)
            return jsonResponse({
              'code': '08006',
              'message': 'Temporary connection failure',
            }, 503);
          return jsonResponse('33333333-3333-4333-8333-333333333333');
        }
        if (request.url.path == '/rest/v1/profiles')
          return jsonResponse({
            'full_name': signups == 1
                ? 'PRIVATE PROFILE FROM SESSION A'
                : 'Session B',
            'phone': 'SYNTHETIC A PHONE',
            'points': 30,
          });
        if (request.url.path == '/rest/v1/reports') return jsonResponse([]);
        return unexpectedRequest(request);
      });
      addTearDown(() async => Supabase.instance.dispose());
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await Supabase.instance.client.auth.signInAnonymously();
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      appNavigatorKey.currentState!.pushNamed('/profile');
      await tester.pumpAndSettle();
      expect(find.text('PRIVATE PROFILE FROM SESSION A'), findsWidgets);
      await tester.tap(find.byIcon(Icons.logout_outlined));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Start a new session'), 200);
      await tester.tap(find.text('Start a new session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New session'));
      await tester.pumpAndSettle();
      expect(Supabase.instance.client.auth.currentUser!.id, secondId);
      expect(appNavigatorKey.currentState!.canPop(), isFalse);
      expect(find.text('PRIVATE PROFILE FROM SESSION A'), findsNothing);
      expect(find.text('30 Points'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
    skip: !const bool.fromEnvironment('DEMO_MODE'),
  );
}
