import 'package:fixcity/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('status text has readable contrast on its light and dark badges', () {
    for (final dark in [false, true]) {
      final surface = fixCityTheme(
        dark ? Brightness.dark : Brightness.light,
      ).colorScheme.surface;
      for (final status in ['pending', 'in_progress', 'resolved']) {
        final ink = statusColor(status, dark: dark);
        final badge = Color.alphaBlend(ink.withValues(alpha: .1), surface);
        final a = ink.computeLuminance(), b = badge.computeLuminance();
        final contrast = a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
        expect(
          contrast,
          greaterThanOrEqualTo(4.5),
          reason: '$status, dark=$dark',
        );
      }
    }
  });
}
