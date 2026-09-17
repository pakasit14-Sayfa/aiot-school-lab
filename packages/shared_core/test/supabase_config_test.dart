import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/services/supabase_config.dart';

/// 2026-09-17: the first store build would have shipped pointing at
/// 127.0.0.1 because the localhost default applied in release mode too.
void main() {
  test('a debug build without dart-defines falls back to local Docker', () {
    expect(() => SupabaseConfig.assertConfigured(release: false), returnsNormally);
    expect(SupabaseConfig.url, 'http://127.0.0.1:54321');
  });

  test('a release build without dart-defines refuses to start', () {
    expect(
      () => SupabaseConfig.assertConfigured(release: true),
      throwsA(isA<StateError>().having(
          (e) => e.message, 'message', SupabaseConfig.missingProdEnvMessage)),
    );
  });
}
