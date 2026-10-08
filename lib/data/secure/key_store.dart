import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/models.dart';

/// LLM API keys live only in the platform secure storage (Keychain /
/// Keystore), never in SQLite or logs.
abstract interface class KeyStore {
  Future<String?> read(ProviderId provider);
  Future<void> write(ProviderId provider, String key);
  Future<void> delete(ProviderId provider);
}

class SecureKeyStore implements KeyStore {
  SecureKeyStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions:
                  IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
            );

  final FlutterSecureStorage _storage;

  static String _name(ProviderId provider) => 'llmKey.${provider.name}';

  @override
  Future<String?> read(ProviderId provider) async {
    final value = await _storage.read(key: _name(provider));
    return (value == null || value.trim().isEmpty) ? null : value;
  }

  @override
  Future<void> write(ProviderId provider, String key) =>
      _storage.write(key: _name(provider), value: key.trim());

  @override
  Future<void> delete(ProviderId provider) => _storage.delete(key: _name(provider));
}

/// In-memory store for tests.
class MemoryKeyStore implements KeyStore {
  MemoryKeyStore([Map<ProviderId, String>? initial]) : _keys = {...?initial};

  final Map<ProviderId, String> _keys;

  @override
  Future<String?> read(ProviderId provider) async => _keys[provider];

  @override
  Future<void> write(ProviderId provider, String key) async => _keys[provider] = key.trim();

  @override
  Future<void> delete(ProviderId provider) async => _keys.remove(provider);
}
