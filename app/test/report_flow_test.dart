import 'dart:async';
import 'dart:convert';

import 'package:fixcity/admin/report_details_page.dart';
import 'package:fixcity/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'support/backend.dart';

const reportId = '22222222-2222-4222-8222-222222222222';
Map<String, dynamic> fixtureReport(String status) => {
  'id': reportId,
  'report_code': 'TESTCODE',
  'title': 'Synthetic road report',
  'description': 'A sample road needs repair.',
  'category': 'cat_pothole',
  'photo_url': null,
  'latitude': 30.04,
  'longitude': 31.23,
  'status': status,
  'district': 'Demo North',
  'user_id': testUserId,
  'created_at': '2026-11-04T10:00:00Z',
};

Future<void> openDetails(WidgetTester tester, {bool district = false}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: ReportDetailsPage(reportId: reportId, districtView: district),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> enterUpdate(WidgetTester tester, String status) async {
  await tester.enterText(
    find.byType(TextFormField).first,
    'Team reviewed the report',
  );
  if (status == 'Resolved') {
    final dropdown = find.byType(DropdownButtonFormField<bool>);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resolve report').last);
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(find.byType(ElevatedButton));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => appLocale.value = const Locale('en'));
  tearDown(() async => Supabase.instance.dispose());

  testWidgets(
    'status change uses one atomic request and refreshes the details',
    (tester) async {
      final mutations = <String>[];
      var status = 'pending';
      await initializeBackend((request) {
        if (request.method == 'POST') {
          mutations.add(request.url.path);
          if (request.url.path == '/rest/v1/rpc/transition_report') {
            status = 'assigned';
            return jsonResponse(null);
          }
        }
        if (request.method == 'GET' && request.url.path == '/rest/v1/reports')
          return jsonResponse(
            request.headers['accept'] == 'application/json'
                ? [fixtureReport(status)]
                : fixtureReport(status),
          );
        if (request.method == 'GET' &&
            request.url.path == '/rest/v1/status_updates')
          return jsonResponse([]);
        return unexpectedRequest(request);
      });
      await openDetails(tester);
      await enterUpdate(tester, 'In Progress');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(mutations, ['/rest/v1/rpc/transition_report']);
      expect(find.text('Staff review'), findsOneWidget);
      expect(find.text('Sent to district'), findsWidgets);
      expect(find.textContaining('Notify Citizen'), findsNothing);
    },
  );

  testWidgets('failed transition retains the note and reuses its retry key', (
    tester,
  ) async {
    final requests = <Map<String, dynamic>>[];
    await initializeBackend((request) {
      if (request.url.path == '/rest/v1/reports' && request.method == 'GET')
        return jsonResponse(
          request.headers['accept'] == 'application/json'
              ? [fixtureReport('pending')]
              : fixtureReport('pending'),
        );
      if (request.url.path == '/rest/v1/status_updates' &&
          request.method == 'GET')
        return jsonResponse([]);
      if (request.url.path == '/rest/v1/rpc/transition_report') {
        requests.add(jsonDecode(request.body));
        return jsonResponse({
          'code': '08006',
          'message': 'Temporary failure',
        }, 503);
      }
      return unexpectedRequest(request);
    });
    await openDetails(tester);
    await enterUpdate(tester, 'In Progress');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Team reviewed the report'), findsOneWidget);
    expect(find.textContaining('Status updated'), findsNothing);
    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(requests, hasLength(2));
    expect(requests[0]['p_request_id'], requests[1]['p_request_id']);
  });

  testWidgets('resolution without repair evidence never sends a mutation', (
    tester,
  ) async {
    final mutations = <String>[];
    await initializeBackend((request) {
      if (request.method != 'GET') mutations.add(request.url.path);
      if (request.url.path == '/rest/v1/reports' && request.method == 'GET')
        return jsonResponse(
          request.headers['accept'] == 'application/json'
              ? [fixtureReport('in_progress')]
              : fixtureReport('in_progress'),
        );
      if (request.url.path == '/rest/v1/status_updates' &&
          request.method == 'GET')
        return jsonResponse([]);
      return unexpectedRequest(request);
    });
    await openDetails(tester, district: true);
    await enterUpdate(tester, 'Resolved');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(mutations, isEmpty);
    expect(find.textContaining('repair photo'), findsWidgets);
  });

  testWidgets(
    'repeated taps send one transition and disposal tolerates a delayed reply',
    (tester) async {
      final response = Completer<http.Response>();
      var calls = 0;
      await initializeBackend((request) {
        if (request.url.path == '/rest/v1/reports' && request.method == 'GET')
          return jsonResponse(
            request.headers['accept'] == 'application/json'
                ? [fixtureReport('pending')]
                : fixtureReport('pending'),
          );
        if (request.url.path == '/rest/v1/status_updates' &&
            request.method == 'GET')
          return jsonResponse([]);
        if (request.url.path == '/rest/v1/rpc/transition_report') {
          calls++;
          return response.future;
        }
        return unexpectedRequest(request);
      });
      await openDetails(tester);
      await enterUpdate(tester, 'In Progress');
      await tester.tap(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(calls, 1);
      await tester.pumpWidget(const MaterialApp(home: Text('Elsewhere')));
      response.complete(jsonResponse(null));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.text('Elsewhere'), findsOneWidget);
    },
  );
}
