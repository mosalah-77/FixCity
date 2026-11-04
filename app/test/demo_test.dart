import 'package:fixcity/main.dart';
import 'package:fixcity/demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'support/backend.dart';

void main() {
  if (!demoMode) {
    test('Demo tests run with DEMO_MODE=true', () {}, skip: true);
    return;
  }
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => appLocale.value = const Locale('en'));
  tearDown(() async => Supabase.instance.dispose());

  testWidgets(
    'language changes immediately and preserves an open report draft',
    (tester) async {
      await initializeBackend(unexpectedRequest);
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();
      expect(find.text('جرّب FixCity'), findsOneWidget);
      appNavigatorKey.currentState!.pushNamed('/report');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'A fictional draft retained across languages.',
      );
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(
        find.text('A fictional draft retained across languages.'),
        findsOneWidget,
      );
      expect(find.text('Submit Report'), findsOneWidget);
    },
  );

  testWidgets(
    'demo entry labels synthetic data, creates one identity and preserves it on reload',
    (tester) async {
      var signups = 0, starts = 0;
      await initializeBackend((request) {
        if (request.url.path == '/auth/v1/signup') {
          signups++;
          return sessionResponse(anonymous: true);
        }
        if (request.url.path == '/rest/v1/rpc/start_demo') {
          starts++;
          return jsonResponse('22222222-2222-4222-8222-222222222222');
        }
        return unexpectedRequest(request);
      });
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(find.textContaining('Synthetic data'), findsWidgets);
      await tester.tap(find.text('Start demo'));
      await tester.pumpAndSettle();
      expect(find.text('Citizen'), findsOneWidget);
      expect(find.text('Staff review'), findsOneWidget);
      expect(signups, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(find.text('Citizen'), findsOneWidget);
      expect(signups, 1);
      expect(starts, 2);
    },
  );

  testWidgets(
    'failed demo setup offers retry without silently claiming readiness',
    (tester) async {
      await initializeBackend(
        (request) => request.url.path == '/auth/v1/signup'
            ? sessionResponse(anonymous: true)
            : jsonResponse({'code': '08006', 'message': 'Unavailable'}, 503),
      );
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start demo'));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Staff review'), findsNothing);
    },
  );

  testWidgets('failed reset preserves the session and existing demo access', (
    tester,
  ) async {
    await initializeBackend((request) {
      if (request.url.path == '/auth/v1/signup')
        return sessionResponse(anonymous: true);
      if (request.url.path == '/rest/v1/rpc/start_demo')
        return jsonResponse('22222222-2222-4222-8222-222222222222');
      if (request.url.path == '/rest/v1/rpc/reset_demo')
        return jsonResponse({
          'code': '55000',
          'message': 'Wait one minute',
        }, 400);
      return unexpectedRequest(request);
    });
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start demo'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Reset my demo'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset my demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset', skipOffstage: false).last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Citizen'), -200);
    await tester.pumpAndSettle();
    expect(find.text('Citizen'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('could not reset'),
      -200,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('could not reset'), findsOneWidget);
    expect(Supabase.instance.client.auth.currentUser!.id, testUserId);
  });

  testWidgets(
    'invalid identity requires explicit replacement and can recover',
    (tester) async {
      var signups = 0;
      await initializeBackend((request) {
        if (request.url.path == '/auth/v1/signup') {
          signups++;
          return sessionResponse(anonymous: true);
        }
        if (request.url.path == '/auth/v1/logout') return jsonResponse(null);
        if (request.url.path == '/rest/v1/rpc/start_demo')
          return signups == 1
              ? jsonResponse({
                  'code': 'PGRST301',
                  'message': 'Invalid JWT',
                }, 401)
              : jsonResponse('22222222-2222-4222-8222-222222222222');
        return unexpectedRequest(request);
      });
      await Supabase.instance.client.auth.signInAnonymously();
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(signups, 1);
      expect(find.text('Retry'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Start a new session'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start a new session'));
      await tester.pumpAndSettle();
      expect(signups, 1);
      await tester.tap(find.text('New session'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Citizen'), -200);
      await tester.pumpAndSettle();
      expect(signups, 2);
      expect(find.text('Citizen'), findsOneWidget);
    },
  );

  testWidgets(
    'personas reuse the session and district view requests its fictional district',
    (tester) async {
      var signups = 0;
      final districts = <String?>[];
      await initializeBackend((request) {
        if (request.url.path == '/auth/v1/signup') {
          signups++;
          return sessionResponse(anonymous: true);
        }
        if (request.url.path == '/rest/v1/rpc/start_demo')
          return jsonResponse('22222222-2222-4222-8222-222222222222');
        if (request.url.path == '/rest/v1/reports') {
          districts.add(request.url.queryParameters['district']);
          return jsonResponse([]);
        }
        return unexpectedRequest(request);
      });
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start demo'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Staff review'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Staff review'));
      await tester.pumpAndSettle();
      expect(
        find.text('No reports found'),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .join(' | '),
      );
      await tester.tap(find.text('Demo menu'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('District team'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('District team'));
      await tester.pumpAndSettle();
      expect(find.text('Demo North'), findsOneWidget);
      expect(districts, [null, 'eq.Demo North']);
      expect(signups, 1);
    },
  );

  testWidgets('Arabic demo entry fits a narrow viewport with large text', (
    tester,
  ) async {
    await initializeBackend(unexpectedRequest);
    appLocale.value = const Locale('ar');
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('ابدأ التجربة'), 200);
    await tester.pumpAndSettle();
    expect(find.text('ابدأ التجربة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
