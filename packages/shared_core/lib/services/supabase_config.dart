import 'package:supabase_flutter/supabase_flutter.dart';
export 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase connection settings are injected at build time via:
///   flutter run --dart-define-from-file=env.json
///
/// If not supplied, it safely defaults to local Supabase Docker development.
class SupabaseConfig {
  static const String _defaultUrl = 'http://127.0.0.1:54321';
  static const String _defaultKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

  static const String _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _envKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get url => _envUrl.isNotEmpty ? _envUrl : _defaultUrl;
  static String get publishableKey => _envKey.isNotEmpty ? _envKey : _defaultKey;

  static Future<void> initialize() async {
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }
}

SupabaseClient get supabase => Supabase.instance.client;
