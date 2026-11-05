import '../theme.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../demo.dart';

class GovernorDashboardPage extends StatefulWidget {
  const GovernorDashboardPage({super.key});
  @override
  State<GovernorDashboardPage> createState() => _GovernorDashboardPageState();
}

class _GovernorDashboardPageState extends State<GovernorDashboardPage> {
  final supabase = Supabase.instance.client;
  String? _district;
  String _filter = 'all';
  bool _profileLoading = true;
  String? _loadError;
  List<Map<String, dynamic>> _reports = [];
  bool _reportsLoading = true;

  final _filters = ['all', 'pending', 'in_progress', 'resolved'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (mounted)
      setState(() {
        _profileLoading = true;
        _loadError = null;
      });
    try {
      if (demoMode) {
        setState(() {
          _district = 'Demo North';
          _profileLoading = false;
        });
        await _loadReports();
        return;
      }
      final user = supabase.auth.currentUser;
      if (user == null) throw const AuthException('Sign in first');
      final p = await supabase
          .from('profiles')
          .select('governor_district')
          .eq('id', user.id)
          .single();
      if (!mounted) return;
      setState(() {
        _district = p['governor_district'];
        _profileLoading = false;
      });
      await _loadReports();
    } catch (_) {
      if (mounted)
        setState(() {
          _profileLoading = false;
          _loadError = 'Could not load this account / تعذر تحميل الحساب';
        });
    }
  }

  Future<void> _loadReports() async {
    if (!mounted || _district == null) return;
    setState(() => _reportsLoading = true);
    try {
      final data = await supabase
          .from('reports')
          .select()
          .eq('district', _district!)
          .order('created_at', ascending: false);
      if (mounted)
        setState(() {
          _reports = data.cast<Map<String, dynamic>>();
          _reportsLoading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _reportsLoading = false;
          _loadError = 'Could not load reports / تعذر تحميل البلاغات';
        });
    }
  }

  String _filterLabel(String f) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (isAr) {
      switch (f) {
        case 'all':
          return 'الكل';
        case 'pending':
          return 'قيد الانتظار';
        case 'in_progress':
          return 'جارٍ العمل';
        case 'resolved':
          return 'تم الحل';
        default:
          return f;
      }
    } else {
      switch (f) {
        case 'all':
          return 'All';
        case 'pending':
          return 'Pending';
        case 'in_progress':
          return 'In Progress';
        case 'resolved':
          return 'Resolved';
        default:
          return f;
      }
    }
  }

  Color _statusColor(String status) => statusColor(
    status,
    dark: Theme.of(context).brightness == Brightness.dark,
  );

  @override
  Widget build(BuildContext context) {
    if (_loadError != null)
      return Scaffold(
        appBar: AppBar(title: const Text('FixCity')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!),
              TextButton(
                onPressed: _loadProfile,
                child: Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'إعادة المحاولة'
                      : 'Retry',
                ),
              ),
            ],
          ),
        ),
      );
    if (_profileLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }

    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';

    final filtered = _filter == 'all'
        ? _reports
        : _reports.where((r) => r['status'] == _filter).toList();

    return PopScope(
      canPop: demoMode,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          if (!demoMode) await supabase.auth.signOut();
          if (context.mounted)
            Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'فريق الحي' : 'District team',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_district != null)
                Text(
                  _district!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          centerTitle: false,
          actions: [
            IconButton(
              tooltip: isAr ? 'تحديث' : 'Refresh reports',
              icon: const Icon(Icons.refresh_outlined),
              onPressed: _loadReports,
            ),
            IconButton(
              tooltip: demoMode ? 'Demo menu' : 'Sign out',
              icon: const Icon(Icons.logout_outlined),
              onPressed: () async {
                if (!demoMode) await supabase.auth.signOut();
                if (!mounted) return;
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (_) => false);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Filter chips
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((f) {
                    final isSelected = _filter == f;
                    final count = f == 'all'
                        ? _reports.length
                        : _reports.where((r) => r['status'] == f).length;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text('${_filterLabel(f)} ($count)'),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _filter = f),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Reports
            Expanded(
              child: _district == null
                  ? Center(
                      child: Text(
                        isAr
                            ? 'لم يتم تعيين حي لهذا الحساب'
                            : 'No district assigned to this account',
                      ),
                    )
                  : _reportsLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: kPrimary),
                    )
                  : RefreshIndicator(
                      color: kPrimary,
                      onRefresh: _loadReports,
                      child: filtered.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.25,
                                ),
                                Column(
                                  children: [
                                    Icon(
                                      Icons.inbox_outlined,
                                      size: 64,
                                      color: Colors.grey.shade200,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      isAr
                                          ? 'لا توجد بلاغات في هذا الحي'
                                          : 'No reports in this district',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      isAr
                                          ? 'اسحب للأسفل للتحديث'
                                          : 'Pull down to refresh',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                16 + MediaQuery.of(context).padding.bottom,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final r = filtered[i];
                                final status = r['status'] ?? 'pending';
                                final color = _statusColor(status);
                                final date =
                                    DateTime.tryParse(r['created_at'] ?? '') ??
                                    DateTime.now();
                                final hasFixPhoto = (r['fix_photo_url'] ?? '')
                                    .toString()
                                    .isNotEmpty;
                                final pingCount = r['ping_count'] ?? 0;
                                final reportId = r['id'].toString();
                                final description = r['description'] ?? '';

                                return GestureDetector(
                                  onTap: () async {
                                    await Navigator.of(
                                      context,
                                    ).pushNamed('/governor/report/$reportId');
                                    _loadReports();
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(14),
                                      border:
                                          pingCount > 0 && status != 'resolved'
                                          ? Border.all(
                                              color: Colors.orange.shade300,
                                              width: 1.5,
                                            )
                                          : Border.all(
                                              color: Colors.grey.shade100,
                                            ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.04,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.report_problem_outlined,
                                            color: color,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                description,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: color.withValues(
                                                        alpha: 0.1,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      _filterLabel(status),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: color,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  if (hasFixPhoto)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: kPrimary
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        isAr
                                                            ? '📷 صورة الإصلاح'
                                                            : '📷 Fix Photo',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  if (pingCount > 0 &&
                                                      status != 'resolved') ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.orange
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '🔔 $pingCount ${isAr ? 'تنبيه' : 'ping${pingCount > 1 ? 's' : ''}'}',
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.orange,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${date.year}/${date.month}/${date.day}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color: Colors.grey.shade300,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
