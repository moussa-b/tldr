import 'dart:convert';
import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

/// A summary request started but not finished (eng review R2).
class PendingSummary {
  const PendingSummary({
    required this.idempotencyKey,
    required this.url,
    required this.provider,
    required this.model,
    required this.startedAt,
  });

  final String idempotencyKey;
  final String url;
  final ProviderId provider;
  final String? model;
  final DateTime startedAt;

  static const maxAge = Duration(minutes: 10);

  bool isFresh(DateTime now) => now.difference(startedAt) < maxAge;

  Map<String, dynamic> toJson() => {
        'idempotencyKey': idempotencyKey,
        'url': url,
        'provider': provider.name,
        'model': model,
        'startedAt': startedAt.toUtc().toIso8601String(),
      };

  factory PendingSummary.fromJson(Map<String, dynamic> json) => PendingSummary(
        idempotencyKey: json['idempotencyKey'] as String,
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

  static const _deviceId = 'redditDeviceId';
  String _deviceIdCache = '';

  /// Random per-install id required by Reddit's installed-app OAuth.
  /// Loaded by [init] at startup.
  String get deviceIdSync => _deviceIdCache;

  Future<void> init() async {
    var id = await _get(_deviceId);
    if (id == null) {
      final random = Random.secure();
      id = List.generate(24, (_) => random.nextInt(36).toRadixString(36)).join();
      await _set(_deviceId, id);
    }
    _deviceIdCache = id;
  }

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
