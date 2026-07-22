import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SecureValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

final class FlutterSecureValueStore implements SecureValueStore {
  const FlutterSecureValueStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Owns the bearer-token persistence boundary.
///
/// SharedPreferences is consulted only once to migrate installations that
/// predate secure storage. The legacy value is always removed, including when
/// secure storage already contains a newer token.
final class SessionTokenStorage {
  SessionTokenStorage({
    SecureValueStore secureStore = const FlutterSecureValueStore(),
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _secureStore = secureStore,
       _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static const key = 'session_token';

  final SecureValueStore _secureStore;
  final Future<SharedPreferences> Function() _preferencesLoader;

  Future<String?> readAndMigrate() async {
    final preferences = await _preferencesLoader();
    var token = await _secureStore.read(key);
    final legacyToken = preferences.getString(key);

    if (token == null && legacyToken != null) {
      await _secureStore.write(key, legacyToken);
      token = legacyToken;
    }

    await preferences.remove(key);
    return token;
  }

  Future<void> write(String token) => _secureStore.write(key, token);

  Future<void> delete() => _secureStore.delete(key);
}
