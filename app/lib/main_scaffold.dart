import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';
import 'home_page.dart';
import 'my_reports_page.dart';
import 'notifications_page.dart';
import 'account_page.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;
  const MainScaffold({super.key, this.initialIndex = 0});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> with RouteAware {
  late int _currentIndex;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadUnread();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  @override
  void didPopNext() {
    _loadUnread();
    setState(() {});
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _loadUnread() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final res = await Supabase.instance.client
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false);
      if (mounted) setState(() => _unreadCount = (res as List).length);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final labels = ar
        ? ['الرئيسية', 'بلاغاتي', 'الإشعارات', 'حسابي']
        : ['Home', 'Reports', 'Alerts', 'Account'];
    const icons = [
      Icons.home_outlined,
      Icons.assignment_outlined,
      Icons.notifications_outlined,
      Icons.person_outline,
    ];
    final pages = <Widget>[
      const HomePage(),
      const MyReportsPage(),
      NotificationsPage(onRead: _loadUnread),
      const AccountPage(),
    ];
    Widget navIcon(int i) => i == 2 && _unreadCount > 0
        ? Badge(label: Text('$_unreadCount'), child: Icon(icons[i]))
        : Icon(icons[i]);
    final page = KeyedSubtree(
      key: ValueKey('${appLocale.value.languageCode}-$_currentIndex'),
      child: pages[_currentIndex],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        return Scaffold(
          body: Row(
            children: [
              if (wide) ...[
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (i) =>
                      setState(() => _currentIndex = i),
                  labelType: NavigationRailLabelType.all,
                  minWidth: 96,
                  destinations: List.generate(
                    4,
                    (i) => NavigationRailDestination(
                      icon: navIcon(i),
                      label: Text(labels[i]),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
              ],
              Expanded(child: page),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (i) =>
                      setState(() => _currentIndex = i),
                  destinations: List.generate(
                    4,
                    (i) => NavigationDestination(
                      icon: navIcon(i),
                      label: labels[i],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
