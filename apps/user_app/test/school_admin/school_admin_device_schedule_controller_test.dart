import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/controllers/school_admin_async_state.dart';
import 'package:my_first_app/pages/school_admin/controllers/school_admin_device_schedule_controller.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  test('load exposes canonical schedules and devices', () async {
    final controller = _controller(
      loadSchedules: () async => <DeviceSchedule>[_schedule()],
    );

    await controller.load();

    expect(
      controller.state,
      isA<SchoolAdminData<SchoolAdminDeviceScheduleSnapshot>>(),
    );
    final data =
        controller.state as SchoolAdminData<SchoolAdminDeviceScheduleSnapshot>;
    expect(data.value.schedules.single.id, 'schedule-1');
    expect(data.value.devices.single.id, 'device-1');
  });

  test('load exposes a visible error state', () async {
    final controller = _controller(
      loadSchedules: () async => throw StateError('offline'),
    );

    await controller.load();

    expect(
      controller.state,
      isA<SchoolAdminError<SchoolAdminDeviceScheduleSnapshot>>(),
    );
    final error =
        controller.state as SchoolAdminError<SchoolAdminDeviceScheduleSnapshot>;
    expect(error.message, 'โหลดข้อมูลตารางเวลาอุปกรณ์ไม่สำเร็จ');
  });

  test('create fails truthfully when backend returns a null-like id', () async {
    final controller = _controller(
      loadSchedules: () async => const <DeviceSchedule>[],
      createSchedule:
          ({
            required deviceId,
            required label,
            required command,
            required daysOfWeek,
            required timeOfDay,
          }) async => 'null',
    );
    await controller.load();

    final succeeded = await controller.create(
      deviceId: 'device-1',
      label: 'เปิดก่อนเข้าเรียน',
      command: const <String, dynamic>{'action': 'on'},
      daysOfWeek: const <int>[1, 2, 3, 4, 5],
      timeOfDay: '08:00',
    );

    expect(succeeded, isFalse);
    expect(
      controller.state,
      isA<SchoolAdminError<SchoolAdminDeviceScheduleSnapshot>>(),
    );
  });

  test('create succeeds only after refetch confirms the returned id', () async {
    var backendSchedules = <DeviceSchedule>[];
    var loadCount = 0;
    final controller = _controller(
      loadSchedules: () async {
        loadCount += 1;
        return List<DeviceSchedule>.unmodifiable(backendSchedules);
      },
      createSchedule:
          ({
            required deviceId,
            required label,
            required command,
            required daysOfWeek,
            required timeOfDay,
          }) async {
            backendSchedules = <DeviceSchedule>[_schedule()];
            return 'schedule-1';
          },
    );
    await controller.load();

    final succeeded = await controller.create(
      deviceId: 'device-1',
      label: 'เปิดก่อนเข้าเรียน',
      command: const <String, dynamic>{'action': 'on'},
      daysOfWeek: const <int>[1, 2, 3, 4, 5],
      timeOfDay: '08:00',
    );

    expect(succeeded, isTrue);
    expect(loadCount, 2);
    final data =
        controller.state as SchoolAdminData<SchoolAdminDeviceScheduleSnapshot>;
    expect(data.value.schedules.single.id, 'schedule-1');
  });

  test('toggle succeeds only after refetch confirms enabled state', () async {
    var backendSchedules = <DeviceSchedule>[_schedule(enabled: true)];
    final controller = _controller(
      loadSchedules: () async =>
          List<DeviceSchedule>.unmodifiable(backendSchedules),
      toggleSchedule: ({required scheduleId, required enabled}) async {
        backendSchedules = <DeviceSchedule>[_schedule(enabled: enabled)];
      },
    );
    await controller.load();

    final succeeded = await controller.toggle('schedule-1', false);

    expect(succeeded, isTrue);
    final data =
        controller.state as SchoolAdminData<SchoolAdminDeviceScheduleSnapshot>;
    expect(data.value.schedules.single.enabled, isFalse);
  });

  test('toggle fails truthfully when refetch still has old state', () async {
    final controller = _controller(
      loadSchedules: () async => <DeviceSchedule>[_schedule(enabled: true)],
    );
    await controller.load();

    final succeeded = await controller.toggle('schedule-1', false);

    expect(succeeded, isFalse);
    expect(
      controller.state,
      isA<SchoolAdminError<SchoolAdminDeviceScheduleSnapshot>>(),
    );
  });

  test('delete succeeds only after refetch confirms absence', () async {
    var backendSchedules = <DeviceSchedule>[_schedule()];
    final controller = _controller(
      loadSchedules: () async =>
          List<DeviceSchedule>.unmodifiable(backendSchedules),
      deleteSchedule: ({required scheduleId}) async {
        backendSchedules = <DeviceSchedule>[];
      },
    );
    await controller.load();

    final succeeded = await controller.delete('schedule-1');

    expect(succeeded, isTrue);
    final data =
        controller.state as SchoolAdminData<SchoolAdminDeviceScheduleSnapshot>;
    expect(data.value.schedules, isEmpty);
  });

  test(
    'delete fails truthfully when refetch still finds the schedule',
    () async {
      final controller = _controller(
        loadSchedules: () async => <DeviceSchedule>[_schedule()],
      );
      await controller.load();

      final succeeded = await controller.delete('schedule-1');

      expect(succeeded, isFalse);
      expect(
        controller.state,
        isA<SchoolAdminError<SchoolAdminDeviceScheduleSnapshot>>(),
      );
    },
  );
}

SchoolAdminDeviceScheduleController _controller({
  required Future<List<DeviceSchedule>> Function() loadSchedules,
  SchoolAdminDeviceScheduleCreateSchedule createSchedule = _unusedCreate,
  SchoolAdminDeviceScheduleToggleSchedule toggleSchedule = _unusedToggle,
  SchoolAdminDeviceScheduleDeleteSchedule deleteSchedule = _unusedDelete,
}) => SchoolAdminDeviceScheduleController(
  loadSchedules: loadSchedules,
  loadDevices: () async => <DeviceOption>[_device()],
  createSchedule: createSchedule,
  toggleSchedule: toggleSchedule,
  deleteSchedule: deleteSchedule,
);

Future<String> _unusedCreate({
  required String deviceId,
  required String label,
  required Map<String, dynamic> command,
  required List<int> daysOfWeek,
  required String timeOfDay,
}) async => 'unused';
Future<void> _unusedToggle({
  required String scheduleId,
  required bool enabled,
}) async {}
Future<void> _unusedDelete({required String scheduleId}) async {}

DeviceSchedule _schedule({bool enabled = true}) => DeviceSchedule(
  id: 'schedule-1',
  deviceId: 'device-1',
  deviceName: 'เครื่องปรับอากาศ',
  deviceLocation: 'ห้อง 101',
  schoolId: 'school-1',
  label: 'เปิดก่อนเข้าเรียน',
  command: const <String, dynamic>{'action': 'on'},
  daysOfWeek: const <int>[1, 2, 3, 4, 5],
  timeOfDay: '08:00:00',
  enabled: enabled,
  createdBy: 'admin-1',
  createdAt: DateTime.utc(2030, 1, 1),
);

DeviceOption _device() => const DeviceOption(
  id: 'device-1',
  name: 'เครื่องปรับอากาศ',
  type: 'air_conditioner',
  location: 'ห้อง 101',
  status: 'online',
);
