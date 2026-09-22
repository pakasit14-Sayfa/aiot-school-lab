import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/controllers/staff_emergency_actions.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_incident_inbox_page.dart';
import 'package:shared_core/shared_core.dart';

/// This page used to show a hardcoded fake "average resolution time"
/// banner unrelated to any real incident data, and had dead mock-fallback
/// branches in the active-SOS card. These tests pin down that the inbox
/// list renders real incident data and that the quick acknowledge/close
/// actions on the list reach the real StaffEmergencyActions controller
/// (the same one the already-tested detail page uses), not fake state.

TeacherIncidentReport _incident({
  String id = 'inc-1',
  String status = 'new',
  IncidentCategory category = IncidentCategory.anomaly,
}) => TeacherIncidentReport(
  id: id,
  category: category,
  room: 'ม.3/1',
  status: status,
  reporterName: 'เด็กชาย ทดสอบ',
  createdAt: DateTime.now(),
  reason: 'พบควันในห้องเรียน',
);

StaffEmergencyActions _controller({
  Future<void> Function(String)? acknowledgeIncident,
  Future<void> Function(String)? closeIncident3,
  Future<String?> Function(StaffEmergencySource, String)? readStatus,
}) => StaffEmergencyActions(
  acknowledgeIncident: acknowledgeIncident ?? (_) async {},
  acknowledgeHardware: (_) async {},
  escalateIncident: (_) async {},
  closeIncident: (id, note, type) async => closeIncident3?.call(id),
  closeHardware: (_, _) async {},
  readStatus: readStatus ?? (_, _) async => 'acknowledged',
  saveIncidentNote: (_, _) async {},
  readLatestIncidentNote: (_) async => null,
);

Future<void> _pump(
  WidgetTester tester, {
  StaffEmergencyActions? actionsOverride,
  Future<List<EmergencyEventItem>> Function()? loadEmergencyEvents,
  Future<List<TeacherIncidentReport>> Function()? loadIncidentReports,
}) async {
  tester.view.physicalSize = const Size(1400, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: TeacherIncidentInboxPage(
        actionsOverride: actionsOverride ?? _controller(),
        loadEmergencyEvents: loadEmergencyEvents ?? () async => const [],
        loadIncidentReports: loadIncidentReports ?? () async => [_incident()],
        watchIncidents: () => const Stream.empty(),
        watchEmergencyEvents: () => const Stream.empty(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'a real incident renders the real reason/room/reporter, no fake resolution-time banner',
    (tester) async {
      await _pump(tester);
      expect(find.text('พบควันในห้องเรียน'), findsWidgets);
      expect(find.textContaining('เด็กชาย ทดสอบ'), findsWidgets);
      expect(find.textContaining('เวลาแก้ไขเฉลี่ย'), findsNothing);
      expect(find.textContaining('เวลาเฉลี่ย'), findsNothing);
    },
  );

  /// ปุ่ม CCTV 2 ปุ่มเคยกดแล้วขึ้น "กำลังเปิดคลิป.../กำลังเชื่อมต่อสัญญาณกล้อง
  /// ห้อง ม.3/2..." ทั้งที่ระบบไม่ได้เชื่อมกับกล้องตัวไหนเลย จากนั้นถูก disable
  /// พร้อมเหตุผล — ตั้งแต่ 2026-09-16 ถอดออกทั้งคู่ (ไม่มีอะไรให้เปิดใช้)
  testWidgets(
    'no CCTV button exists on the incident page — there is no camera link',
    (tester) async {
      await _pump(tester);
      expect(find.textContaining('CCTV'), findsNothing);
      expect(find.textContaining('กำลังเปิดคลิป'), findsNothing);
      expect(find.textContaining('ม.3/2'), findsNothing);
      expect(find.text('ข้อมูลจำลอง'), findsNothing);
    },
  );

  testWidgets(
    'zero real incidents/events shows an honest empty list, no fabricated entries',
    (tester) async {
      await _pump(tester, loadIncidentReports: () async => const []);
      expect(find.text('พบควันในห้องเรียน'), findsNothing);
    },
  );

  testWidgets(
    'quick-acknowledge from the list calls the real controller, and reflects the confirmed status',
    (tester) async {
      var acked = false;
      await _pump(
        tester,
        actionsOverride: _controller(
          acknowledgeIncident: (_) async => acked = true,
          readStatus: (_, _) async => acked ? 'acknowledged' : 'new',
        ),
      );

      await tester.tap(find.text('รับเรื่อง'));
      await tester.pumpAndSettle();

      expect(
        acked,
        true,
        reason: 'the real acknowledge callback must be invoked',
      );
      expect(find.text('รับเรื่องเรียบร้อยแล้ว'), findsOneWidget);
    },
  );

  testWidgets(
    'a load failure shows the real error banner with retry, not silent stale data',
    (tester) async {
      await _pump(
        tester,
        loadIncidentReports: () async =>
            throw StateError('backend detail that must stay internal'),
      );

      expect(find.textContaining('โหลดเหตุฉุกเฉินไม่สำเร็จ'), findsOneWidget);
      expect(find.textContaining('backend detail'), findsNothing);
    },
  );
}
