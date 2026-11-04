import 'dart:async';
import 'dart:convert';
import 'package:fixcity/main.dart';
import 'package:fixcity/demo.dart';
import 'package:fixcity/report_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'support/backend.dart';

Future<void> fillReport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(600, 1300);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    const MaterialApp(home: ReportPage(initialCategory: 'cat_pothole')),
  );
  await tester.pump();
  await tester.enterText(
    find.byType(TextFormField).first,
    'A synthetic pothole needs repair.',
  );
  await tester.ensureVisible(find.text('Select a district'));
  await tester.tap(find.text('Select a district'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Demo North'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Use sample photo'));
  await tester.tap(find.text('Use sample photo'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Damaged road / طريق متضرر'));
  await tester.pumpAndSettle();
}

Future<void> submit(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Submit Report'));
  await tester.tap(find.text('Submit Report'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text('Submit', skipOffstage: false).last);
  await tester.pump();
}

void main() {
  if (!demoMode) {
    test('Synthetic form tests run with DEMO_MODE=true', () {}, skip: true);
    return;
  }
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => appLocale.value = const Locale('en'));
  tearDown(() async => Supabase.instance.dispose());

  testWidgets(
    'lost save response then language switch retries the same committed operation',
    (tester) async {
      final requests = <Map<String, dynamic>>[];
      final persisted = <String>{};
      await initializeBackend((request) {
        if (request.url.path == '/rest/v1/rpc/create_report') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          requests.add(body);
          persisted.add(body['p_request_id'] as String);
          if (requests.length == 1)
            return jsonResponse({
              'code': '08006',
              'message': 'Response lost after commit',
            }, 503);
          return jsonResponse({
            'report_code': '0123456789ABCDEF0123456789ABCDEF',
          });
        }
        return unexpectedRequest(request);
      });
      await fillReport(tester);
      await submit(tester);
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: [Locale('ar'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: ReportPage(initialCategory: 'cat_pothole'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('إرسال البلاغ'));
      await tester.tap(find.text('إرسال البلاغ'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('إرسال').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(requests, hasLength(2));
      expect(requests[1], requests[0]);
      expect(persisted, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed save keeps form and retries one atomic request with the same key',
    (tester) async {
      final requests = <Map<String, dynamic>>[];
      await initializeBackend((request) {
        if (request.url.path == '/rest/v1/rpc/create_report') {
          requests.add(jsonDecode(request.body));
          return jsonResponse({
            'code': '08006',
            'message': 'Temporary failure',
          }, 503);
        }
        return unexpectedRequest(request);
      });
      await fillReport(tester);
      await submit(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Report Submitted!'), findsNothing);
      expect(find.text('A synthetic pothole needs repair.'), findsOneWidget);
      await submit(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(requests, hasLength(2));
      expect(requests[0]['p_request_id'], requests[1]['p_request_id']);
      expect(requests[0]['p_report']['photo_url'], 'sample:pothole');
      expect(requests[0]['p_report'].containsKey('points'), isFalse);
    },
  );

  testWidgets('success stays on the live route until the user dismisses it', (
    tester,
  ) async {
    var saves = 0;
    await initializeBackend((request) {
      if (request.url.path == '/rest/v1/rpc/create_report') {
        saves++;
        return jsonResponse({
          'id': '22222222-2222-4222-8222-222222222222',
          'report_code': '0123456789ABCDEF0123456789ABCDEF',
        });
      }
      return unexpectedRequest(request);
    });
    await fillReport(tester);
    await submit(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(saves, 1);
    expect(find.text('Report Submitted!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'leaving while a save completes cannot open a stale success dialog',
    (tester) async {
      final response = Completer<http.Response>();
      var saves = 0;
      await initializeBackend((request) {
        if (request.url.path == '/rest/v1/rpc/create_report') {
          saves++;
          return response.future;
        }
        return unexpectedRequest(request);
      });
      await fillReport(tester);
      await submit(tester);
      expect(saves, 1);
      await tester.pumpWidget(const MaterialApp(home: Text('Elsewhere')));
      response.complete(jsonResponse({'report_code': 'PERSISTED'}));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.text('Report Submitted!'), findsNothing);
    },
  );
}
