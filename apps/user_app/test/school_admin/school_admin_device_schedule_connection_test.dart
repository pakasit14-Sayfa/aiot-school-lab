import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/controllers/school_admin_device_schedule_controller.dart';
import 'package:my_first_app/pages/school_admin/school_admin_device_schedule_page.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  testWidgets(
    'empty schedule backend renders the required honest empty label',
    (tester) async {
      final controller = _controller(
        loadSchedules: () async => const <DeviceSchedule>[],
      );
      addTearDown(controller.dispose);

      await _pumpPage(tester, controller);

      expect(find.text('ยังไม่มีข้อมูล'), findsOneWidget);
    },
  );

  testWidgets('schedule load failure is visible and retryable', (tester) async {
    final controller = _controller(
      loadSchedules: () async => throw StateError('offline'),
    );
    addTearDown(controller.dispose);

    await _pumpPage(tester, controller);

    expect(find.text('โหลดข้อมูลตารางเวลาอุปกรณ์ไม่สำเร็จ'), findsOneWidget);
    expect(find.text('ลองใหม่'), findsOneWidget);
    expect(find.text('ยังไม่มีข้อมูล'), findsNothing);
  });

  testWidgets('retry reloads the backend and clears the load error', (
    tester,
  ) async {
    var attempts = 0;
    final controller = _controller(
      loadSchedules: () async {
        attempts += 1;
        if (attempts == 1) throw StateError('offline');
        return const <DeviceSchedule>[];
      },
    );
    addTearDown(controller.dispose);

    await _pumpPage(tester, controller);
    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('โหลดข้อมูลตารางเวลาอุปกรณ์ไม่สำเร็จ'), findsNothing);
    expect(find.text('ยังไม่มีข้อมูล'), findsOneWidget);
  });

  testWidgets('create failure never shows a success message', (tester) async {
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
    addTearDown(controller.dispose);

    await _pumpPage(tester, controller);
    await tester.tap(find.text('เพิ่มเวลาอัตโนมัติ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'เปิดก่อนเข้าเรียน');
    await tester.tap(find.text('บันทึกตารางเวลา'));
    await tester.pumpAndSettle();

    expect(find.text('บันทึกตารางเวลาอุปกรณ์ไม่สำเร็จ'), findsWidgets);
    expect(find.text('บันทึกการตั้งเวลาอัตโนมัติสำเร็จ'), findsNothing);
  });

  testWidgets('create success is shown only after canonical refetch', (
    tester,
  ) async {
    var backendSchedules = <DeviceSchedule>[];
    final controller = _controller(
      loadSchedules: () async =>
          List<DeviceSchedule>.unmodifiable(backendSchedules),
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
    addTearDown(controller.dispose);

    await _pumpPage(tester, controller);
    await tester.tap(find.text('เพิ่มเวลาอัตโนมัติ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'เปิดก่อนเข้าเรียน');
    await tester.tap(find.text('บันทึกตารางเวลา'));
    await tester.pumpAndSettle();

    expect(find.text('บันทึกการตั้งเวลาอัตโนมัติสำเร็จ'), findsOneWidget);
    expect(find.text('เพิ่มตารางเวลาอัตโนมัติ'), findsNothing);
    expect(find.text('เปิดก่อนเข้าเรียน'), findsOneWidget);
  });

  testWidgets('toggle failure keeps canonical state and shows no success', (
    tester,
  ) async {
    final controller = _controller(
      loadSchedules: () async => <DeviceSchedule>[_schedule()],
    );
    addTearDown(controller.dispose);

    await _pumpPage(tester, controller);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('เปลี่ยนสถานะตารางเวลาอุปกรณ์ไม่สำเร็จ'), findsWidgets);
    expect(find.text('ปิดใช้งานตารางเวลาแล้ว'), findsNothing);
  });

  testWidgets('delete failure keeps the dialog open and shows no success', (
    tester,
  ) async {
    final controller = _controller(
      loadSchedules: () async => <DeviceSchedule>[_schedule()],
    );
    addTearDown(controller.dispose);

    await _pumpPage(tester, controller);
    await tester.tap(find.byTooltip('ลบตารางเวลา'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบตาราง'));
    await tester.pumpAndSettle();

    expect(find.text('ลบตารางเวลาอุปกรณ์ไม่สำเร็จ'), findsWidgets);
    expect(find.text('ลบตารางเวลาเรียบร้อยแล้ว'), findsNothing);
    expect(find.text('ยืนยันลบตารางเวลา'), findsOneWidget);
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  SchoolAdminDeviceScheduleController controller,
) async {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(home: SchoolAdminDeviceSchedulePage(controller: controller)),
  );
  await tester.pumpAndSettle();
}

SchoolAdminDeviceScheduleController _controller({
  required SchoolAdminDeviceScheduleLoadSchedulesLoader loadSchedules,
  SchoolAdminDeviceScheduleCreateSchedule createSchedule = _unusedCreate,
  SchoolAdminDeviceScheduleDeleteSchedule deleteSchedule = _unusedDelete,
}) => SchoolAdminDeviceScheduleController(
  loadSchedules: loadSchedules,
  loadDevices: () async => <DeviceOption>[_device()],
  createSchedule: createSchedule,
  toggleSchedule: ({required scheduleId, required enabled}) async {},
  deleteSchedule: deleteSchedule,
);

Future<String> _unusedCreate({
  required String deviceId,
  required String label,
  required Map<String, dynamic> command,
  required List<int> daysOfWeek,
  required String timeOfDay,
}) async => 'unused';
Future<void> _unusedDelete({required String scheduleId}) async {}

DeviceSchedule _schedule() => DeviceSchedule(
  id: 'schedule-1',
  deviceId: 'device-1',
  deviceName: 'เครื่องปรับอากาศ',
  deviceLocation: 'ห้อง 101',
  schoolId: 'school-1',
  label: 'เปิดก่อนเข้าเรียน',
  command: const <String, dynamic>{'action': 'on'},
  daysOfWeek: const <int>[1, 2, 3, 4, 5],
  timeOfDay: '08:00:00',
  enabled: true,
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
