import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'demo.dart';
import 'main.dart';
import 'theme.dart';

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});
  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final _client = Supabase.instance.client;
  bool _busy = false, _ready = false;
  String? _error;
  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  @override
  void initState() {
    super.initState();
    if (_client.auth.currentUser != null) _start();
  }

  Future<void> _start() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ensureDemoWorkspace(_client);
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted)
        setState(
          () => _error = _ar
              ? 'تعذر بدء التجربة. تحقق من الاتصال وحاول مجدداً.'
              : 'Could not start the demo. Check your connection and retry.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_ar ? 'إلغاء' : 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _reset() async {
    if (_busy ||
        !await _confirm(
          _ar ? 'إعادة ضبط التجربة؟' : 'Reset your demo?',
          _ar
              ? 'سيتم حذف بلاغات هذه الجلسة التجريبية فقط وإعادة الأمثلة.'
              : 'This removes only this session’s synthetic reports and restores the examples.',
          _ar ? 'إعادة الضبط' : 'Reset',
        ))
      return;
    if (!mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await resetDemoWorkspace(_client);
    } catch (_) {
      if (mounted)
        setState(
          () => _error = _ar
              ? 'تعذرت إعادة الضبط. انتظر دقيقة وحاول مجدداً؛ بياناتك ما زالت متاحة.'
              : 'We could not reset the demo. Wait a minute and retry; your existing demo is still available.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _newSession() async {
    if (_busy ||
        !await _confirm(
          _ar ? 'بدء جلسة جديدة؟' : 'Start a new session?',
          _ar
              ? 'ستفقد الوصول إلى بلاغات الجلسة السابقة.'
              : 'You will lose access to reports in this browser’s previous session.',
          _ar ? 'جلسة جديدة' : 'New session',
        ))
      return;
    if (!mounted) return;
    try {
      await _client.auth.signOut(scope: SignOutScope.local);
      if (mounted) {
        setState(() => _ready = false);
        await _start();
      }
    } catch (_) {
      if (mounted)
        setState(
          () => _error = _ar
              ? 'تعذر تغيير الجلسة؛ حاول مجدداً.'
              : 'Could not change sessions; please retry.',
        );
    }
  }

  void _open(DemoPersona persona, String route) {
    demoPersona.value = persona;
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              _ar ? 'جرّب FixCity' : 'Try FixCity',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _ar
                  ? 'من بلاغ إلى إصلاح موثّق'
                  : 'From a report to a documented resolution',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            Text(
              _ar
                  ? 'نموذج مشروع تخرج جماعي. البيانات والرسومات تجريبية، ولا يتصل بجهة حكومية أو يرسل بلاغات حقيقية.'
                  : 'A team graduation-project prototype. Synthetic data and illustrations; no government affiliation or real municipal delivery.',
            ),
            const SizedBox(height: 12),
            Text(
              _ar
                  ? 'أنشئ بلاغاً، راجعه كفريق العمل، ثم أضف دليلاً تجريبياً للإصلاح وتابع النتيجة كمواطن.'
                  : 'Create a report, review it as staff, add synthetic repair evidence as the district team, then check the citizen’s tracking and alerts.',
            ),
            const SizedBox(height: 12),
            Text(
              _ar
                  ? 'مساحتك منفصلة عن الزوار الآخرين. استخدم أمثلة وهمية فقط. تنتهي البيانات بعد 7 أيام؛ مسح تخزين المتصفح يفقدك الوصول.'
                  : 'Your workspace is separate from other visitors. Use fictional details only. Data expires after seven days; clearing browser/app storage loses access.',
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (_busy)
              const Center(child: CircularProgressIndicator())
            else if (!_ready) ...[
              ElevatedButton(
                onPressed: _start,
                child: Text(
                  _error == null
                      ? (_ar ? 'ابدأ التجربة' : 'Start demo')
                      : (_ar ? 'إعادة المحاولة' : 'Retry'),
                ),
              ),
              if (_error != null && _client.auth.currentUser != null)
                TextButton(
                  onPressed: _newSession,
                  child: Text(_ar ? 'بدء جلسة جديدة' : 'Start a new session'),
                ),
            ] else ...[
              _role(
                _ar ? 'مواطن' : 'Citizen',
                _ar
                    ? 'إرسال بلاغ ومتابعة الإشعارات'
                    : 'Submit a report and check tracking or alerts',
                Icons.person_outline,
                () => _open(DemoPersona.citizen, '/home'),
              ),
              _role(
                _ar ? 'مراجعة فريق العمل' : 'Staff review',
                _ar
                    ? 'مراجعة البلاغ ونقله إلى جارٍ العمل'
                    : 'Review a report and move it into progress',
                Icons.fact_check_outlined,
                () => _open(DemoPersona.staff, '/admin/dashboard'),
              ),
              _role(
                _ar ? 'فريق الحي' : 'District team',
                _ar
                    ? 'إكمال الإصلاح في الحي التجريبي الشمالي'
                    : 'Complete the repair in Demo North',
                Icons.construction,
                () => _open(DemoPersona.district, '/governor/dashboard'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _reset,
                child: Text(_ar ? 'إعادة ضبط تجربتي' : 'Reset my demo'),
              ),
              Text(
                _ar
                    ? 'مثالان جاهزان، وحتى 20 بلاغاً في المساحة الواحدة. لا قيمة مالية للنقاط.'
                    : 'Two starter examples; up to 20 reports per workspace. Points have no monetary value.',
                style: const TextStyle(fontSize: 12),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Original team project: moatazahmedshaker/Fixcity. Credits: Ahmed Wael Ali (DoctorJhin) and the six-person BIS team. This portfolio extension is maintained by Mohamed Elmorshedy with AI assistance.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _role(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback action,
  ) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: Icon(icon, color: kRed),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward),
      onTap: action,
    ),
  );
}

class DemoBanner extends StatelessWidget {
  final Widget child;
  const DemoBanner({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      children: [
        Material(
          color: const Color(0xFFFFF3CD),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    ar
                        ? 'بيانات تجريبية · لا توجد بلاغات حقيقية'
                        : 'Synthetic data · No real reports',
                    style: const TextStyle(
                      color: Color(0xFF553C00),
                      fontSize: 12,
                    ),
                  ),
                  TextButton(
                    onPressed: () => appNavigatorKey.currentState
                        ?.pushNamedAndRemoveUntil('/demo', (_) => false),
                    child: Text(ar ? 'قائمة التجربة' : 'Demo menu'),
                  ),
                  TextButton(
                    onPressed: () => appLocale.value = ar
                        ? const Locale('en')
                        : const Locale('ar'),
                    child: Text(ar ? 'English' : 'العربية'),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
