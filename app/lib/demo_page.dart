import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'demo.dart';
import 'main.dart';
import 'theme.dart';
import 'brand.dart';

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 12),
              const FixCityWordmark(),
              const SizedBox(height: 28),
              Text(
                _ar
                    ? 'جرّب FixCity'
                    : (_ready
                          ? 'Choose a role to try'
                          : 'See how a report gets resolved'),
                style: _ready
                    ? theme.textTheme.headlineSmall
                    : theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              if (!_ready)
                Text(
                  _ar
                      ? 'بلّغ عن مشكلة في الشارع، ثم تابع مراجعتها وإصلاحها خطوة بخطوة.'
                      : 'Report a street problem, then follow it through review and repair.',
                  style: theme.textTheme.bodyLarge,
                ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _ar
                          ? 'تجربة ببيانات وهمية'
                          : 'Synthetic data for a hands-on demo',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _ar
                          ? 'هذا نموذج لمشروع تخرج جماعي. لا يتبع جهة حكومية ولا يرسل بلاغات حقيقية. استخدم أمثلة وهمية فقط.'
                          : 'This is a team graduation-project prototype. It has no government affiliation and sends no real reports. Use fictional details only.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                const SizedBox(height: 12),
              ],
              if (_busy)
                const Center(child: CircularProgressIndicator())
              else if (!_ready) ...[
                ElevatedButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
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
                const SizedBox(height: 8),
                Text(
                  _ar
                      ? 'دون تسجيل حساب. مساحتك منفصلة عن الزوار الآخرين.'
                      : 'No registration needed. You get a workspace separate from other visitors.',
                  style: theme.textTheme.bodySmall,
                ),
              ] else ...[
                const SizedBox(height: 12),
                _role(
                  _ar ? 'مواطن' : 'Citizen',
                  _ar
                      ? 'أرسل بلاغاً وتابع ما حدث له'
                      : 'Submit a report and follow its progress',
                  Icons.person_outline,
                  () => _open(DemoPersona.citizen, '/home'),
                ),
                const Divider(),
                _role(
                  _ar ? 'مراجعة فريق العمل' : 'Staff review',
                  _ar
                      ? 'راجع البلاغ وابدأ العمل عليه'
                      : 'Review the report and start the work',
                  Icons.fact_check_outlined,
                  () => _open(DemoPersona.staff, '/admin/dashboard'),
                ),
                const Divider(),
                _role(
                  _ar ? 'فريق الحي' : 'District team',
                  _ar
                      ? 'أضف نتيجة الإصلاح في الحي التجريبي الشمالي'
                      : 'Record the repair in Demo North',
                  Icons.construction,
                  () => _open(DemoPersona.district, '/governor/dashboard'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _reset,
                  child: Text(_ar ? 'إعادة ضبط تجربتي' : 'Reset my demo'),
                ),
              ],
              const SizedBox(height: 24),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  _ar
                      ? 'عن هذه التجربة والبيانات'
                      : 'About the demo and your data',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      _ar
                          ? 'تبدأ المساحة بمثالين وتسمح بما يصل إلى 20 بلاغاً. تُحذف البيانات بعد 7 أيام. مسح تخزين المتصفح أو التطبيق يفقدك الوصول إليها. الصور تجريبية، والنقاط بلا قيمة مالية. الخدمة المجانية قد تتوقف مؤقتاً بعد فترة من عدم الاستخدام.'
                          : 'Your workspace starts with two examples and allows up to 20 reports. Data expires after seven days. Clearing browser or app storage loses access. Images are samples and points have no monetary value. The free backend may pause after inactivity.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Original project: moatazahmedshaker/Fixcity. Credits: Ahmed Wael Ali (DoctorJhin) and the six-person BIS team. Mohamed Elmorshedy maintains this portfolio extension with AI assistance.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _role(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback action,
  ) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
    title: Text(title, style: Theme.of(context).textTheme.titleMedium),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: action,
  );
}

class DemoBanner extends StatelessWidget {
  final Widget child;
  const DemoBanner({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Material(
            color: dark ? kDark2 : const Color(0xFFECE8D9),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  children: [
                    Text(
                      ar
                          ? 'نسخة تجريبية · بلا بلاغات حقيقية'
                          : 'Demo only · No real reports',
                      style: TextStyle(
                        color: dark ? Colors.white : kDark,
                        fontSize: 12,
                      ),
                    ),
                    TextButton(
                      onPressed: () => appNavigatorKey.currentState
                          ?.pushNamedAndRemoveUntil('/demo', (_) => false),
                      child: Text(ar ? 'قائمة التجربة' : 'Demo menu'),
                    ),
                    TextButton(
                      onPressed: () =>
                          appLocale.value = Locale(ar ? 'en' : 'ar'),
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
                constraints: const BoxConstraints(maxWidth: 1120),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
