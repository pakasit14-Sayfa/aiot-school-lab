import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, kReleaseMode;
import 'package:supabase_flutter/supabase_flutter.dart';
export 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase connection settings are injected at build time via:
///   flutter run --dart-define-from-file=env.json        (local Docker)
///   flutter build apk --dart-define-from-file=env.prod.json   (production)
///
/// If not supplied, it defaults to local Supabase Docker development. That
/// default is only ever reachable from the dev machine itself — a desktop or
/// Chrome build. Two cases would otherwise ship/run an app silently pointing
/// at a 127.0.0.1 that is the *phone*, so both throw instead:
///   - any release build (this would have gone to the store, 2026-09-17), and
///   - any build for a phone at all, debug included: an iOS simulator can
///     still reach the Mac's localhost, but a real handset never can, and a
///     debug run on a handset with no dart-defines looks exactly like "login
///     is broken" with nothing in the logs to say why.
/// So on iOS/Android the dart-define file is mandatory in every mode — which
/// is what the documented run commands pass anyway.
class SupabaseConfig {
  static const String _defaultUrl = 'http://127.0.0.1:54321';
  static const String _defaultKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

  static const String _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _envKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get url => _envUrl.isNotEmpty ? _envUrl : _defaultUrl;
  static String get publishableKey =>
      _envKey.isNotEmpty ? _envKey : _defaultKey;

  /// Message of the error thrown when a release build was made without
  /// `--dart-define-from-file=env.prod.json`.
  static const String missingProdEnvMessage =
      'Release build has no SUPABASE_URL — build with '
      '--dart-define-from-file=env.prod.json';

  /// Message of the error thrown when a phone build — debug included — was
  /// made without any dart-define file. The localhost default would resolve
  /// to the handset itself and every request would fail with no clue why.
  static const String missingMobileEnvMessage =
      'Mobile build has no SUPABASE_URL — the localhost default points at the '
      'phone itself. Build with --dart-define-from-file=env.prod.json '
      '(production) or =env.json (local Docker, simulator only)';

  static void assertConfigured({
    bool release = kReleaseMode,
    bool isWeb = kIsWeb,
    TargetPlatform? platform,
  }) {
    if (_envUrl.isNotEmpty) return;
    if (release) throw StateError(missingProdEnvMessage);
    if (isWeb) return;
    final target = platform ?? defaultTargetPlatform;
    if (target == TargetPlatform.iOS || target == TargetPlatform.android) {
      throw StateError(missingMobileEnvMessage);
    }
  }

  static Future<void> initialize() async {
    assertConfigured();
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }
}

SupabaseClient get supabase => Supabase.instance.client;
