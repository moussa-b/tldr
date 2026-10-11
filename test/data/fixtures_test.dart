import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tldr/data/models/models.dart';

/// The demo summary, the test fixtures and the bundled catalog must parse
/// with the app models.
void main() {
  Map<String, dynamic> read(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  test('summaries parse and respect the analysis bounds', () {
    for (final f in [
      'assets/demo/summary_fr.json',
      'test/fixtures/summary_en_long.json',
      'test/fixtures/summary_link.json',
    ]) {
      final r = SummaryResult.fromJson(read(f));
      expect(r.analysis.emotions, isNotEmpty, reason: f);
      expect(r.analysis.emotions.length, lessThanOrEqualTo(4), reason: f);
      expect(r.thread.id, matches(RegExp(r'^[a-z0-9]{5,10}$')), reason: f);
    }
  });

  test('catalog has exactly one default model per provider', () {
    final catalog = ProviderCatalog.fromJson(read('assets/catalog.json'));
    expect(catalog.providers.map((p) => p.id).toSet(), ProviderId.values.toSet());
    for (final p in catalog.providers) {
      expect(p.models.where((m) => m.isDefault), hasLength(1), reason: p.id.name);
    }
  });

  test('translation fixture parses', () {
    expect(TranslationResult.fromJson(read('test/fixtures/translation_fr.json')).analysis.language,
        'fr');
  });
}
