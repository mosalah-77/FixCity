import 'package:fixcity/main.dart';
import 'package:fixcity/home_page.dart';
import 'package:fixcity/admin/admin_dashboard_page.dart';
import 'package:fixcity/governor/governor_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'support/backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => appLocale.value = const Locale('en'));
  tearDown(() async => Supabase.instance.dispose());
  for (final page in <Widget>[
    const HomePage(),
    const AdminDashboardPage(),
    const GovernorDashboardPage(),
  ]) {
    testWidgets(
      '${page.runtimeType} fits narrow Arabic screens with larger text',
      (tester) async {
        appLocale.value = const Locale('ar');
        await initializeBackend((request) {
          if (request.url.path == '/auth/v1/token') return sessionResponse();
          if (request.url.path == '/rest/v1/profiles')
            return jsonResponse({'governor_district': 'Demo North'});
          if (request.url.path == '/rest/v1/reports') return jsonResponse([]);
          return unexpectedRequest(request);
        });
        await Supabase.instance.client.auth.signInWithPassword(
          email: 'citizen@example.test',
          password: 'test',
        );
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.4;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: page,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      '${page.runtimeType} distinguishes failed loading from no reports and retries',
      (tester) async {
        var attempts = 0;
        await initializeBackend((request) {
          if (request.url.path == '/auth/v1/token') return sessionResponse();
          if (request.url.path == '/rest/v1/profiles')
            return jsonResponse({'governor_district': 'Demo North'});
          if (request.url.path == '/rest/v1/reports') {
            attempts++;
            return attempts == 1
                ? jsonResponse({'code': '08006', 'message': 'Offline'}, 503)
                : jsonResponse([]);
          }
          return unexpectedRequest(request);
        });
        await Supabase.instance.client.auth.signInWithPassword(
          email: 'citizen@example.test',
          password: 'test',
        );
        await tester.pumpWidget(MaterialApp(home: page));
        await tester.pumpAndSettle();
        expect(find.textContaining('Could not load'), findsOneWidget);
        expect(find.text('No reports found'), findsNothing);
        expect(find.text('No reports in this district'), findsNothing);
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(attempts, 2);
        expect(find.textContaining('Could not load'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
