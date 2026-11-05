import 'package:fixcity/main.dart' as app;
import 'package:fixcity/demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (const bool.fromEnvironment('MEASURE_PERFORMANCE')) {
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  }
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'Android demo completes one persisted reporting cycle',
    (tester) async {
      // Profile mode needs a registered test keyboard to receive injected text.
      tester.testTextInput.register();
      addTearDown(tester.testTextInput.unregister);
      Future<void> workflow() async {
        // This opt-in test creates synthetic data only in the dedicated demo project.
        expect(demoMode, isTrue);
        expect(app.supabaseUrl, 'https://goohgkzuggxxqpcnikjn.supabase.co');
        await app.main();
        app.appLocale.value = const Locale('en');
        Future<void> waitFor(Finder finder) async {
          final end = DateTime.now().add(const Duration(seconds: 45));
          while (finder.evaluate().isEmpty && DateTime.now().isBefore(end)) {
            await tester.pump(const Duration(milliseconds: 200));
          }
          expect(
            finder,
            findsWidgets,
            reason: tester.allWidgets
                .whereType<Text>()
                .map((w) => w.data)
                .join(' | '),
          );
        }

        Future<void> tap(Finder finder) async {
          await waitFor(finder);
          debugPrint('Android step: ${finder.description}');
          // The success dialog intentionally animates forever; do not settle it.
          await tester.pump(const Duration(milliseconds: 600));
          await tester.ensureVisible(finder.first);
          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(finder.first);
          await tester.pump(const Duration(milliseconds: 400));
        }

        await tester.pump(const Duration(seconds: 1));
        if (find.text('Start demo').evaluate().isNotEmpty) {
          await tap(find.text('Start demo'));
        }
        await tap(find.text('Citizen'));
        await tap(find.text('Roads'));
        final description =
            'Synthetic Android emulator check ${DateTime.now().millisecondsSinceEpoch}';
        await tester.enterText(find.byType(TextFormField).first, description);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField).first)
              .controller!
              .text,
          description,
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tap(find.text('Select a district'));
        await tap(find.text('Demo North'));
        await tap(find.text('Use sample photo'));
        await tap(find.text('Damaged road / طريق متضرر'));
        await tap(find.text('Submit Report'));
        await tap(find.text('Submit'));
        await waitFor(find.text('Report submitted'));
        await tap(find.text('Done'));
        final client = Supabase.instance.client;
        final saved = await client
            .from('reports')
            .select()
            .eq('description', description)
            .single();
        expect(saved['status'], 'pending');
        await tap(find.text('Demo menu'));
        await tap(find.text('Staff review'));
        await waitFor(find.byType(ListTile));
        await tap(
          find.descendant(
            of: find.byType(ListTile).first,
            matching: find.byType(IconButton),
          ),
        );
        await waitFor(find.text(description));
        await tester.enterText(
          find.byType(TextFormField).first,
          'Synthetic staff review completed.',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tap(find.text('Attach photo (optional)'));
        await tap(find.text('Damaged road / طريق متضرر'));
        await tap(find.text('Send to district'));
        await waitFor(find.text('Synthetic staff review completed.'));
        expect(
          (await client
              .from('reports')
              .select('status')
              .eq('id', saved['id'])
              .single())['status'],
          'assigned',
        );
        await tap(find.text('Demo menu'));
        await tap(find.text('District team'));
        await tap(find.text(description));
        await waitFor(find.byType(TextFormField));
        await tester.enterText(
          find.byType(TextFormField).first,
          'District crew started work.',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tap(find.text('Start repair'));
        await waitFor(find.text('District crew started work.'));
        await tap(find.byType(DropdownButtonFormField<bool>));
        await tap(find.text('Resolve report').last);
        await tester.enterText(
          find.byType(TextFormField).first,
          'Synthetic repair verified on Android.',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tap(find.text('Attach repair photo'));
        await tap(find.text('Repaired road / طريق تم إصلاحه'));
        await tap(find.text('Mark resolved'));
        await waitFor(find.text('Resolved'));
        expect(
          (await client
              .from('reports')
              .select('status')
              .eq('id', saved['id'])
              .single())['status'],
          'resolved',
        );
        expect(
          await client
              .from('status_updates')
              .select('id')
              .eq('report_id', saved['id']),
          hasLength(4),
        );
        expect(
          await client
              .from('notifications')
              .select('id')
              .eq('report_id', saved['id']),
          hasLength(4),
        );
        await tap(find.text('Demo menu'));
        await tap(find.text('Citizen'));
        app.appNavigatorKey.currentState!.pushNamed(
          '/track',
          arguments: saved['report_code'],
        );
        await tester.pump(const Duration(milliseconds: 500));
        await waitFor(find.text('Synthetic repair verified on Android.'));
        expect(find.text('Resolved'), findsWidgets);
        await tap(find.text('العربية'));
        expect(find.text('متابعة حالة البلاغ'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      if (const bool.fromEnvironment('MEASURE_PERFORMANCE')) {
        await binding.watchPerformance(workflow);
      } else {
        await workflow();
      }
    },
    skip: !const bool.fromEnvironment('RUN_HOSTED_SMOKE'),
  );
}
