import 'dart:async';

import 'package:fixcity/main.dart';
import 'package:fixcity/demo_page.dart';
import 'package:fixcity/track_page.dart';
import 'package:fixcity/translations.dart';
import 'package:fixcity/report_media.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/backend.dart';

Map<String, dynamic> report(String code, String title) => {
  'id': '22222222-2222-4222-8222-222222222222',
  'report_code': code,
  'title': title,
  'category': 'cat_trash',
  'description': 'A synthetic report for testing.',
  'photo_url': null,
  'latitude': 30.0,
  'longitude': 31.0,
  'status': 'pending',
  'created_at': '2026-01-01T00:00:00Z',
  'user_id': testUserId,
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

  testWidgets('long descriptions wrap inside the desktop demo boundary', (
    tester,
  ) async {
    await initializeBackend((request) {
      if (request.url.path == '/rest/v1/reports') {
        final row = report('LONG', 'Long report')
          ..['description'] = List.filled(
            30,
            'A longer synthetic report description.',
          ).join(' ');
        return jsonResponse(
          request.headers['accept'] == 'application/vnd.pgrst.object+json'
              ? row
              : [row],
        );
      }
      return jsonResponse([]);
    });
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: DemoBanner(child: TrackPage())),
    );
    await search(tester, 'LONG');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('tracking from a narrow report card opens its exact code', (
    tester,
  ) async {
    const code = '71274C974678474BBC2315642096C212';
    var lookedUp = false;
    await initializeBackend((request) {
      if (request.url.path == '/auth/v1/token')
        return sessionResponse(anonymous: true);
      if (request.url.path == '/rest/v1/rpc/start_demo')
        return jsonResponse('22222222-2222-4222-8222-222222222222');
      if (request.url.path == '/rest/v1/profiles')
        return jsonResponse({'points': 30});
      if (request.url.path == '/rest/v1/reports') {
        lookedUp |= request.url.queryParameters['report_code'] == 'eq.$code';
        final row = report(code, 'Selected road report')
          ..['status'] = 'resolved'
          ..['fix_photo_url'] = 'sample:repaired-road';
        return jsonResponse(
          request.headers['accept'] == 'application/vnd.pgrst.object+json'
              ? row
              : [row],
        );
      }
      return jsonResponse([]);
    });
    await Supabase.instance.client.auth.signInWithPassword(
      email: 'test@example.test',
      password: 'test',
    );
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    appNavigatorKey.currentState!.pushNamed('/my_reports');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Selected road report'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Track this report'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Track this report'));
    await tester.pumpAndSettle();
    expect(lookedUp, isTrue);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      code,
    );
    expect(find.text('Selected road report'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an older search cannot overwrite the latest tracking result', (
    tester,
  ) async {
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
        return jsonResponse(
          request.headers['accept'] == 'application/json' ? [row] : row,
        );
      }
      if (request.url.path == '/rest/v1/status_updates')
        return jsonResponse([]);
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

  testWidgets('database failure is not reported as an unknown tracking code', (
    tester,
  ) async {
    await initializeBackend(
      (request) => jsonResponse({
        'code': '08006',
        'message': 'Database unavailable',
        'details': null,
        'hint': null,
      }, 503),
    );
    await openTracking(tester);
    await search(tester, 'CODE000001');
    await tester.pumpAndSettle();
    expect(find.text(t('not_found', lang: 'en')), findsNothing);
    expect(find.textContaining('try again'), findsOneWidget);
  });

  testWidgets(
    'citizen tracking shows the photo attached to an earlier update',
    (tester) async {
      await initializeBackend((request) {
        if (request.url.path == '/rest/v1/reports') {
          final row = report('HISTORY', 'Inspection evidence')
            ..['status'] = 'assigned';
          return jsonResponse(
            request.headers['accept'] == 'application/json' ? [row] : row,
          );
        }
        if (request.url.path == '/rest/v1/status_updates')
          return jsonResponse([
            {
              'text': 'Inspection completed',
              'updated_at': '2026-11-05T10:00:00Z',
              'updated_by': 'Staff review',
              'photo_url': 'sample:pothole',
            },
          ]);
        return unexpectedRequest(request);
      });
      await openTracking(tester);
      await search(tester, 'HISTORY');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Inspection completed'));
      expect(
        tester
            .widgetList<ReportMedia>(find.byType(ReportMedia))
            .map((w) => w.media),
        contains('sample:pothole'),
      );
      expect(find.text('Sent to district'), findsWidgets);
    },
  );

  testWidgets('an absent report has a clear not-found state', (tester) async {
    await initializeBackend((request) {
      if (request.headers['accept'] == 'application/json')
        return jsonResponse([]);
      return jsonResponse({
        'code': 'PGRST116',
        'message': 'No rows returned',
        'details': 'The result contains 0 rows',
        'hint': null,
      }, 406);
    });
    await openTracking(tester);
    await search(tester, 'CODE000001');
    await tester.pumpAndSettle();
    expect(find.text(t('not_found', lang: 'en')), findsOneWidget);
  });
}
