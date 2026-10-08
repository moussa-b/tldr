import 'package:intl/intl.dart';

import '../data/models/models.dart';

/// French labels and emoji (spec section « Écrans », D-15).
const emotionLabels = {
  'joy': 'joie',
  'sadness': 'tristesse',
  'anger': 'colère',
  'fear': 'peur',
  'disgust': 'dégoût',
  'surprise': 'surprise',
  'love': 'amour',
  'pride': 'fierté',
  'relief': 'soulagement',
  'hope': 'espoir',
  'excitement': 'enthousiasme',
  'envy': 'envie',
  'guilt': 'culpabilité',
  'shame': 'honte',
  'neutral': 'neutre',
};

String emotionLabel(String emotion) => emotionLabels[emotion] ?? emotion;

String sentimentLabel(Sentiment s) => switch (s) {
      Sentiment.positive => 'Positif',
      Sentiment.negative => 'Négatif',
      Sentiment.neutral => 'Neutre',
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

String toxicityLabel(double? value) => switch (toxicityLevel(value)) {
      ToxicityLevel.low => 'Toxicité faible',
      ToxicityLevel.moderate => 'Toxicité modérée',
      ToxicityLevel.high => 'Toxicité élevée',
      ToxicityLevel.unknown => 'Toxicité —',
    };

/// « il y a 14 h », « hier », « 3 oct. ».
String relativeDate(DateTime date, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final local = date.toLocal();
  final diff = current.difference(local);
  if (diff.inMinutes < 1) return 'à l\'instant';
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24 && local.day == current.day) return 'il y a ${diff.inHours} h';
  final yesterday = DateTime(current.year, current.month, current.day - 1);
  if (local.year == yesterday.year && local.month == yesterday.month && local.day == yesterday.day) {
    return 'hier';
  }
  if (diff.inDays < 7) return 'il y a ${diff.inDays.clamp(1, 6)} jours';
  final sameYear = local.year == current.year;
  return DateFormat(sameYear ? 'd MMM' : 'd MMM y', 'fr_FR').format(local);
}

String compactNumber(int value) => NumberFormat.compact(locale: 'fr_FR').format(value);

String percent(double ratio) => '${(ratio * 100).round()} %';
