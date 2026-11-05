import '../theme.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/problem.dart';
import '../demo.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final supabase = Supabase.instance.client;
  String _filterStatus = 'all';
  String _filterDistrict = 'all';
  List<Map<String, dynamic>> _allReports = [];
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final data = await supabase
          .from('reports')
          .select()
          .order('created_at', ascending: false)
          .limit(200);
      if (mounted)
        setState(() {
          _allReports = data.cast<Map<String, dynamic>>();
          if (!_allReports.any((r) => r['district'] == _filterDistrict))
            _filterDistrict = 'all';
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

  void _logout() async {
    if (!demoMode) await supabase.auth.signOut();
    if (context.mounted)
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  Color _statusColor(String status) => statusColor(
    status,
    dark: Theme.of(context).brightness == Brightness.dark,
  );

  String _statusLabel(String s) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (isAr) {
      switch (s) {
        case 'pending':
          return 'قيد الانتظار';
        case 'in_progress':
          return 'جارٍ العمل';
        case 'resolved':
          return 'تم الحل';
        default:
          return s;
      }
    } else {
      switch (s) {
        case 'pending':
          return 'Pending';
        case 'in_progress':
          return 'In Progress';
        case 'resolved':
          return 'Resolved';
        default:
          return s;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadFailed)
      return Scaffold(
        appBar: AppBar(title: const Text('FixCity')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load reports / تعذر تحميل البلاغات'),
              TextButton(
                onPressed: _loadReports,
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
    var filtered = _filterStatus == 'all'
        ? _allReports
        : _allReports.where((r) => r['status'] == _filterStatus).toList();
    if (_filterDistrict != 'all') {
      filtered = filtered
          .where((r) => r['district'] == _filterDistrict)
          .toList();
    }
    final districts = [
      'all',
      ..._allReports
          .map((r) => r['district']?.toString() ?? '')
          .where((d) => d.isNotEmpty)
          .toSet()
          .toList()
        ..sort(),
    ];

    final pending = _allReports.where((r) => r['status'] == 'pending').length;
    final inProgress = _allReports
        .where((r) => r['status'] == 'in_progress')
        .length;
    final resolved = _allReports.where((r) => r['status'] == 'resolved').length;

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
          title: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'مراجعة البلاغات'
                : 'Staff review',
          ),
          actions: [
            IconButton(
              tooltip: Localizations.localeOf(context).languageCode == 'ar'
                  ? 'تحديث'
                  : 'Refresh reports',
              icon: const Icon(Icons.refresh_outlined),
              onPressed: _loadReports,
            ),
            IconButton(
              tooltip: demoMode ? 'Demo menu' : 'Sign out',
              icon: const Icon(Icons.logout_outlined),
              onPressed: _logout,
            ),
          ],
        ),
        body: Column(
          children: [
            // Filter chips with live counts
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatChip(
                    value: '${_allReports.length}',
                    label: Localizations.localeOf(context).languageCode == 'ar'
                        ? 'الكل'
                        : 'All',
                    color: Colors.white70,
                    selected: _filterStatus == 'all',
                    onTap: () => setState(() => _filterStatus = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    value: '$pending',
                    label: Localizations.localeOf(context).languageCode == 'ar'
                        ? 'انتظار'
                        : 'Pending',
                    color: const Color(0xFFF59E0B),
                    selected: _filterStatus == 'pending',
                    onTap: () => setState(() => _filterStatus = 'pending'),
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    value: '$inProgress',
                    label: Localizations.localeOf(context).languageCode == 'ar'
                        ? 'جارٍ'
                        : 'Active',
                    color: const Color(0xFF60A5FA),
                    selected: _filterStatus == 'in_progress',
                    onTap: () => setState(() => _filterStatus = 'in_progress'),
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    value: '$resolved',
                    label: Localizations.localeOf(context).languageCode == 'ar'
                        ? 'محلول'
                        : 'Resolved',
                    color: const Color(0xFF185FA5),
                    selected: _filterStatus == 'resolved',
                    onTap: () => setState(() => _filterStatus = 'resolved'),
                  ),
                ],
              ),
            ),

            // District filter
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: DropdownButtonFormField<String>(
                value: _filterDistrict,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.location_city_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                dropdownColor: Theme.of(context).colorScheme.surface,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                ),
                items: districts
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(
                          d == 'all'
                              ? (Localizations.localeOf(context).languageCode ==
                                        'ar'
                                    ? 'كل الأحياء'
                                    : 'All Districts')
                              : d,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _filterDistrict = v ?? 'all'),
              ),
            ),

            Expanded(
              child: _loading
                  ? const _DashboardSkeleton()
                  : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey.shade200,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            Localizations.localeOf(context).languageCode == 'ar'
                                ? 'لا توجد بلاغات'
                                : 'No reports found',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: kPrimary,
                      onRefresh: _loadReports,
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          16 + MediaQuery.of(context).padding.bottom,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final data = filtered[index];
                          final problem = Problem.fromSupabase(data);
                          final sc = _statusColor(problem.status);
                          final date = problem.createdAt;
                          final hasFixPhoto = (data['fix_photo_url'] ?? '')
                              .toString()
                              .isNotEmpty;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                            ),
                            child: ListTile(
                              onTap: () async {
                                await Navigator.of(
                                  context,
                                ).pushNamed('/admin/report/${data['id']}');
                                if (mounted) await _loadReports();
                              },
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: sc.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.report_problem_outlined,
                                  color: sc,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                problem.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: sc.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          _statusLabel(problem.status),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: sc,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      if ((data['district'] ?? '')
                                          .toString()
                                          .isNotEmpty)
                                        Text(
                                          data['district'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      if (hasFixPhoto) ...[
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.photo_camera,
                                          size: 12,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${date.year}/${date.month}/${date.day}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                tooltip:
                                    Localizations.localeOf(
                                          context,
                                        ).languageCode ==
                                        'ar'
                                    ? 'فتح البلاغ'
                                    : 'Open report',
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                onPressed: () async {
                                  await Navigator.of(
                                    context,
                                  ).pushNamed('/admin/report/${data['id']}');
                                  if (mounted) await _loadReports();
                                },
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

class _StatChip extends StatelessWidget {
  final String value, label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _StatChip({
    required this.value,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text('$label ($value)'),
      selected: selected,
      onSelected: (_) => onTap(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    );
  }
}

class _DashboardSkeleton extends StatefulWidget {
  const _DashboardSkeleton();
  @override
  State<_DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<_DashboardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => FadeTransition(
        opacity: _anim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 10,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
