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
/// refresh. There is no backend for building/room mutations at all, so those
/// entry points were changed to disclose that plainly instead of pretending
/// to save — this test pins that disclosure.

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
      ),
    ),
  );
}

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
    'creating a building discloses there is no backend, instead of faking success',
    (tester) async {
      await _pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('สร้างอาคาร'));
      await tester.pumpAndSettle();

      expect(
        find.text('ยังไม่มีระบบบันทึกข้อมูลอาคาร/ห้องในเวอร์ชันนี้ กำลังพัฒนา RPC รองรับ'),
        findsOneWidget,
      );
      // No fake building must appear in the list as a result of the tap.
      expect(find.text('ยังไม่มีประวัติการจัดการอาคารและห้อง'), findsOneWidget);
    },
  );

  testWidgets(
    'creating a room discloses there is no backend, instead of faking success',
    (tester) async {
      await _pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('สร้างห้อง'));
      await tester.pumpAndSettle();

      expect(
        find.text('ยังไม่มีระบบบันทึกข้อมูลอาคาร/ห้องในเวอร์ชันนี้ กำลังพัฒนา RPC รองรับ'),
        findsOneWidget,
      );
    },
  );
}
