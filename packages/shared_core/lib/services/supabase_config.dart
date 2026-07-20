import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase connection settings are injected at build time so no
/// environment-specific values live in source control:
///
///   flutter run --dart-define-from-file=env.json
///
/// Copy env.example.json (repo root) to env.json and fill it in.
class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static Future<void> initialize() async {
    if (url.isEmpty || publishableKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL / SUPABASE_ANON_KEY are not set. '
        'Run with --dart-define-from-file=env.json '
        '(copy env.example.json to env.json first).',
      );
    }
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }
}

SupabaseClient get supabase => Supabase.instance.client;
