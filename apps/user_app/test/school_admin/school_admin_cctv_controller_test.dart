import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/controllers/school_admin_async_state.dart';
import 'package:my_first_app/pages/school_admin/controllers/school_admin_cctv_controller.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  test('load exposes the canonical grants and eligible users', () async {
    final controller = SchoolAdminCctvController(
      loadGrants: () async => <CameraAccessGrantItem>[_grant()],
      loadUsers: () async => <UserModel>[_user()],
      grantAccess: _unusedGrant,
      revokeAccess: _unusedRevoke,
    );

    await controller.load();

    expect(controller.state, isA<SchoolAdminData<SchoolAdminCctvSnapshot>>());
    final data = controller.state as SchoolAdminData<SchoolAdminCctvSnapshot>;
    expect(data.value.grants.single.grantId, 'grant-1');
    expect(data.value.users.single.uid, 'user-1');
  });

  test('grant fails truthfully when the backend returns no grant id', () async {
    final controller = SchoolAdminCctvController(
      loadGrants: () async => const <CameraAccessGrantItem>[],
      loadUsers: () async => <UserModel>[_user()],
      grantAccess:
          ({
            required userId,
            cameraDeviceId,
            required reason,
            required validUntil,
          }) async => null,
      revokeAccess: _unusedRevoke,
    );

    await controller.load();
    final succeeded = await controller.grant(
      userId: 'user-1',
      reason: 'ตรวจสอบความปลอดภัย',
      validUntil: DateTime.utc(2030, 1, 8),
    );

    expect(succeeded, isFalse);
    expect(controller.state, isA<SchoolAdminError<SchoolAdminCctvSnapshot>>());
  });

  test(
    'grant succeeds only after refetch confirms the active grant id',
    () async {
      var backendGrants = <CameraAccessGrantItem>[];
      var loadCount = 0;
      final controller = SchoolAdminCctvController(
        loadGrants: () async {
          loadCount += 1;
          return List<CameraAccessGrantItem>.unmodifiable(backendGrants);
        },
        loadUsers: () async => <UserModel>[_user()],
        grantAccess:
            ({
              required userId,
              cameraDeviceId,
              required reason,
              required validUntil,
            }) async {
              backendGrants = <CameraAccessGrantItem>[_grant()];
              return 'grant-1';
            },
        revokeAccess: _unusedRevoke,
      );

      await controller.load();
      final succeeded = await controller.grant(
        userId: 'user-1',
        reason: 'ตรวจสอบความปลอดภัย',
        validUntil: DateTime.utc(2030, 1, 8),
      );

      expect(succeeded, isTrue);
      expect(loadCount, 2);
      final data = controller.state as SchoolAdminData<SchoolAdminCctvSnapshot>;
      expect(data.value.grants.single.isActive, isTrue);
    },
  );

  test('revoke fails truthfully when the backend returns false', () async {
    final controller = SchoolAdminCctvController(
      loadGrants: () async => <CameraAccessGrantItem>[_grant()],
      loadUsers: () async => <UserModel>[_user()],
      grantAccess: _unusedGrant,
      revokeAccess: (_) async => false,
    );

    await controller.load();
    final succeeded = await controller.revoke('grant-1');

    expect(succeeded, isFalse);
    expect(controller.state, isA<SchoolAdminError<SchoolAdminCctvSnapshot>>());
  });

  test('revoke succeeds only after refetch confirms inactive state', () async {
    var backendGrants = <CameraAccessGrantItem>[_grant()];
    final controller = SchoolAdminCctvController(
      loadGrants: () async =>
          List<CameraAccessGrantItem>.unmodifiable(backendGrants),
      loadUsers: () async => <UserModel>[_user()],
      grantAccess: _unusedGrant,
      revokeAccess: (grantId) async {
        backendGrants = <CameraAccessGrantItem>[_grant(isActive: false)];
        return true;
      },
    );

    await controller.load();
    final succeeded = await controller.revoke('grant-1');

    expect(succeeded, isTrue);
    final data = controller.state as SchoolAdminData<SchoolAdminCctvSnapshot>;
    expect(data.value.grants.single.isActive, isFalse);
  });
}

Future<String?> _unusedGrant({
  required String userId,
  String? cameraDeviceId,
  required String reason,
  required DateTime validUntil,
}) async => 'unused';

Future<bool> _unusedRevoke(String grantId) async => true;

UserModel _user() => const UserModel(
  uid: 'user-1',
  name: 'ครูทดสอบ',
  email: 'teacher@example.test',
  role: UserRole.teacher,
  schoolId: 'school-1',
);

CameraAccessGrantItem _grant({bool isActive = true}) => CameraAccessGrantItem(
  grantId: 'grant-1',
  cameraName: 'กล้องหน้าโรงเรียน',
  location: 'ประตูหน้า',
  building: 'อาคาร 1',
  room: '101',
  userId: 'user-1',
  userName: 'ครูทดสอบ',
  userEmail: 'teacher@example.test',
  userRole: 'teacher',
  reason: 'ตรวจสอบความปลอดภัย',
  validFrom: DateTime.utc(2030, 1, 1),
  validUntil: DateTime.utc(2030, 1, 8),
  grantedAt: DateTime.utc(2030, 1, 1),
  grantedByName: 'แอดมินทดสอบ',
  isActive: isActive,
);
