import 'package:fixcity/main.dart';
import 'package:fixcity/home_page.dart';
import 'package:fixcity/main_scaffold.dart';
import 'package:fixcity/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fixcity/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'support/backend.dart';
import 'report_flow_test.dart' show fixtureReport;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Cairo')
      ..addFont(rootBundle.load('assets/fonts/Cairo.ttf'));
    await font.load();
  });
  setUp(() {
    appLocale.value = const Locale('en');
    isDarkMode.value = false;
  });
  tearDown(() => isDarkMode.value = false);
  tearDown(() async => Supabase.instance.dispose());

  for (final width in [360.0, 1000.0]) {
    testWidgets('navigation at $width keeps account tools reachable', (
      tester,
    ) async {
      await initializeBackend((request) => jsonResponse([]));
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: fixCityTheme(Brightness.light),
          home: const MainScaffold(),
          routes: {'/settings': (_) => const SettingsPage()},
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byType(width < 700 ? NavigationBar : NavigationRail),
        findsOneWidget,
      );
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Badges'), findsNothing);
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(find.text('Badges'), findsOneWidget);
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('home uses stored report codes and opens the matching tracker', (
    tester,
  ) async {
    await initializeBackend((request) {
      if (request.url.path == '/auth/v1/token') return sessionResponse();
      if (request.url.path == '/rest/v1/reports') {
        // These are the selected fields in the database schema, not model aliases.
        const columns = {
          'id',
          'title',
          'description',
          'status',
          'category',
          'report_code',
          'district',
          'created_at',
        };
        final requested = request.url.queryParameters['select']!.split(',');
        expect(requested.every(columns.contains), isTrue);
        expect(request.url.queryParameters['user_id'], 'eq.$testUserId');
        return jsonResponse([
          {
            'id': '22222222-2222-4222-8222-222222222222',
            'report_code': 'TRACK-THIS-REPORT',
            'title': 'Sample lighting issue',
            'description': 'A fictional broken light',
            'status': 'pending',
            'category': 'cat_lighting',
            'district': 'Demo North',
            'created_at': '2026-11-05T09:00:00Z',
          },
        ]);
      }
      return unexpectedRequest(request);
    });
    await Supabase.instance.client.auth.signInWithPassword(
      email: 'citizen@example.test',
      password: 'test',
    );
    Object? openedCode;
    await tester.pumpWidget(
      MaterialApp(
        theme: fixCityTheme(Brightness.light),
        home: const HomePage(),
        onGenerateRoute: (settings) {
          openedCode = settings.arguments;
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Tracking destination')),
          );
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not load'), findsNothing);
    await tester.scrollUntilVisible(find.text('A fictional broken light'), 180);
    await tester.tap(find.text('A fictional broken light'));
    await tester.pumpAndSettle();
    expect(openedCode, 'TRACK-THIS-REPORT');
    expect(find.text('Tracking destination'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'report sheet still tracks after a navigation breakpoint change',
    (tester) async {
      await initializeBackend((request) {
        if (request.url.path == '/auth/v1/token') return sessionResponse();
        if (request.url.path == '/rest/v1/reports')
          return jsonResponse([fixtureReport('pending')]);
        if (request.url.path == '/rest/v1/notifications')
          return jsonResponse([]);
        return unexpectedRequest(request);
      });
      await Supabase.instance.client.auth.signInWithPassword(
        email: 'citizen@example.test',
        password: 'test',
      );
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Object? openedCode;
      await tester.pumpWidget(
        MaterialApp(
          theme: fixCityTheme(Brightness.dark),
          home: const MainScaffold(initialIndex: 1),
          onGenerateRoute: (settings) {
            openedCode = settings.arguments;
            return MaterialPageRoute<void>(
              builder: (_) =>
                  const Scaffold(body: Text('Tracking destination')),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Synthetic road report').first);
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(360, 900);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Track this report'));
      await tester.tap(find.text('Track this report'));
      await tester.pumpAndSettle();
      expect(openedCode, 'TESTCODE');
      expect(find.text('Tracking destination'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('settings changes the actual application theme', (tester) async {
    await initializeBackend((request) => jsonResponse([]));
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    appNavigatorKey.currentState!.pushNamed('/settings');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(isDarkMode.value, isTrue);
    expect(
      Theme.of(tester.element(find.byType(SettingsPage))).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
