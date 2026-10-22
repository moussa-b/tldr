import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tldr/core/labels.dart';
import 'package:tldr/data/models/models.dart';
import 'package:tldr/l10n/app_localizations.dart';

void main() {
  setUpAll(initializeDateFormatting);
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));

  group('relativeDate', () {
    final now = DateTime(2026, 10, 11, 10, 55);

    test('counts calendar days, never « 1 jours »', () {
      // Regression: ISSUE-001 — a post from two days ago, under 48 h old, read « il y a 1 jours »
      // Found by /qa on 2026-10-11
      // Report: docs/qa/2026-10-11/qa-report-tldr-2026-10-11.md
      expect(relativeDate(DateTime(2026, 10, 9, 22), fr, now: now), 'il y a 2 jours');
    });

    test('labels by age', () {
      expect(relativeDate(now.subtract(const Duration(seconds: 20)), fr, now: now), 'à l\'instant');
      expect(relativeDate(now.subtract(const Duration(minutes: 5)), fr, now: now), 'il y a 5 min');
      expect(relativeDate(DateTime(2026, 10, 11, 7), fr, now: now), 'il y a 3 h');
      expect(relativeDate(DateTime(2026, 10, 10, 23), fr, now: now), 'hier');
      expect(relativeDate(DateTime(2026, 10, 5, 12), fr, now: now), 'il y a 6 jours');
      expect(relativeDate(DateTime(2026, 10, 3), fr, now: now), '3 oct.');
      expect(relativeDate(DateTime(2025, 10, 3), fr, now: now), '3 oct. 2025');
    });

    // protects=English dates; fails_when=a branch falls back to French or a wrong pattern;
    // no_claim=other languages.
    test('labels by age in English', () {
      expect(relativeDate(now.subtract(const Duration(seconds: 20)), en, now: now), 'just now');
      expect(relativeDate(now.subtract(const Duration(minutes: 5)), en, now: now), '5 min ago');
      expect(relativeDate(DateTime(2026, 10, 11, 7), en, now: now), '3h ago');
      expect(relativeDate(DateTime(2026, 10, 10, 23), en, now: now), 'yesterday');
      expect(relativeDate(DateTime(2026, 10, 9, 22), en, now: now), '2 days ago');
      expect(relativeDate(DateTime(2026, 10, 3), en, now: now), 'Oct 3');
      expect(relativeDate(DateTime(2025, 10, 3), en, now: now), 'Oct 3, 2025');
    });

    // protects=« le 3 oct. » only for dates; fails_when=« le il y a 6 jours »; no_claim=layout.
    test('a date is absolute from 7 calendar days', () {
      expect(isAbsoluteDate(DateTime(2026, 10, 5, 12), now: now), isFalse);
      expect(isAbsoluteDate(DateTime(2026, 10, 4, 12), now: now), isTrue);
      expect(isAbsoluteDate(now.subtract(const Duration(minutes: 5)), now: now), isFalse);
    });
  });

  // protects=« Déjà résumé le 3 oct. » / « Already summarized on Oct 3 » for old dates only;
  // fails_when=the prefix is dropped or added to a relative date; no_claim=the banner layout.
  test('the already-summarized banner date', () {
    final now = DateTime(2026, 10, 11, 10, 55);
    expect(bannerDate(DateTime(2026, 10, 9, 22), fr, now: now), 'il y a 2 jours');
    expect(bannerDate(DateTime(2026, 10, 3), fr, now: now), 'le 3 oct.');
    expect(bannerDate(DateTime(2026, 10, 9, 22), en, now: now), '2 days ago');
    expect(bannerDate(DateTime(2026, 10, 3), en, now: now), 'on Oct 3');
  });

  // protects=English labels and number formats; fails_when=a French label or format shows in
  // English; no_claim=how they fit on screen.
  test('labels and numbers in English', () {
    expect(emotionLabel('joy', en), 'joy');
    expect(emotionLabel('excitement', fr), 'enthousiasme');
    expect(emotionLabel('unknown-emotion', en), 'unknown-emotion');
    expect(sentimentLabel(Sentiment.negative, en), 'Negative');
    expect(toxicityLabel(0.7, en), 'High toxicity');
    expect(toxicityLabel(null, en), 'Toxicity —');
    expect(percent(0.45, en), '45%');
    expect(percent(0.45, fr), '45 %');
    expect(compactNumber(1234, en), '1.23K');
  });
}
