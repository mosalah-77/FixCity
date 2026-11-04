import 'dart:async';
import 'package:fixcity/main.dart';
import 'package:fixcity/profile_page.dart';
import 'package:fixcity/governor/governor_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'support/backend.dart';

Future<void> signIn() async => Supabase.instance.client.auth.signInWithPassword(
  email: 'citizen@example.test',
  password: 'test-password',
);
Future<void> openProfile(WidgetTester tester) async {
  tester.view.physicalSize = const Size(600, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await signIn();
  await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Name'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), 'Changed name');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => appLocale.value = const Locale('en'));
  tearDown(() async => Supabase.instance.dispose());
  testWidgets('editing a profile uses only a permitted update, not an insert', (
    tester,
  ) async {
    final mutations = <String>[];
    await initializeBackend((request) {
      if (request.url.path == '/auth/v1/token') return sessionResponse();
      if (request.url.path == '/rest/v1/profiles' && request.method == 'GET')
        return jsonResponse({
          'full_name': 'Original',
          'phone': '',
          'points': 0,
        });
      if (request.url.path == '/rest/v1/reports') return jsonResponse([]);
      mutations.add(request.method);
      return request.method == 'PATCH'
          ? jsonResponse(null)
          : unexpectedRequest(request);
    });
    await openProfile(tester);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(mutations, ['PATCH']);
    expect(find.text('Changed name'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'leaving a profile during a save does not update disposed state',
    (tester) async {
      final response = Completer<http.Response>();
      await initializeBackend((request) {
        if (request.url.path == '/auth/v1/token') return sessionResponse();
        if (request.url.path == '/rest/v1/profiles' && request.method == 'GET')
          return jsonResponse({
            'full_name': 'Original',
            'phone': '',
            'points': 0,
          });
        if (request.url.path == '/rest/v1/reports') return jsonResponse([]);
        return response.future;
      });
      await openProfile(tester);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const MaterialApp(home: Text('Elsewhere')));
      response.complete(jsonResponse(null));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'district profile failure offers retry instead of an endless spinner',
    (tester) async {
      await initializeBackend(
        (request) => request.url.path == '/auth/v1/token'
            ? sessionResponse()
            : jsonResponse({'code': '08006', 'message': 'Offline'}, 503),
      );
      await signIn();
      await tester.pumpWidget(const MaterialApp(home: GovernorDashboardPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
