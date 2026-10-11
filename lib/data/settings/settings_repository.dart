import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

/// A summary request started but not finished, replayed when the app comes
/// back (eng review R2, spec D-20).
class PendingSummary {
  const PendingSummary({
    required this.url,
    required this.provider,
    required this.model,
    required this.startedAt,
  });

  final String url;
  final ProviderId provider;
  final String? model;
  final DateTime startedAt;

  static const maxAge = Duration(minutes: 10);

  bool isFresh(DateTime now) => now.difference(startedAt) < maxAge;

  Map<String, dynamic> toJson() => {
        'url': url,
        'provider': provider.name,
        'model': model,
        'startedAt': startedAt.toUtc().toIso8601String(),
      };

  factory PendingSummary.fromJson(Map<String, dynamic> json) => PendingSummary(
        url: json['url'] as String,
        provider: ProviderId.fromJson(json['provider'] as String),
        model: json['model'] as String?,
        startedAt: DateTime.parse(json['startedAt'] as String),
      );
}

/// Key/value settings stored in the `settings` table. Never stores API keys.
class SettingsRepository {
  SettingsRepository(this._db);

  final Database _db;

  static const _activeProvider = 'activeProvider';
  static const _catalog = 'catalogJson';
  static const _pending = 'pendingSummary';
  static String _modelKey(ProviderId p) => 'model.${p.name}';

  Future<String?> _get(String key) async {
    final rows = await _db.query('settings', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value']! as String;
  }

  Future<void> _set(String key, String value) => _db.insert(
      'settings', {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> _remove(String key) =>
      _db.delete('settings', where: 'key = ?', whereArgs: [key]);

  /// Defaults to Gemini (spec D-11).
  Future<ProviderId> activeProvider() async {
    final value = await _get(_activeProvider);
    return value == null ? ProviderId.gemini : ProviderId.fromJson(value);
  }

  Future<void> setActiveProvider(ProviderId provider) =>
      _set(_activeProvider, provider.name);

  Future<String?> model(ProviderId provider) => _get(_modelKey(provider));

  Future<void> setModel(ProviderId provider, String modelId) =>
      _set(_modelKey(provider), modelId);

  Future<ProviderCatalog?> cachedCatalog() async {
    final value = await _get(_catalog);
    if (value == null) return null;
    return ProviderCatalog.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  Future<void> cacheCatalog(ProviderCatalog catalog) =>
      _set(_catalog, jsonEncode(catalog.toJson()));

  Future<PendingSummary?> pendingSummary() async {
    final value = await _get(_pending);
    if (value == null) return null;
    return PendingSummary.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  Future<void> setPendingSummary(PendingSummary pending) =>
      _set(_pending, jsonEncode(pending.toJson()));

  Future<void> clearPendingSummary() => _remove(_pending);
}
