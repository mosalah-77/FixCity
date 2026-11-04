import 'dart:convert';

import 'package:fixcity/main.dart';
import 'package:fixcity/main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => appLocale.value = const Locale('en'));
  tearDown(() async => Supabase.instance.dispose());

  testWidgets('home leaves alerts unread; opening alerts marks only the loaded batch', (tester) async {
    final notifications = List.generate(51, (i) => <String, dynamic>{
      'id': '00000000-0000-4000-8000-${i.toString().padLeft(12, '0')}',
      'user_id': testUserId,
      'title': 'Update $i', 'body': 'Changed',
      'created_at': '2026-01-01T00:00:00Z', 'is_read': false,
    });
    var readWrites = 0;
    await initializeBackend((request) {
      if (request.url.path == '/auth/v1/token') return sessionResponse();
      if (request.url.path == '/rest/v1/reports') return jsonResponse([]);
      if (request.url.path == '/rest/v1/profiles') {
        return jsonResponse({'id': testUserId, 'points': 0, 'full_name': 'Demo Citizen'});
      }
      if (request.url.path == '/rest/v1/notifications') {
        if (request.method == 'PATCH') {
          readWrites++;
          expect(jsonDecode(request.body), {'is_read': true});
          final idFilter = request.url.queryParameters['id'];
          for (final row in notifications) {
            if (idFilter == null || idFilter.contains(row['id'] as String)) {
              row['is_read'] = true;
            }
          }
          return jsonResponse(null, 204);
        }
        var rows = notifications.where((row) =>
          request.url.queryParameters['is_read'] != 'eq.false' || row['is_read'] == false);
        final limit = int.tryParse(request.url.queryParameters['limit'] ?? '');
        if (limit != null) rows = rows.take(limit);
        return jsonResponse(rows.toList());
      }
      return unexpectedRequest(request);
    });
    await Supabase.instance.client.auth.signInWithPassword(email: 'citizen@example.test', password: 'password');
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: MainScaffold()));
    await tester.pumpAndSettle();
    expect(readWrites, 0, reason: 'Opening Home must not consume unread notifications.');
    await tester.tap(find.text('Alerts'));
    await tester.pumpAndSettle();
    expect(find.text('Update 0'), findsOneWidget);
    expect(readWrites, 1);
    expect(notifications.where((n) => n['is_read'] == false).length, 1,
      reason: 'The 51st notification was not loaded and must stay unread.');
    expect(find.text('1'), findsOneWidget, reason: 'The badge reflects the remaining unread item.');
  });

  testWidgets('a failed alert fetch does not mark anything read or pretend the list is empty', (tester) async {
    var readWrites = 0;
    await initializeBackend((request) {
      if (request.url.path == '/auth/v1/token') return sessionResponse();
      if (request.url.path == '/rest/v1/reports') return jsonResponse([]);
      if (request.url.path == '/rest/v1/profiles') return jsonResponse({'points': 0});
      if (request.url.path == '/rest/v1/notifications') {
        if (request.method == 'PATCH') {
          readWrites++;
          return jsonResponse(null, 204);
        }
        return jsonResponse({'message': 'Database unavailable', 'code': '08006'}, 503);
      }
      return unexpectedRequest(request);
    });
    await Supabase.instance.client.auth.signInWithPassword(email: 'citizen@example.test', password: 'password');
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: MainScaffold(initialIndex: 2)));
    await tester.pumpAndSettle();
    expect(readWrites, 0);
    expect(find.text('No notifications yet'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });
}
