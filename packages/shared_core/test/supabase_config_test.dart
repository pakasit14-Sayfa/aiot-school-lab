import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/services/supabase_config.dart';

/// 2026-09-17: the first store build would have shipped pointing at
/// 127.0.0.1 because the localhost default applied in release mode too.
/// 2026-09-21: the same default was still silently accepted by a *debug*
/// build on a handset, where 127.0.0.1 is the phone — it read as "login is
/// broken" with nothing in the logs.
void main() {
  test('a debug desktop build without dart-defines falls back to local Docker',
      () {
    expect(
      () => SupabaseConfig.assertConfigured(
          release: false, isWeb: false, platform: TargetPlatform.macOS),
      returnsNormally,
    );
    expect(SupabaseConfig.url, 'http://127.0.0.1:54321');
  });

  test('a debug web build without dart-defines falls back to local Docker', () {
    expect(
      () => SupabaseConfig.assertConfigured(release: false, isWeb: true),
      returnsNormally,
    );
  });

  test('a release build without dart-defines refuses to start', () {
    expect(
      () => SupabaseConfig.assertConfigured(release: true),
      throwsA(isA<StateError>().having(
          (e) => e.message, 'message', SupabaseConfig.missingProdEnvMessage)),
    );
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    test('a debug $platform build without dart-defines refuses to start', () {
      expect(
        () => SupabaseConfig.assertConfigured(
            release: false, isWeb: false, platform: platform),
        throwsA(isA<StateError>().having((e) => e.message, 'message',
            SupabaseConfig.missingMobileEnvMessage)),
      );
    });
  }

  test('web on a phone browser still falls back — isWeb wins over platform',
      () {
    expect(
      () => SupabaseConfig.assertConfigured(
          release: false, isWeb: true, platform: TargetPlatform.iOS),
      returnsNormally,
    );
  });
}
