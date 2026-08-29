import 'dart:convert';

import 'session_token_storage.dart';

/// Persists "remember this device" trust tokens so a device that already
/// completed login OTP once for an account can skip OTP on future logins
/// — for *every* role that account holds, not just the one that was
/// active when the checkbox was ticked. See [[trusted_devices]]
/// migrations `20260829000000_trusted_devices_remember_login.sql` and
/// `20260829010000_trusted_devices_account_wide.sql`.
///
/// Stored as a single secure-storage entry holding a JSON map keyed by
/// email (lowercased), one token per account this device has ever
/// remembered. Never persists anything about the password step — this
/// class only ever shortens the OTP step.
final class DeviceTrustTokenStorage {
  DeviceTrustTokenStorage({
    SecureValueStore secureStore = const FlutterSecureValueStore(),
  }) : _secureStore = secureStore;

  static const _storageKey = 'device_trust_tokens';

  final SecureValueStore _secureStore;

  Future<Map<String, String>> _readAll() async {
    final raw = await _secureStore.read(_storageKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeAll(Map<String, String> tokens) async {
    if (tokens.isEmpty) {
      await _secureStore.delete(_storageKey);
      return;
    }
    await _secureStore.write(_storageKey, jsonEncode(tokens));
  }

  /// Trust token for this email, if this device has one stored — null if
  /// never remembered or since forgotten. Covers every role on the
  /// account; the server re-validates the token regardless.
  Future<String?> read(String email) async {
    final all = await _readAll();
    return all[email.trim().toLowerCase()];
  }

  Future<void> save({required String email, required String token}) async {
    final all = await _readAll();
    all[email.trim().toLowerCase()] = token;
    await _writeAll(all);
  }

  Future<void> clearAll() => _secureStore.delete(_storageKey);
}
