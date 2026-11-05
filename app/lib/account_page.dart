import 'package:flutter/material.dart';
import 'demo.dart';
import 'main.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});
  @override
  Widget build(BuildContext context) {
    final ar = appLocale.value.languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'حسابي' : 'Account'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (demoMode) ...[
            Text(
              ar ? 'مساحتك التجريبية' : 'Your demo workspace',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              ar
                  ? 'البيانات هنا وهمية وتُحذف بعد 7 أيام. لا تضف بياناتك الشخصية.'
                  : 'These are fictional records, kept for seven days. Please leave personal details out.',
            ),
            const SizedBox(height: 24),
          ],
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(ar ? 'الملف الشخصي' : 'Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(ar ? 'الإعدادات' : 'Settings'),
            subtitle: Text(ar ? 'اللغة والمظهر' : 'Language and appearance'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: Text(ar ? 'الأوسمة' : 'Badges'),
            subtitle: Text(
              ar
                  ? 'نقاط المشاركة، بلا قيمة مالية'
                  : 'Participation points, with no monetary value',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/achievements'),
          ),
          if (!demoMode) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text(ar ? 'دخول فريق المراجعة' : 'Staff sign-in'),
              onTap: () => Navigator.pushNamed(context, '/admin'),
            ),
            ListTile(
              leading: const Icon(Icons.construction),
              title: Text(ar ? 'دخول فريق الحي' : 'District sign-in'),
              onTap: () => Navigator.pushNamed(context, '/governor'),
            ),
          ],
          if (demoMode) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(ar ? 'تغيير الدور التجريبي' : 'Switch demo role'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/demo',
                (_) => false,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
