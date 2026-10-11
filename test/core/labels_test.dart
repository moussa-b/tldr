import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tldr/core/labels.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  group('relativeDate', () {
    final now = DateTime(2026, 10, 11, 10, 55);

    test('counts calendar days, never « 1 jours »', () {
      // Regression: ISSUE-001 — a post from two days ago, under 48 h old, read « il y a 1 jours »
      // Found by /qa on 2026-10-11
      // Report: docs/qa/2026-10-11/qa-report-tldr-2026-10-11.md
      expect(relativeDate(DateTime(2026, 10, 9, 22), now: now), 'il y a 2 jours');
    });

    test('labels by age', () {
      expect(relativeDate(now.subtract(const Duration(seconds: 20)), now: now), 'à l\'instant');
      expect(relativeDate(now.subtract(const Duration(minutes: 5)), now: now), 'il y a 5 min');
      expect(relativeDate(DateTime(2026, 10, 11, 7), now: now), 'il y a 3 h');
      expect(relativeDate(DateTime(2026, 10, 10, 23), now: now), 'hier');
      expect(relativeDate(DateTime(2026, 10, 5, 12), now: now), 'il y a 6 jours');
      expect(relativeDate(DateTime(2026, 10, 3), now: now), '3 oct.');
      expect(relativeDate(DateTime(2025, 10, 3), now: now), '3 oct. 2025');
    });
  });
}
