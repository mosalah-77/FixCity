import 'dart:async';

import 'package:fixcity/main.dart';
import 'package:fixcity/track_page.dart';
import 'package:fixcity/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/backend.dart';

Map<String, dynamic> report(String code, String title) => {
  'id': '22222222-2222-4222-8222-222222222222',
  'report_code': code, 'title': title, 'category': 'cat_trash',
  'description': 'A synthetic report for testing.', 'photo_url': null,
  'latitude': 30.0, 'longitude': 31.0, 'status': 'pending',
  'created_at': '2026-01-01T00:00:00Z', 'user_id': testUserId,
};

Future<void> openTracking(WidgetTester tester) async {
  tester.view.physicalSize = const Size(600, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const MaterialApp(home: TrackPage()));
}

Future<void> search(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(TextField), code);
  await tester.tap(find.byIcon(Icons.arrow_forward));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => appLocale.value = const Locale('en'));
  tearDown(() async => Supabase.instance.dispose());

  testWidgets('an older search cannot overwrite the latest tracking result', (tester) async {
    final oldResponse = Completer<http.Response>();
    var oldStarted = false;
    var oldWantsArray = false;
    await initializeBackend((request) {
      if (request.url.path == '/rest/v1/reports') {
        if (request.url.queryParameters['report_code'] == 'eq.OLD0000001') {
          oldStarted = true;
          oldWantsArray = request.headers['accept'] == 'application/json';
          return oldResponse.future;
        }
        final row = report('NEW0000002', 'Latest result');
        return jsonResponse(request.headers['accept'] == 'application/json' ? [row] : row);
      }
      if (request.url.path == '/rest/v1/status_updates') return jsonResponse([]);
      return unexpectedRequest(request);
    });
    await openTracking(tester);
    await search(tester, 'OLD0000001');
    expect(oldStarted, isTrue);
    await search(tester, 'NEW0000002');
    await tester.pumpAndSettle();
    expect(find.text('Latest result'), findsOneWidget);
    final old = report('OLD0000001', 'Stale result');
    oldResponse.complete(jsonResponse(oldWantsArray ? [old] : old));
    await tester.pumpAndSettle();
    expect(find.text('Latest result'), findsOneWidget);
    expect(find.text('Stale result'), findsNothing);
  });

  testWidgets('database failure is not reported as an unknown tracking code', (tester) async {
    await initializeBackend((request) => jsonResponse({
      'code': '08006', 'message': 'Database unavailable', 'details': null, 'hint': null,
    }, 503));
    await openTracking(tester);
    await search(tester, 'CODE000001');
    await tester.pumpAndSettle();
    expect(find.text(t('not_found', lang: 'en')), findsNothing);
    expect(find.textContaining('try again'), findsOneWidget);
  });

  testWidgets('an absent report has a clear not-found state', (tester) async {
    await initializeBackend((request) {
      if (request.headers['accept'] == 'application/json') return jsonResponse([]);
      return jsonResponse({'code': 'PGRST116', 'message': 'No rows returned', 'details': 'The result contains 0 rows', 'hint': null}, 406);
    });
    await openTracking(tester);
    await search(tester, 'CODE000001');
    await tester.pumpAndSettle();
    expect(find.text(t('not_found', lang: 'en')), findsOneWidget);
  });
}
