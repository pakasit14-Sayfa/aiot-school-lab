import 'dart:convert';

import 'session_token_storage.dart';

/// Persists "remember this device" trust tokens so a device that already
/// completed login OTP once for a given (email, role, schoolId) can skip
/// OTP on future logins for that exact combo — see [[trusted_devices]]
/// migration `20260829000000_trusted_devices_remember_login.sql`.
///
/// Stored as a single secure-storage entry holding a JSON map keyed by
/// `email|role|schoolId`, since one device can hold trust for more than
/// one role (multi-role accounts) at once. Never persists anything about
/// the password step — this class only ever shortens the OTP step.
final class DeviceTrustTokenStorage {
  DeviceTrustTokenStorage({
    SecureValueStore secureStore = const FlutterSecureValueStore(),
  }) : _secureStore = secureStore;

  static const _storageKey = 'device_trust_tokens';

  final SecureValueStore _secureStore;

  static String _mapKey(String email, String role, String? schoolId) =>
      '${email.trim().toLowerCase()}|$role|${schoolId ?? ''}';

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

  /// Trust token for this exact (email, role, schoolId), if this device
  /// has one stored — null if never remembered or since forgotten.
  Future<String?> read({
    required String email,
    required String role,
    String? schoolId,
  }) async {
    final all = await _readAll();
    return all[_mapKey(email, role, schoolId)];
  }

  Future<void> save({
    required String email,
    required String role,
    String? schoolId,
    required String token,
  }) async {
    final all = await _readAll();
    all[_mapKey(email, role, schoolId)] = token;
    await _writeAll(all);
  }

  /// Best-effort lookup when the role isn't known yet (the single-role
  /// sign-in call happens before the server has told us which role this
  /// account has) — returns any token stored for this email, since the
  /// server-side check re-validates role/school anyway and simply won't
  /// match if it's the wrong one.
  Future<String?> readAnyForEmail(String email) async {
    final all = await _readAll();
    final prefix = '${email.trim().toLowerCase()}|';
    for (final entry in all.entries) {
      if (entry.key.startsWith(prefix)) return entry.value;
    }
    return null;
  }

  Future<void> clearAll() => _secureStore.delete(_storageKey);
}
