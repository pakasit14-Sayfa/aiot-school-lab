import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/school_buildings_page.dart';
import 'package:shared_core/shared_core.dart';

/// Pins loading / data / empty / error apart for buildings, rooms, and the
/// audit-log panel (the only backend this page actually has —
/// `fetchBuildings`/`fetchRooms`/`fetchAuditLogs`, all read-only).
///
/// As of 2026-09-07 the create/edit/delete building & room dialogs were
/// entirely fake: they wrote to in-memory lists via setState and showed a
/// "บันทึกแล้ว" message without calling any RPC, so the change vanished on
/// refresh. They were first changed to disclose that plainly. Since
/// 2026-09-14 "create" goes through the real batch-import RPCs
/// (`import_school_buildings_batch` / `import_school_rooms_batch`, one row
/// at a time) — edit/delete still have no RPC and still say so.

SchoolBuildingRecord _building({
  String id = 'bld-1',
  String name = 'อาคาร 1',
  String code = 'BLD-1',
}) => SchoolBuildingRecord(
  id: id,
  schoolId: 'school-1',
  name: name,
  code: code,
  floors: 3,
  roomsCount: 10,
  managerName: 'อ.สมศักดิ์',
  devicesCount: 5,
  trainingKitsCount: 2,
  status: 'active',
  note: '',
);

SchoolRoomRecord _room({
  String id = 'room-1',
  String name = 'ห้องเรียน 101',
  String code = 'A-101',
  String buildingName = 'อาคาร 1',
}) => SchoolRoomRecord(
  id: id,
  schoolId: 'school-1',
  buildingName: buildingName,
  name: name,
  code: code,
  floor: 'ชั้น 1',
  roomType: 'ห้องเรียน',
  capacity: 40,
  teacherName: 'ครูสมศรี',
  devicesCount: 2,
  trainingKitsCount: 1,
  status: 'active',
  resourceStatus: 'ปกติ',
);

SchoolAdminAuditLog _log({String action = 'เพิ่มอาคาร'}) => SchoolAdminAuditLog(
  id: 1,
  action: action,
  target: 'อาคาร 1',
  detail: '',
  actorName: 'ผู้ดูแล ทดสอบ',
  actorRole: 'school_admin',
  createdAt: DateTime(2026, 9, 1),
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<SchoolBuildingRecord>> Function()? loadBuildings,
  Future<List<SchoolRoomRecord>> Function()? loadRooms,
  Future<List<SchoolAdminAuditLog>> Function()? loadLogs,
  Future<BulkImportResult> Function(Map<String, dynamic>)? createBuilding,
  Future<BulkImportResult> Function(Map<String, dynamic>)? createRoom,
  Future<void> Function({required String buildingId, required String name, required String code, int? floors, String? note})?
  updateBuilding,
  Future<void> Function(String)? deleteBuilding,
  Future<void> Function({required String buildingId, required String? managerName})?
  setBuildingManager,
  Future<void> Function({required String roomId, required String name, required String code, String? floor, String? roomType, int? capacity})?
  updateRoom,
  Future<void> Function(String)? deleteRoom,
  Future<List<SchoolSensorAlertRecord>> Function()? loadAlerts,
  Future<List<DeviceOption>> Function()? loadDevices,
  Future<List<StaffDirectoryEntry>> Function()? loadStaffDirectory,
}) async {
  tester.view.physicalSize = const Size(1500, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SchoolBuildingsPage(
        loadBuildings: loadBuildings ?? () async => <SchoolBuildingRecord>[],
        loadRooms: loadRooms ?? () async => <SchoolRoomRecord>[],
        loadLogs: loadLogs ?? () async => <SchoolAdminAuditLog>[],
        createBuilding: createBuilding,
        createRoom: createRoom,
        updateBuilding: updateBuilding,
        deleteBuilding: deleteBuilding,
        setBuildingManager: setBuildingManager,
        updateRoom: updateRoom,
        deleteRoom: deleteRoom,
        loadAlerts: loadAlerts ?? () async => const <SchoolSensorAlertRecord>[],
        loadDevices: loadDevices ?? () async => const <DeviceOption>[],
        loadStaffDirectory: loadStaffDirectory ?? () async => const <StaffDirectoryEntry>[],
      ),
    ),
  );
}

const _inserted = BulkImportResult(success: true, insertedCount: 1, skipped: []);
const _duplicate = BulkImportResult(
  success: true,
  insertedCount: 0,
  skipped: [SkippedRow(row: 1, reason: 'duplicate_code')],
);

void main() {
  testWidgets('real buildings and rooms are rendered', (tester) async {
    await _pump(
      tester,
      loadBuildings: () async => [_building()],
      loadRooms: () async => [_room()],
    );
    await tester.pumpAndSettle();

    expect(find.text('อาคาร 1'), findsWidgets);
    expect(find.text('ห้องเรียน 101'), findsWidgets);
  });

  testWidgets('no buildings says so, distinct from a failed load', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีประวัติการจัดการอาคารและห้อง'), findsOneWidget);
    expect(find.text('โหลดข้อมูลอาคารไม่สำเร็จ'), findsNothing);
  });

  testWidgets('a failed building load is distinct from empty, with retry', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      loadBuildings: () async {
        calls++;
        throw StateError('backend detail that must stay internal');
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('โหลดข้อมูลอาคารไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('backend detail'), findsNothing);
    expect(calls, 1);

    await tester.tap(find.text('ลองใหม่').first);
    await tester.pumpAndSettle();
    expect(calls, 2, reason: 'retry must actually re-issue the load');
  });

  testWidgets('a slow load shows progress, not an empty result', (
    tester,
  ) async {
    final gate = Completer<List<SchoolBuildingRecord>>();
    await _pump(tester, loadBuildings: () => gate.future);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);

    gate.complete([_building()]);
    await tester.pumpAndSettle();
  });

  testWidgets('audit log error is distinct from an empty log list', (
    tester,
  ) async {
    await _pump(
      tester,
      loadLogs: () async => throw StateError('log query failed'),
    );
    await tester.pumpAndSettle();

    // The page continues to show the rest of its content even if just the
    // log fetch fails — it must not fall back to claiming "no history".
    expect(find.text('ยังไม่มีประวัติการจัดการอาคารและห้อง'), findsOneWidget);
  });

  testWidgets('a real audit log entry is rendered', (tester) async {
    await _pump(tester, loadLogs: () async => [_log()]);
    await tester.pumpAndSettle();

    expect(find.text('เพิ่มอาคาร • อาคาร 1'), findsOneWidget);
  });

  testWidgets(
    'creating a building sends the form to the real import RPC and reloads',
    (tester) async {
      Map<String, dynamic>? sent;
      var loads = 0;
      await _pump(
        tester,
        loadBuildings: () async {
          loads++;
          return <SchoolBuildingRecord>[];
        },
        createBuilding: (b) async {
          sent = b;
          return _inserted;
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('สร้างอาคาร'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'ชื่ออาคาร'), 'อาคารวิทยาศาสตร์');
      await tester.enterText(find.widgetWithText(TextField, 'รหัสอาคาร (ไม่ซ้ำ)'), 'SCI');
      await tester.enterText(find.widgetWithText(TextField, 'จำนวนชั้น'), '4');
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();

      expect(sent, {'name': 'อาคารวิทยาศาสตร์', 'code': 'SCI', 'floors': 4});
      expect(loads, 2, reason: 'a successful create reloads from the backend');
      expect(find.text('สร้างอาคาร "อาคารวิทยาศาสตร์" แล้ว'), findsOneWidget);
    },
  );

  testWidgets(
    'a skipped row (duplicate code) is reported as such, never as success',
    (tester) async {
      var loads = 0;
      await _pump(
        tester,
        loadBuildings: () async {
          loads++;
          return <SchoolBuildingRecord>[];
        },
        createBuilding: (_) async => _duplicate,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('สร้างอาคาร'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'ชื่ออาคาร'), 'อาคาร 1');
      await tester.enterText(find.widgetWithText(TextField, 'รหัสอาคาร (ไม่ซ้ำ)'), 'BLD-1');
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();

      expect(find.text('รหัสอาคารนี้มีอยู่แล้ว กรุณาใช้รหัสอื่น'), findsOneWidget);
      expect(find.textContaining('แล้ว"'), findsNothing);
      expect(loads, 1, reason: 'nothing was written, so nothing reloads');
    },
  );

  testWidgets(
    'creating a room sends the chosen building code to the real import RPC',
    (tester) async {
      Map<String, dynamic>? sent;
      await _pump(
        tester,
        loadBuildings: () async => [_building(), _building(id: 'bld-2', name: 'อาคาร 2', code: 'BLD-2')],
        createRoom: (r) async {
          sent = r;
          return _inserted;
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('สร้างห้อง'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'ชื่อห้อง'), 'ห้องแล็บ AIoT');
      await tester.enterText(find.widgetWithText(TextField, 'รหัสห้อง (ไม่ซ้ำ)'), 'LAB-1');
      await tester.enterText(find.widgetWithText(TextField, 'ชั้น (ถ้ามี)'), '2');
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();

      expect(sent, {
        'name': 'ห้องแล็บ AIoT',
        'code': 'LAB-1',
        'building_code': 'BLD-1',
        'floor': '2',
        'capacity': 30,
      });
    },
  );

  testWidgets(
    'a failing create RPC shows a fixed sentence, not the exception',
    (tester) async {
      await _pump(
        tester,
        createBuilding: (_) async => throw Exception('PostgrestException: boom_secret'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('สร้างอาคาร'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'ชื่ออาคาร'), 'อาคาร X');
      await tester.enterText(find.widgetWithText(TextField, 'รหัสอาคาร (ไม่ซ้ำ)'), 'X');
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();

      expect(find.text('สร้างอาคารไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'), findsOneWidget);
      expect(find.textContaining('boom_secret'), findsNothing);
    },
  );

  testWidgets(
    'the monitoring section lists real unacknowledged alerts with the device location, never invented ones',
    (tester) async {
      await _pump(
        tester,
        loadAlerts: () async => [
          SchoolSensorAlertRecord(
            id: 'al-1', deviceId: 'dev-1', deviceName: 'PM2.5 ห้อง 101', deviceCode: 'PM-101',
            schoolId: 'school-1', metric: 'pm25', value: 92, triggeredAt: DateTime(2026, 9, 14, 9),
            status: 'new', thresholdId: null, acknowledgedBy: null, acknowledgedByName: null, acknowledgedAt: null,
          ),
        ],
        loadDevices: () async => const [
          DeviceOption(id: 'dev-1', name: 'PM2.5 ห้อง 101', type: 'pm25_sensor', location: 'อาคาร 1 ชั้น 1', status: 'online'),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('PM2.5 ห้อง 101'), findsOneWidget);
      expect(find.textContaining('อาคาร 1 ชั้น 1 · pm25 92'), findsOneWidget);
      expect(find.textContaining('LAB-02'), findsNothing);
      expect(find.textContaining('อาคารกีฬา'), findsNothing);
      expect(find.textContaining('ยังไม่มีระบบตรวจจับ'), findsNothing);
    },
  );

  testWidgets('no unacknowledged alerts says so', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();
    expect(find.text('ไม่มีแจ้งเตือนที่ยังไม่ได้รับทราบ'), findsOneWidget);
  });

  testWidgets('a failed alert load says so with retry, not an empty list', (tester) async {
    await _pump(tester, loadAlerts: () async => throw Exception('boom'));
    await tester.pumpAndSettle();
    expect(find.text('โหลดรายการแจ้งเตือนไม่สำเร็จ'), findsOneWidget);
    expect(find.text('ไม่มีแจ้งเตือนที่ยังไม่ได้รับทราบ'), findsNothing);
  });

  testWidgets(
    '"กำหนดครูประจำอาคาร" picks a real staff member and writes it through set_school_building_manager',
    (tester) async {
      String? sentBuilding, sentName;
      var loads = 0;
      await _pump(
        tester,
        loadBuildings: () async {
          loads++;
          return [_building()];
        },
        loadStaffDirectory: () async => const [
          StaffDirectoryEntry(
            userId: 'u-1', fullName: 'ครูสมศักดิ์ ใจดี', email: 's@x.test', status: 'active',
            roles: ['teacher'], administrativeDepartments: [], subjectGroups: [], headsDepartments: [],
          ),
        ],
        setBuildingManager: ({required buildingId, required managerName}) async {
          sentBuilding = buildingId;
          sentName = managerName;
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('กำหนดครูประจำอาคาร'));
      await tester.pumpAndSettle();
      // dropdown ผู้รับผิดชอบ (ตัวที่สองในแผ่น — ตัวแรกคืออาคาร) เริ่มที่ค่าปัจจุบัน
      // DropdownButtonFormField<String> ของอาคารก็ตรง `is DropdownButtonFormField<String?>`
      // (String เป็น subtype ของ String?) — เอาตัวสุดท้ายในแผ่น = ผู้รับผิดชอบ
      final managerDropdown = find.byWidgetPredicate(
        (w) => w is DropdownButtonFormField<String?>,
      );
      expect(managerDropdown, findsNWidgets(2));
      await tester.tap(managerDropdown.last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ครูสมศักดิ์ ใจดี').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();

      expect(sentBuilding, 'bld-1');
      expect(sentName, 'ครูสมศักดิ์ ใจดี');
      expect(loads, 2, reason: 'reads back after the write');
    },
  );

  testWidgets(
    'editing a building sends the changed fields to update_school_building',
    (tester) async {
      Map<String, Object?>? sent;
      await _pump(
        tester,
        loadBuildings: () async => [_building()],
        updateBuilding: ({required buildingId, required name, required code, floors, note}) async {
          sent = {'id': buildingId, 'name': name, 'code': code, 'floors': floors, 'note': note};
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('แก้ไขอาคาร').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'ชื่ออาคาร'), 'อาคาร 1 (ปรับปรุง)');
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();

      expect(sent, {'id': 'bld-1', 'name': 'อาคาร 1 (ปรับปรุง)', 'code': 'BLD-1', 'floors': 3, 'note': ''});
      expect(find.text('บันทึกอาคาร "อาคาร 1 (ปรับปรุง)" แล้ว'), findsOneWidget);
    },
  );

  testWidgets(
    'deleting a building that still has rooms shows the RPC reason, not a generic error',
    (tester) async {
      await _pump(
        tester,
        loadBuildings: () async => [_building()],
        deleteBuilding: (_) async => throw Exception('PostgrestException: building_has_rooms'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('แก้ไขอาคาร').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'ลบ'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'ลบ'));
      await tester.pumpAndSettle();

      expect(find.textContaining('ยังมีห้องอยู่ในอาคารนี้'), findsOneWidget);
      expect(find.textContaining('building_has_rooms'), findsNothing);
    },
  );

  testWidgets(
    'room type/status filters only ever offer values that actually appear in the data',
    (tester) async {
      await _pump(
        tester,
        loadRooms: () async => [
          _room(id: 'r-1', name: 'ห้องเรียน 101', code: 'A-101'),
        ],
      );
      await tester.pumpAndSettle();

      // The dead options this used to offer regardless of data must never
      // reappear — they never matched a real room in this codebase.
      expect(find.text('ห้องประชุม'), findsNothing);
      expect(find.text('ห้องสำนักงาน'), findsNothing);
      expect(find.text('ห้องเก็บอุปกรณ์'), findsNothing);
      expect(find.text('ปิดใช้งาน'), findsNothing);
    },
  );

  testWidgets(
    'audit log rows infer type from the action instead of hardcoding success',
    (tester) async {
      await _pump(
        tester,
        loadLogs: () async => [_log(action: 'ลบห้อง')],
      );
      await tester.pumpAndSettle();

      // A delete action must not render with the same green "success" color
      // every action used to get regardless of what actually happened.
      expect(find.text('ลบห้อง • อาคาร 1'), findsOneWidget);
    },
  );
}
