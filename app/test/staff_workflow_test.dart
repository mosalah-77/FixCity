import 'dart:convert';
import 'package:fixcity/admin/report_details_page.dart';
import 'package:fixcity/governor/governor_report_page.dart';
import 'package:fixcity/report_media.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'report_flow_test.dart' show fixtureReport, reportId;
import 'support/backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() async => Supabase.instance.dispose());

  Future<void> open(
    WidgetTester tester,
    String initial, {
    bool district = false,
    bool fail = false,
    List<Map<String, dynamic>>? requests,
  }) async {
    var status = initial;
    final history = <Map<String, dynamic>>[];
    await initializeBackend((request) {
      if (request.url.path == '/rest/v1/reports') {
        final row = {...fixtureReport(status), 'workspace_id': 'demo'};
        return jsonResponse(
          request.headers['accept'] == 'application/json' ? [row] : row,
        );
      }
      if (request.url.path == '/rest/v1/status_updates')
        return jsonResponse(history);
      if (request.url.path == '/rest/v1/rpc/transition_report') {
        final payload = Map<String, dynamic>.from(jsonDecode(request.body));
        requests?.add(payload);
        if (fail)
          return jsonResponse({'code': '08006', 'message': 'Unavailable'}, 503);
        status = payload['p_status'];
        history.add({
          'text': payload['p_note'],
          'photo_url': payload['p_fix_photo_url'],
          'updated_by': 'Staff review',
          'updated_at': '2026-11-05T10:00:00Z',
        });
        return jsonResponse(null);
      }
      return unexpectedRequest(request);
    });
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: district
            ? const GovernorReportPage(reportId: reportId)
            : const ReportDetailsPage(reportId: reportId),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> photo(WidgetTester tester) async {
    final button = find.byIcon(Icons.add_photo_alternate_outlined);
    expect(button, findsOneWidget);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.text(sampleMedia['sample:pothole']!));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'first staff update sends a photo with the handoff and retains it in history',
    (tester) async {
      final requests = <Map<String, dynamic>>[];
      await open(tester, 'pending', requests: requests);
      await photo(tester);
      await tester.enterText(
        find.byType(TextFormField),
        'Checked location and evidence.',
      );
      await tester.ensureVisible(find.text('Send to district'));
      await tester.tap(find.text('Send to district'));
      await tester.pumpAndSettle();
      expect(requests.single['p_status'], 'assigned');
      expect(requests.single['p_fix_photo_url'], 'sample:pothole');
      expect(find.byType(TextFormField), findsNothing);
      expect(
        tester
            .widgetList<ReportMedia>(find.byType(ReportMedia))
            .map((w) => w.media),
        contains('sample:pothole'),
      );
    },
  );

  testWidgets(
    'failed first update retains photo and note and reuses its retry key',
    (tester) async {
      final requests = <Map<String, dynamic>>[];
      await open(tester, 'pending', fail: true, requests: requests);
      await photo(tester);
      await tester.enterText(find.byType(TextFormField), 'Inspection note');
      for (var i = 0; i < 2; i++) {
        await tester.ensureVisible(find.text('Send to district'));
        await tester.tap(find.text('Send to district'));
        await tester.pumpAndSettle();
      }
      expect(requests, hasLength(2));
      expect(requests[0], requests[1]);
      expect(requests[0]['p_fix_photo_url'], 'sample:pothole');
      expect(find.text('Inspection note'), findsOneWidget);
    },
  );

  testWidgets('district cannot start an unreviewed report', (tester) async {
    await open(tester, 'pending', district: true);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.textContaining('staff review'), findsWidgets);
  });

  testWidgets('staff cannot perform district work after handing off', (
    tester,
  ) async {
    await open(tester, 'in_progress');
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('district starts an assigned report with an optional photo', (
    tester,
  ) async {
    final requests = <Map<String, dynamic>>[];
    await open(tester, 'assigned', district: true, requests: requests);
    await photo(tester);
    await tester.enterText(find.byType(TextFormField), 'Crew has started.');
    await tester.ensureVisible(find.text('Start repair'));
    await tester.tap(find.text('Start repair'));
    await tester.pumpAndSettle();
    expect(requests.single['p_status'], 'in_progress');
    expect(requests.single['p_fix_photo_url'], 'sample:pothole');
  });

  testWidgets('district progress note does not resolve a report', (
    tester,
  ) async {
    final requests = <Map<String, dynamic>>[];
    await open(tester, 'in_progress', district: true, requests: requests);
    await tester.enterText(find.byType(TextFormField).first, 'Work continues.');
    await tester.ensureVisible(find.text('Save progress update'));
    await tester.tap(find.text('Save progress update'));
    await tester.pumpAndSettle();
    expect(requests.single['p_status'], 'in_progress');
    expect(requests.single['p_fix_photo_url'], isNull);
  });
}
