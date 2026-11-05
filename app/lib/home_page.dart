import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'brand.dart';
import 'demo.dart';
import 'main.dart';
import 'theme.dart';
import 'translations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  final _client = Supabase.instance.client;
  StreamSubscription<AuthState>? _authSubscription;
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true, _loadFailed = false;
  String? _loadedUserId;

  @override
  void initState() {
    super.initState();
    _authSubscription = _client.auth.onAuthStateChange.listen((data) {
      if (data.session?.user.id != _loadedUserId) _loadReports();
    });
    _loadReports();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  @override
  void didPopNext() => _loadReports();
  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadReports() async {
    if (!mounted) return;
    final user = _client.auth.currentUser;
    _loadedUserId = user?.id;
    if (user == null) {
      setState(() {
        _reports = [];
        _loading = false;
        _loadFailed = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final rows = await _client
          .from('reports')
          .select(
            'id,title,description,status,category,report_code,district,created_at',
          )
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      if (mounted && _client.auth.currentUser?.id == user.id)
        setState(() {
          _reports = rows.cast<Map<String, dynamic>>();
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final lang = ar ? 'ar' : 'en';
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const categories = [
      ('cat_pothole', Icons.add_road_outlined),
      ('cat_trash', Icons.delete_outline),
      ('cat_lighting', Icons.lightbulb_outline),
      ('cat_sewage', Icons.waves_outlined),
      ('cat_water', Icons.water_drop_outlined),
      ('cat_other', Icons.more_horiz),
    ];
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const FittedBox(fit: BoxFit.scaleDown, child: FixCityWordmark()),
        toolbarHeight: 76,
        actions: [
          if (!demoMode)
            TextButton(
              onPressed: () => appLocale.value = Locale(ar ? 'en' : 'ar'),
              child: Text(ar ? 'English' : 'العربية'),
            ),
          IconButton(
            tooltip: ar ? 'تحديث البلاغات' : 'Refresh reports',
            onPressed: _loading ? null : _loadReports,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReports,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            if (_loadFailed) ...[
              Text(
                ar
                    ? 'تعذر تحميل البلاغات. حاول مرة أخرى.'
                    : 'Could not load reports. Please try again.',
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: _loadReports,
                  child: Text(ar ? 'إعادة المحاولة' : 'Retry'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ar ? 'ما المشكلة في منطقتك؟' : 'What needs fixing?',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ar
                        ? 'أضف تفاصيل المشكلة، ثم تابع بلاغك حتى اكتمال الإصلاح.'
                        : 'Report a local problem and follow its progress through to repair.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFD7E4EB),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAccent,
                          foregroundColor: kDark,
                        ),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/report'),
                        icon: const Icon(Icons.add),
                        label: Text(ar ? 'بلّغ عن مشكلة' : 'Report a problem'),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF8097A4)),
                        ),
                        onPressed: () => Navigator.pushNamed(context, '/track'),
                        icon: const Icon(Icons.search),
                        label: Text(ar ? 'متابعة بلاغ' : 'Track a report'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              ar ? 'اختر نوع المشكلة' : 'Choose a problem type',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 600 ? 3 : 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final category in categories)
                      SizedBox(
                        width:
                            (constraints.maxWidth - (columns - 1) * 12) /
                            columns,
                        child: Material(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/report',
                              arguments: category.$1,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    category.$2,
                                    color: scheme.primary,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    t(category.$1, lang: lang),
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              children: [
                Text(
                  ar ? 'آخر بلاغاتك' : 'Your latest reports',
                  style: theme.textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/my_reports'),
                  child: Text(ar ? 'عرض الكل' : 'View all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading)
              const LinearProgressIndicator()
            else if (_loadFailed)
              const SizedBox.shrink()
            else if (_reports.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  ar
                      ? 'لم ترسل بلاغاً بعد. ابدأ باختيار نوع المشكلة أعلاه.'
                      : 'No reports yet. Choose a problem type above to get started.',
                ),
              )
            else ...[
              Text(
                ar
                    ? '${_reports.length} بلاغات · ${_reports.where((r) => r['status'] == 'resolved').length} تم حلها'
                    : '${_reports.length} reports · ${_reports.where((r) => r['status'] == 'resolved').length} resolved',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              for (final report in _reports.take(3)) ...[
                Material(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    title: Text(
                      report['description']?.toString() ??
                          report['title']?.toString() ??
                          '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${statusLabel(report['status'] as String? ?? 'pending', lang)} · ${report['district'] ?? ''}',
                      ),
                    ),
                    leading: Icon(
                      report['status'] == 'resolved'
                          ? Icons.task_alt
                          : Icons.assignment_outlined,
                      color: scheme.primary,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: report['report_code'] == null
                        ? null
                        : () => Navigator.pushNamed(
                            context,
                            '/track',
                            arguments: report['report_code'],
                          ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
            if (demoMode) ...[
              const SizedBox(height: 20),
              Text(
                ar
                    ? 'تريد تجربة ما يحدث بعد الإرسال؟ افتح قائمة التجربة واختر فريق المراجعة.'
                    : 'Want to see what happens after submission? Open the demo menu and choose Staff review.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
