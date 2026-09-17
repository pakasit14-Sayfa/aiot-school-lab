import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:supabase_flutter/supabase_flutter.dart';
export 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase connection settings are injected at build time via:
///   flutter run --dart-define-from-file=env.json        (local Docker)
///   flutter build apk --dart-define-from-file=env.prod.json   (production)
///
/// If not supplied, it defaults to local Supabase Docker development — except
/// in a release build, where that default would ship an app that silently
/// points at 127.0.0.1 on the user's phone. There it throws instead.
class SupabaseConfig {
  static const String _defaultUrl = 'http://127.0.0.1:54321';
  static const String _defaultKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

  static const String _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _envKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get url => _envUrl.isNotEmpty ? _envUrl : _defaultUrl;
  static String get publishableKey => _envKey.isNotEmpty ? _envKey : _defaultKey;

  /// Message of the error thrown when a release build was made without
  /// `--dart-define-from-file=env.prod.json`.
  static const String missingProdEnvMessage =
      'Release build has no SUPABASE_URL — build with '
      '--dart-define-from-file=env.prod.json';

  static void assertConfigured({bool release = kReleaseMode}) {
    if (release && _envUrl.isEmpty) throw StateError(missingProdEnvMessage);
  }

  static Future<void> initialize() async {
    assertConfigured();
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }
}

SupabaseClient get supabase => Supabase.instance.client;
