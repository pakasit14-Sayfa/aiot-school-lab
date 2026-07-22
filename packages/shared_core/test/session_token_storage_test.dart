import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/services/session_token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class FakeSecureValueStore implements SecureValueStore {
  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSecureValueStore secureStore;
  late SessionTokenStorage storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    secureStore = FakeSecureValueStore();
    storage = SessionTokenStorage(secureStore: secureStore);
  });

  test('migrates a legacy token and removes the plaintext copy', () async {
    SharedPreferences.setMockInitialValues({
      SessionTokenStorage.key: 'legacy-token',
    });

    expect(await storage.readAndMigrate(), 'legacy-token');
    expect(secureStore.values[SessionTokenStorage.key], 'legacy-token');
    expect(
      (await SharedPreferences.getInstance()).containsKey(
        SessionTokenStorage.key,
      ),
      isFalse,
    );
  });

  test('keeps the secure token and deletes a stale legacy token', () async {
    secureStore.values[SessionTokenStorage.key] = 'secure-token';
    SharedPreferences.setMockInitialValues({
      SessionTokenStorage.key: 'stale-token',
    });

    expect(await storage.readAndMigrate(), 'secure-token');
    expect(secureStore.values[SessionTokenStorage.key], 'secure-token');
    expect(
      (await SharedPreferences.getInstance()).containsKey(
        SessionTokenStorage.key,
      ),
      isFalse,
    );
  });

  test('writes and deletes only in secure storage', () async {
    await storage.write('new-token');
    expect(secureStore.values[SessionTokenStorage.key], 'new-token');

    await storage.delete();
    expect(secureStore.values, isEmpty);
  });
}
