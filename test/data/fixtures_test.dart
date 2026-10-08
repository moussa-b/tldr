import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tldr/core/errors.dart';
import 'package:tldr/data/models/models.dart';

/// Replaces the OpenAPI contract test (R6) since the backend was dropped:
/// every fixture must parse with the app models.
void main() {
  Map<String, dynamic> read(String path) =>
      jsonDecode(File('assets/fixtures/api/$path').readAsStringSync()) as Map<String, dynamic>;

  test('summaries parse and respect the analysis bounds', () {
    for (final f in ['summary_en_long.json', 'summary_fr.json', 'summary_link.json']) {
      final r = SummaryResult.fromJson(read(f));
      expect(r.analysis.emotions, isNotEmpty, reason: f);
      expect(r.analysis.emotions.length, lessThanOrEqualTo(4), reason: f);
      expect(r.thread.id, matches(RegExp(r'^[a-z0-9]{5,10}$')), reason: f);
    }
  });

  test('catalog has exactly one default model per provider and matches the bundled copy', () {
    final catalog = ProviderCatalog.fromJson(read('models.json'));
    expect(catalog.providers.map((p) => p.id).toSet(), ProviderId.values.toSet());
    for (final p in catalog.providers) {
      expect(p.models.where((m) => m.isDefault), hasLength(1), reason: p.id.name);
    }
    final bundled = File('assets/catalog.json').readAsStringSync();
    expect(jsonDecode(bundled), read('models.json'));
  });

  test('translation and key fixtures parse', () {
    expect(TranslationResult.fromJson(read('translation_fr.json')).analysis.language, 'fr');
    expect(KeyValidation.fromJson(read('key_valid.json')).valid, isTrue);
    expect(KeyValidation.fromJson(read('key_invalid.json')).valid, isFalse);
  });

  test('error fixtures parse', () {
    for (final f in Directory('assets/fixtures/api/errors').listSync().whereType<File>()) {
      final e = ApiError.fromBody(jsonDecode(f.readAsStringSync()) as Map<String, dynamic>);
      expect(e.code, isNotEmpty, reason: f.path);
    }
  });
}
