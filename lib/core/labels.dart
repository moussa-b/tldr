import 'package:intl/intl.dart';

import '../data/models/models.dart';
import '../l10n/app_localizations.dart';

/// Labels and emoji in the app's language (spec section « Écrans », D-15).
String emotionLabel(String emotion, AppLocalizations l) => switch (emotion) {
      'joy' => l.emotionJoy,
      'sadness' => l.emotionSadness,
      'anger' => l.emotionAnger,
      'fear' => l.emotionFear,
      'disgust' => l.emotionDisgust,
      'surprise' => l.emotionSurprise,
      'love' => l.emotionLove,
      'pride' => l.emotionPride,
      'relief' => l.emotionRelief,
      'hope' => l.emotionHope,
      'excitement' => l.emotionExcitement,
      'envy' => l.emotionEnvy,
      'guilt' => l.emotionGuilt,
      'shame' => l.emotionShame,
      'neutral' => l.emotionNeutral,
      _ => emotion,
    };

String sentimentLabel(Sentiment s, AppLocalizations l) => switch (s) {
      Sentiment.positive => l.sentimentPositive,
      Sentiment.negative => l.sentimentNegative,
      Sentiment.neutral => l.sentimentNeutral,
    };

/// History list only (D-15: no emoji on the summary screen).
String sentimentEmoji(Sentiment s) => switch (s) {
      Sentiment.positive => '🙂',
      Sentiment.negative => '🙁',
      Sentiment.neutral => '😐',
    };

enum ToxicityLevel { low, moderate, high, unknown }

ToxicityLevel toxicityLevel(double? value) {
  if (value == null) return ToxicityLevel.unknown;
  if (value < 0.3) return ToxicityLevel.low;
  if (value <= 0.6) return ToxicityLevel.moderate;
  return ToxicityLevel.high;
}

String toxicityLabel(double? value, AppLocalizations l) => switch (toxicityLevel(value)) {
      ToxicityLevel.low => l.toxicityLow,
      ToxicityLevel.moderate => l.toxicityModerate,
      ToxicityLevel.high => l.toxicityHigh,
      ToxicityLevel.unknown => l.toxicityUnknown,
    };

/// Whole calendar days between [date] and [now].
int _calendarDays(DateTime date, DateTime now) {
  final local = date.toLocal();
  return (DateTime(now.year, now.month, now.day)
                  .difference(DateTime(local.year, local.month, local.day))
                  .inHours /
              24)
          .round();
}

/// True when [relativeDate] shows a date rather than a time ago.
bool isAbsoluteDate(DateTime date, {DateTime? now}) =>
    _calendarDays(date, now ?? DateTime.now()) >= 7;

/// « il y a 14 h », « hier », « 3 oct. » (or « 14h ago », « yesterday », « Oct 3 »).
String relativeDate(DateTime date, AppLocalizations l, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final local = date.toLocal();
  final diff = current.difference(local);
  if (diff.inMinutes < 1) return l.relativeJustNow;
  if (diff.inMinutes < 60) return l.relativeMinutes('${diff.inMinutes}');
  if (diff.inHours < 24 && local.day == current.day) return l.relativeHours('${diff.inHours}');
  final yesterday = DateTime(current.year, current.month, current.day - 1);
  if (local.year == yesterday.year && local.month == yesterday.month && local.day == yesterday.day) {
    return l.relativeYesterday;
  }
  // Calendar days: two days back is « 2 jours » even when under 48 h ago.
  final days = _calendarDays(date, current);
  if (days < 7) return l.relativeDays('${days.clamp(2, 6)}');
  final sameYear = local.year == current.year;
  return DateFormat(sameYear ? l.dateShortPattern : l.dateLongPattern, l.localeName)
      .format(local);
}

/// The date in « Déjà résumé … »: « il y a 2 jours », or « le 3 oct. » for an
/// older one (« 2 days ago », « on Oct 3 »).
String bannerDate(DateTime date, AppLocalizations l, {DateTime? now}) {
  final label = relativeDate(date, l, now: now);
  return isAbsoluteDate(date, now: now) ? l.summaryBannerOnDate(label) : label;
}

String compactNumber(int value, AppLocalizations l) =>
    NumberFormat.compact(locale: l.localeName).format(value);

String percent(double ratio, AppLocalizations l) => l.percentValue('${(ratio * 100).round()}');
