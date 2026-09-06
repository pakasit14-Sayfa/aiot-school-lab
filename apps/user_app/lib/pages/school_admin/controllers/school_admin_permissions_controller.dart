import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';

import 'school_admin_async_state.dart';

typedef SchoolAdminPermissionsUserLoader = Future<List<UserModel>> Function();
typedef SchoolAdminPermissionsInvitationLoader =
    Future<List<StaffInvitation>> Function();
typedef SchoolAdminPermissionsLogLoader =
    Future<List<SchoolAdminAuditLog>> Function();
typedef SchoolAdminPermissionsRoleWriter =
    Future<void> Function({required String uid, required UserRole role});
typedef SchoolAdminPermissionsStatusWriter = Future<void> Function(String uid);
typedef SchoolAdminPermissionsInvitationCreator =
    Future<StaffInvitationTicket> Function({
      required String email,
      required UserRole role,
    });
typedef SchoolAdminPermissionsInvitationRevoker =
    Future<void> Function(String invitationId);

/// Server-confirmed view of the permissions page. Everything shown on the
/// page must come from here — there is no hardcoded roster, role table or
/// permission matrix behind this screen.
final class SchoolAdminPermissionsSnapshot {
  SchoolAdminPermissionsSnapshot({
    required List<UserModel> users,
    required List<StaffInvitation> invitations,
    required List<SchoolAdminAuditLog> logs,
  }) : users = List<UserModel>.unmodifiable(users),
       invitations = List<StaffInvitation>.unmodifiable(invitations),
       logs = List<SchoolAdminAuditLog>.unmodifiable(logs);

  final List<UserModel> users;
  final List<StaffInvitation> invitations;
  final List<SchoolAdminAuditLog> logs;

  bool get isEmpty => users.isEmpty && invitations.isEmpty && logs.isEmpty;

  List<StaffInvitation> get pendingInvitations =>
      invitations.where((invitation) => invitation.isPending).toList();

  int get activeUserCount =>
      users.where((user) => user.status == 'active').length;

  int get suspendedUserCount =>
      users.where((user) => user.status == 'suspended').length;

  /// Count per role using *membership in all_roles*, never equality on the
  /// collapsed `active_role`: a teacher who was later also granted
  /// school_admin has active_role = school_admin and would otherwise
  /// disappear from the teacher count entirely.
  Map<UserRole, int> get roleCounts => <UserRole, int>{
    for (final role in UserRole.values)
      role: users.where((user) => user.hasRole(role)).length,
  };
}

final class SchoolAdminPermissionsController extends ChangeNotifier {
  SchoolAdminPermissionsController({
    required SchoolAdminPermissionsUserLoader loadUsers,
    required SchoolAdminPermissionsInvitationLoader loadInvitations,
    required SchoolAdminPermissionsLogLoader loadLogs,
    required SchoolAdminPermissionsRoleWriter updateRole,
    required SchoolAdminPermissionsRoleWriter addSecondaryRole,
    required SchoolAdminPermissionsStatusWriter suspendUser,
    required SchoolAdminPermissionsStatusWriter reactivateUser,
    required SchoolAdminPermissionsInvitationCreator createInvitation,
    required SchoolAdminPermissionsInvitationRevoker revokeInvitation,
  }) : _loadUsers = loadUsers,
       _loadInvitations = loadInvitations,
       _loadLogs = loadLogs,
       _updateRole = updateRole,
       _addSecondaryRole = addSecondaryRole,
       _suspendUser = suspendUser,
       _reactivateUser = reactivateUser,
       _createInvitation = createInvitation,
       _revokeInvitation = revokeInvitation;

  /// Roles a school_admin may hand out. `super_admin` is excluded because
  /// `update_user_role` / `add_secondary_role` / `create_staff_invitation`
  /// all reject it for a school_admin actor (`forbidden_role_grant`).
  static const List<UserRole> assignableRoles = <UserRole>[
    UserRole.teacher,
    UserRole.schoolAdmin,
    UserRole.executive,
    UserRole.student,
    UserRole.parent,
  ];

  final SchoolAdminPermissionsUserLoader _loadUsers;
  final SchoolAdminPermissionsInvitationLoader _loadInvitations;
  final SchoolAdminPermissionsLogLoader _loadLogs;
  final SchoolAdminPermissionsRoleWriter _updateRole;
  final SchoolAdminPermissionsRoleWriter _addSecondaryRole;
  final SchoolAdminPermissionsStatusWriter _suspendUser;
  final SchoolAdminPermissionsStatusWriter _reactivateUser;
  final SchoolAdminPermissionsInvitationCreator _createInvitation;
  final SchoolAdminPermissionsInvitationRevoker _revokeInvitation;

  SchoolAdminAsyncState<SchoolAdminPermissionsSnapshot> _state =
      const SchoolAdminLoading<SchoolAdminPermissionsSnapshot>();
  SchoolAdminPermissionsSnapshot? _lastConfirmedData;
  final Set<String> _busyKeys = <String>{};
  StaffInvitationTicket? _lastIssuedTicket;
  bool _disposed = false;

  SchoolAdminAsyncState<SchoolAdminPermissionsSnapshot> get state => _state;
  SchoolAdminPermissionsSnapshot? get lastConfirmedData => _lastConfirmedData;

  /// The one-time invitation token from the most recent successful invite.
  /// There is no way to re-read it from the backend (only its sha256 hash is
  /// stored), so the page must show it immediately after issuing.
  StaffInvitationTicket? get lastIssuedTicket => _lastIssuedTicket;

  bool get isInviting => _busyKeys.contains('invite');
  bool isUserBusy(String uid) => _busyKeys.contains('user:${uid.trim()}');
  bool isInvitationBusy(String id) =>
      _busyKeys.contains('invitation:${id.trim()}');

  Future<void> load() async {
    final previous = _lastConfirmedData;
    _publish(SchoolAdminLoading(previousData: previous));
    try {
      _publishCanonical(await _loadCanonical());
    } catch (error, stackTrace) {
      _publish(
        SchoolAdminError(
          message: 'โหลดข้อมูลสิทธิ์ผู้ใช้งานไม่สำเร็จ',
          error: error,
          stackTrace: stackTrace,
          previousData: previous,
        ),
      );
    }
  }

  /// Replaces the user's role set with [role] (`update_user_role` deletes the
  /// previous roles in this school and inserts one clean row).
  Future<bool> changePrimaryRole({
    required String uid,
    required UserRole role,
  }) async {
    final id = uid.trim();
    if (id.isEmpty || !assignableRoles.contains(role)) return false;
    return _runMutation(
      key: 'user:$id',
      failureMessage: 'เปลี่ยนบทบาทไม่สำเร็จ',
      action: () async {
        await _updateRole(uid: id, role: role);
        final canonical = await _loadCanonical();
        final updated = _findUser(canonical, id);
        if (updated == null ||
            updated.allRoles.length != 1 ||
            !updated.hasRole(role)) {
          throw StateError('backend_role_change_not_confirmed');
        }
        return canonical;
      },
    );
  }

  /// Grants an *extra* role without removing the existing ones — an account
  /// in this app can legitimately hold more than one role.
  Future<bool> grantSecondaryRole({
    required String uid,
    required UserRole role,
  }) async {
    final id = uid.trim();
    if (id.isEmpty || !assignableRoles.contains(role)) return false;
    final existing = _findUser(_lastConfirmedData, id);
    if (existing != null && existing.hasRole(role)) return false;
    return _runMutation(
      key: 'user:$id',
      failureMessage: 'เพิ่มบทบาทไม่สำเร็จ',
      action: () async {
        await _addSecondaryRole(uid: id, role: role);
        final canonical = await _loadCanonical();
        final updated = _findUser(canonical, id);
        if (updated == null ||
            !updated.hasRole(role) ||
            updated.allRoles.length < 2) {
          throw StateError('backend_secondary_role_not_confirmed');
        }
        return canonical;
      },
    );
  }

  Future<bool> setSuspended({required String uid, required bool suspended}) {
    final id = uid.trim();
    if (id.isEmpty) return Future<bool>.value(false);
    return _runMutation(
      key: 'user:$id',
      failureMessage: suspended
          ? 'ระงับสิทธิ์ผู้ใช้งานไม่สำเร็จ'
          : 'เปิดใช้งานผู้ใช้งานไม่สำเร็จ',
      action: () async {
        if (suspended) {
          await _suspendUser(id);
        } else {
          await _reactivateUser(id);
        }
        final canonical = await _loadCanonical();
        final updated = _findUser(canonical, id);
        final expected = suspended ? 'suspended' : 'active';
        if (updated == null || updated.status != expected) {
          throw StateError('backend_status_change_not_confirmed');
        }
        return canonical;
      },
    );
  }

  Future<bool> inviteStaff({
    required String email,
    required UserRole role,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!_isValidEmail(normalizedEmail) || !assignableRoles.contains(role)) {
      return false;
    }
    return _runMutation(
      key: 'invite',
      failureMessage: 'ส่งคำเชิญผู้ใช้งานไม่สำเร็จ',
      action: () async {
        final ticket = await _createInvitation(
          email: normalizedEmail,
          role: role,
        );
        final canonical = await _loadCanonical();
        if (!canonical.invitations.any(
          (invitation) =>
              invitation.email.toLowerCase() == normalizedEmail &&
              invitation.isPending &&
              invitation.role == role,
        )) {
          throw StateError('backend_invitation_not_confirmed');
        }
        _lastIssuedTicket = ticket;
        return canonical;
      },
    );
  }

  Future<bool> revokeInvitation(String invitationId) async {
    final id = invitationId.trim();
    if (id.isEmpty) return false;
    return _runMutation(
      key: 'invitation:$id',
      failureMessage: 'ยกเลิกคำเชิญไม่สำเร็จ',
      action: () async {
        await _revokeInvitation(id);
        final canonical = await _loadCanonical();
        if (canonical.invitations.any(
          (invitation) => invitation.id == id && invitation.isPending,
        )) {
          throw StateError('backend_revoke_not_confirmed');
        }
        return canonical;
      },
    );
  }

  void clearIssuedTicket() {
    if (_lastIssuedTicket == null) return;
    _lastIssuedTicket = null;
    if (!_disposed) notifyListeners();
  }

  static bool _isValidEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s.]+\.[^@\s]+$').hasMatch(email);

  UserModel? _findUser(SchoolAdminPermissionsSnapshot? snapshot, String uid) {
    if (snapshot == null) return null;
    for (final user in snapshot.users) {
      if (user.uid == uid) return user;
    }
    return null;
  }

  Future<bool> _runMutation({
    required String key,
    required String failureMessage,
    required Future<SchoolAdminPermissionsSnapshot> Function() action,
  }) async {
    if (_disposed || !_busyKeys.add(key)) return false;
    final previous = _lastConfirmedData;
    notifyListeners();
    try {
      final canonical = await action();
      if (_disposed) return false;
      _publishCanonical(canonical);
      return true;
    } catch (error, stackTrace) {
      _publish(
        SchoolAdminError(
          message: failureMessage,
          error: error,
          stackTrace: stackTrace,
          previousData: previous,
        ),
      );
      return false;
    } finally {
      _busyKeys.remove(key);
      if (!_disposed) notifyListeners();
    }
  }

  Future<SchoolAdminPermissionsSnapshot> _loadCanonical() async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _loadUsers(),
      _loadInvitations(),
      _loadLogs(),
    ]);
    return SchoolAdminPermissionsSnapshot(
      users: results[0] as List<UserModel>,
      invitations: results[1] as List<StaffInvitation>,
      logs: results[2] as List<SchoolAdminAuditLog>,
    );
  }

  void _publishCanonical(SchoolAdminPermissionsSnapshot snapshot) {
    if (_disposed) return;
    _lastConfirmedData = snapshot;
    _publish(
      snapshot.isEmpty
          ? const SchoolAdminEmpty<SchoolAdminPermissionsSnapshot>()
          : SchoolAdminData<SchoolAdminPermissionsSnapshot>(snapshot),
    );
  }

  void _publish(SchoolAdminAsyncState<SchoolAdminPermissionsSnapshot> next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
