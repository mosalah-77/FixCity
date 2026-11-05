import 'package:flutter/material.dart';

const kPrimary = Color(0xFF087F73);
const kBlue = Color(0xFF164C70);
const kDark = Color(0xFF102D40);
const kDark2 = Color(0xFF16394D);
const kAccent = Color(0xFFD5AD56);
const kBg = Color(0xFFF5F4EF);
const kWhite = Colors.white;
const kGrey = Color(0xFF586872);
const kSuccess = Color(0xFF147653);
const kWarning = Color(0xFF94620E);

ThemeData fixCityTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: kPrimary,
    brightness: brightness,
    primary: dark ? const Color(0xFF7AD7C5) : kPrimary,
    secondary: dark ? kAccent : kBlue,
    surface: dark ? const Color(0xFF142B38) : Colors.white,
    onSurface: dark ? const Color(0xFFE8EFF2) : kDark,
    error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFB3261E),
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Cairo',
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  return base.copyWith(
    scaffoldBackgroundColor: dark ? const Color(0xFF0B1C27) : kBg,
    textTheme: base.textTheme.copyWith(
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.4,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.4,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.6),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.6,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: shape,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: shape,
        elevation: 0,
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: shape,
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.outline),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: scheme.primary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.all(16),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'Cairo',
          color: scheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      selectedLabelTextStyle: TextStyle(
        fontFamily: 'Cairo',
        color: scheme.primary,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: TextStyle(
        fontFamily: 'Cairo',
        color: scheme.onSurfaceVariant,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
  );
}

Color statusColor(String status, {bool dark = false}) => switch (status) {
  'pending' => dark ? const Color(0xFFFFD38E) : kWarning,
  'assigned' => dark ? const Color(0xFFA0CFFF) : kBlue,
  'in_progress' => dark ? const Color(0xFFA0CFFF) : kBlue,
  'resolved' => dark ? const Color(0xFF86DCB5) : kSuccess,
  _ => dark ? const Color(0xFFBAC8CF) : kGrey,
};

String statusLabel(String status, String lang) {
  final ar = lang == 'ar';
  return switch (status) {
    'pending' => ar ? 'قيد الانتظار' : 'Pending',
    'assigned' => ar ? 'أُحيل إلى الحي' : 'Sent to district',
    'in_progress' => ar ? 'جارٍ العمل' : 'In Progress',
    'resolved' => ar ? 'تم الحل' : 'Resolved',
    _ => status,
  };
}
