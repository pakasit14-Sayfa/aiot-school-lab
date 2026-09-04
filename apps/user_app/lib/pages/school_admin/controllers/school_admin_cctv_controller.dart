import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';

import 'school_admin_async_state.dart';

typedef SchoolAdminCctvGrantsLoader =
    Future<List<CameraAccessGrantItem>> Function();
typedef SchoolAdminCctvUsersLoader = Future<List<UserModel>> Function();
typedef SchoolAdminCctvGrantAccess =
    Future<String?> Function({
      required String userId,
      String? cameraDeviceId,
      required String reason,
      required DateTime validUntil,
    });
typedef SchoolAdminCctvRevokeAccess = Future<bool> Function(String grantId);

final class SchoolAdminCctvSnapshot {
  SchoolAdminCctvSnapshot({
    required List<CameraAccessGrantItem> grants,
    required List<UserModel> users,
  }) : grants = List<CameraAccessGrantItem>.unmodifiable(grants),
       users = List<UserModel>.unmodifiable(users);

  final List<CameraAccessGrantItem> grants;
  final List<UserModel> users;
}

final class SchoolAdminCctvController extends ChangeNotifier {
  SchoolAdminCctvController({
    required SchoolAdminCctvGrantsLoader loadGrants,
    required SchoolAdminCctvUsersLoader loadUsers,
    required SchoolAdminCctvGrantAccess grantAccess,
    required SchoolAdminCctvRevokeAccess revokeAccess,
  }) : _loadGrants = loadGrants,
       _loadUsers = loadUsers,
       _grantAccess = grantAccess,
       _revokeAccess = revokeAccess;

  final SchoolAdminCctvGrantsLoader _loadGrants;
  final SchoolAdminCctvUsersLoader _loadUsers;
  final SchoolAdminCctvGrantAccess _grantAccess;
  final SchoolAdminCctvRevokeAccess _revokeAccess;

  SchoolAdminAsyncState<SchoolAdminCctvSnapshot> _state =
      const SchoolAdminLoading<SchoolAdminCctvSnapshot>();
  SchoolAdminCctvSnapshot? _lastConfirmedData;
  bool _isMutating = false;
  bool _disposed = false;

  SchoolAdminAsyncState<SchoolAdminCctvSnapshot> get state => _state;
  bool get isMutating => _isMutating;

  Future<void> load() async {
    final previousData = _lastConfirmedData;
    _publish(SchoolAdminLoading(previousData: previousData));
    try {
      _publishCanonical(await _loadCanonical());
    } catch (error, stackTrace) {
      _publish(
        SchoolAdminError(
          message: 'โหลดข้อมูลสิทธิ์กล้อง CCTV ไม่สำเร็จ',
          error: error,
          stackTrace: stackTrace,
          previousData: previousData,
        ),
      );
    }
  }

  Future<bool> grant({
    required String userId,
    String? cameraDeviceId,
    required String reason,
    required DateTime validUntil,
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedReason = reason.trim();
    if (_disposed ||
        _isMutating ||
        normalizedUserId.isEmpty ||
        normalizedReason.isEmpty) {
      return false;
    }

    return _runMutation(
      failureMessage: 'บันทึกสิทธิ์กล้อง CCTV ไม่สำเร็จ',
      action: () async {
        final grantId = await _grantAccess(
          userId: normalizedUserId,
          cameraDeviceId: cameraDeviceId?.trim().isEmpty == true
              ? null
              : cameraDeviceId?.trim(),
          reason: normalizedReason,
          validUntil: validUntil,
        );
        final normalizedGrantId = grantId?.trim();
        if (normalizedGrantId == null || normalizedGrantId.isEmpty) {
          throw StateError('backend_grant_id_missing');
        }

        final snapshot = await _loadCanonical();
        final confirmed = snapshot.grants.any(
          (grant) => grant.grantId == normalizedGrantId && grant.isActive,
        );
        if (!confirmed) throw StateError('backend_grant_not_confirmed');
        return snapshot;
      },
    );
  }

  Future<bool> revoke(String grantId) async {
    final normalizedGrantId = grantId.trim();
    if (_disposed || _isMutating || normalizedGrantId.isEmpty) return false;

    return _runMutation(
      failureMessage: 'เพิกถอนสิทธิ์กล้อง CCTV ไม่สำเร็จ',
      action: () async {
        final accepted = await _revokeAccess(normalizedGrantId);
        if (!accepted) throw StateError('backend_revoke_rejected');

        final snapshot = await _loadCanonical();
        final confirmed = snapshot.grants.any(
          (grant) => grant.grantId == normalizedGrantId && !grant.isActive,
        );
        if (!confirmed) throw StateError('backend_revoke_not_confirmed');
        return snapshot;
      },
    );
  }

  Future<bool> _runMutation({
    required String failureMessage,
    required Future<SchoolAdminCctvSnapshot> Function() action,
  }) async {
    final previousData = _lastConfirmedData;
    _isMutating = true;
    _notifySafely();
    try {
      _publishCanonical(await action());
      return true;
    } catch (error, stackTrace) {
      _publish(
        SchoolAdminError(
          message: failureMessage,
          error: error,
          stackTrace: stackTrace,
          previousData: previousData,
        ),
      );
      return false;
    } finally {
      _isMutating = false;
      _notifySafely();
    }
  }

  Future<SchoolAdminCctvSnapshot> _loadCanonical() async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _loadGrants(),
      _loadUsers(),
    ]);
    return SchoolAdminCctvSnapshot(
      grants: results[0] as List<CameraAccessGrantItem>,
      users: results[1] as List<UserModel>,
    );
  }

  void _publishCanonical(SchoolAdminCctvSnapshot snapshot) {
    if (_disposed) return;
    _lastConfirmedData = snapshot;
    _publish(SchoolAdminData(snapshot));
  }

  void _publish(SchoolAdminAsyncState<SchoolAdminCctvSnapshot> nextState) {
    if (_disposed) return;
    _state = nextState;
    notifyListeners();
  }

  void _notifySafely() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
