import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'demo.dart';
import 'demo_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'splash_page.dart';
import 'main_scaffold.dart';
import 'report_page.dart';
import 'track_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'admin/admin_login_page.dart';
import 'admin/admin_dashboard_page.dart';
import 'admin/report_details_page.dart';
import 'governor/governor_login_page.dart';
import 'governor/governor_dashboard_page.dart';
import 'governor/governor_report_page.dart';
import 'theme.dart';
import 'settings_page.dart';
import 'achievements_page.dart';
import 'profile_page.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

final ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('ar'));
final appNavigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Configure your own Supabase project using dart-define. See README.',
    );
  }
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, _) {
        final isAr = locale.languageCode == 'ar';
        return ValueListenableBuilder<bool>(
          valueListenable: isDarkMode,
          builder: (context, dark, _) {
            return MaterialApp(
              title: 'FixCity',
              navigatorKey: appNavigatorKey,
              locale: locale,
              supportedLocales: const [Locale('ar'), Locale('en')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              debugShowCheckedModeBanner: false,
              builder: (context, child) => Directionality(
                textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                child: child!,
              ),
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              darkTheme: fixCityTheme(Brightness.dark),
              theme: fixCityTheme(Brightness.light),
              navigatorObservers: [routeObserver],
              initialRoute: demoMode ? '/' : '/splash',
              routes:
                  <String, WidgetBuilder>{
                    '/demo': (context) => const DemoPage(),
                    '/splash': (context) => const SplashPage(),
                    '/': (context) =>
                        demoMode ? const DemoPage() : const MainScaffold(),
                    '/home': (context) => const MainScaffold(initialIndex: 0),
                    '/report': (context) => ReportPage(),
                    '/track': (context) => TrackPage(
                      initialCode:
                          ModalRoute.of(context)?.settings.arguments as String?,
                    ),
                    '/login': (context) =>
                        demoMode ? const DemoPage() : const LoginPage(),
                    '/signup': (context) =>
                        demoMode ? const DemoPage() : const SignupPage(),
                    '/my_reports': (context) =>
                        const MainScaffold(initialIndex: 1),
                    '/notifications': (context) =>
                        const MainScaffold(initialIndex: 2),
                    '/achievements': (context) => const AchievementsPage(),
                    '/profile': (context) => const ProfilePage(),
                    '/admin': (context) => demoMode
                        ? const AdminDashboardPage()
                        : const AdminLoginPage(),
                    '/admin/dashboard': (context) => const AdminDashboardPage(),
                    '/governor': (context) => demoMode
                        ? const GovernorDashboardPage()
                        : const GovernorLoginPage(),
                    '/governor/dashboard': (context) =>
                        const GovernorDashboardPage(),
                    '/settings': (context) => const SettingsPage(),
                  }.map(
                    (name, page) => MapEntry(
                      name,
                      (context) => demoMode
                          ? DemoBanner(child: page(context))
                          : page(context),
                    ),
                  ),
              onGenerateRoute: (settings) {
                if (settings.name != null &&
                    settings.name!.startsWith('/admin/report/')) {
                  final reportId = settings.name!.split('/').last;
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (_) => demoMode
                        ? DemoBanner(
                            child: ReportDetailsPage(reportId: reportId),
                          )
                        : ReportDetailsPage(reportId: reportId),
                  );
                }
                if (settings.name != null &&
                    settings.name!.startsWith('/governor/report/')) {
                  final reportId = settings.name!.split('/').last;
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (_) => demoMode
                        ? DemoBanner(
                            child: GovernorReportPage(reportId: reportId),
                          )
                        : GovernorReportPage(reportId: reportId),
                  );
                }
                return null;
              },
            );
          },
        );
      },
    );
  }
}
