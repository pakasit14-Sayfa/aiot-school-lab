import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_assignment_editor_page.dart';
import 'package:shared_core/shared_core.dart';

/// PBL-4: link_assignment_sensor_dataset + AssignmentService.linkSensorDataset
/// were real but had zero callers — the UI was intentionally stripped from
/// this editor on 2026-09-16 because the redesigned student assignment page
/// didn't render assignment_sensor_datasets, so a link made here would have
/// been invisible to students. PBL-6 (2026-09-18) changed that: the student
/// side now renders pinned sensor datasets. This test locks in the
/// reinstated teacher-side binding UI, including that only devices whose
/// metrics fit the DB's `metric_type` enum are offered — a device type like
/// `water_meter` (water_flow_lmin/water_volume_l/water_m3) has no metric in
/// that enum at all and must never appear as a pickable option.
void main() {
  const course = CourseSummary(
    id: 'course-a',
    subjectName: 'วิทยาศาสตร์',
    gradeLevel: 'ม.1',
    room: '101',
    status: 'active',
    termId: 'term-1',
  );

  const assignment = AssignmentSummary(
    id: 'asg-1',
    type: 'homework',
    title: 'ใบงานเซนเซอร์',
    dueAt: null,
    status: 'published',
  );

  const airQualityDevice = DeviceOption(
    id: 'dev-air',
    name: 'เซนเซอร์คุณภาพอากาศ',
    type: 'air_quality_sensor',
    location: 'ห้อง 101',
    status: 'online',
  );
  const waterDevice = DeviceOption(
    id: 'dev-water',
    name: 'มิเตอร์น้ำ',
    type: 'water_meter',
    location: 'สนาม',
    status: 'online',
  );
  const relayDevice = DeviceOption(
    id: 'dev-relay',
    name: 'รีเลย์ไฟ',
    type: 'relay',
    location: null,
    status: 'online',
  );

  const detailNoDatasets = AssignmentDetail(
    id: 'asg-1',
    courseId: 'course-a',
    type: 'homework',
    title: 'ใบงานเซนเซอร์',
    instructions: null,
    dueAt: null,
    status: 'published',
    sensorDatasets: [],
  );

  Future<void> pumpEditor(
    WidgetTester tester, {
    required Future<List<DeviceOption>> Function() listDevices,
    required Future<void> Function({
      required String assignmentId,
      required String deviceId,
      required String metric,
      DateTime? timeStart,
      DateTime? timeEnd,
      String? label,
    })
    linkSensorDataset,
    required Future<AssignmentDetail> Function(String) loadAssignmentDetail,
  }) async {
    tester.view.physicalSize = const Size(1400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherAssignmentEditorPage(
          loadCourses: () async => const [course],
          loadAssignmentsForCourse: (_) async => const [assignment],
          loadCourseStudents: (_) async => [
            CourseStudent(
              studentId: 's1',
              firstName: 'สมชาย',
              lastName: 'ใจดี',
              email: 'a@test',
              enrolledAt: DateTime(2026, 1, 1),
            ),
          ],
          loadSubmissions: (_) async => <SubmissionRoster>[],
          listMyRubrics: () async => const [],
          listDevices: listDevices,
          linkSensorDataset: linkSensorDataset,
          loadAssignmentDetail: loadAssignmentDetail,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // เปิดฟอร์มแก้ไขใบงานที่มีอยู่แล้ว (assignment != null คือเงื่อนไขเดียว
    // ที่ทำให้ปุ่ม "ผูกข้อมูล" โผล่ — ใบงานใหม่ยังไม่มี id จริงให้ผูก)
    await tester.tap(find.text('แก้ไข'));
    await tester.pumpAndSettle();
  }

  testWidgets('ปุ่มผูกข้อมูลโหลดเฉพาะอุปกรณ์เซนเซอร์ที่ metric อยู่ใน metric_type จริง', (
    tester,
  ) async {
    await pumpEditor(
      tester,
      listDevices: () async => const [airQualityDevice, waterDevice, relayDevice],
      linkSensorDataset:
          ({
            required assignmentId,
            required deviceId,
            required metric,
            timeStart,
            timeEnd,
            label,
          }) async {},
      loadAssignmentDetail: (_) async => detailNoDatasets,
    );

    expect(find.text('ยังไม่มีชุดข้อมูลเซนเซอร์ผูกกับใบงานนี้'), findsOneWidget);

    await tester.tap(find.text('ผูกข้อมูล'));
    await tester.pumpAndSettle();

    // มิเตอร์น้ำ (metric ไม่อยู่ใน enum) และรีเลย์ (ไม่ใช่เซนเซอร์) ต้องไม่โผล่
    expect(find.text('เซนเซอร์คุณภาพอากาศ · ห้อง 101'), findsOneWidget);
    expect(find.textContaining('มิเตอร์น้ำ'), findsNothing);
    expect(find.textContaining('รีเลย์ไฟ'), findsNothing);

    // metric dropdown ต้องกรองเหลือแค่ pm25/aqi/temperature/humidity (ตัด
    // co2/tvoc/gas_mq2_percent ที่ air_quality_sensor วัดได้แต่ enum ไม่รับ)
    expect(find.text('co2'), findsNothing);
    expect(find.text('tvoc'), findsNothing);
  });

  testWidgets('บันทึกเรียก linkSensorDataset จริงด้วย assignment id จริง แล้วรีเฟรชลิสต์', (
    tester,
  ) async {
    String? calledAssignmentId;
    String? calledDeviceId;
    String? calledMetric;
    var refreshed = false;

    await pumpEditor(
      tester,
      listDevices: () async => const [airQualityDevice],
      linkSensorDataset:
          ({
            required assignmentId,
            required deviceId,
            required metric,
            timeStart,
            timeEnd,
            label,
          }) async {
            calledAssignmentId = assignmentId;
            calledDeviceId = deviceId;
            calledMetric = metric;
          },
      loadAssignmentDetail: (_) async {
        if (!refreshed) {
          refreshed = true;
          return detailNoDatasets;
        }
        return const AssignmentDetail(
          id: 'asg-1',
          courseId: 'course-a',
          type: 'homework',
          title: 'ใบงานเซนเซอร์',
          instructions: null,
          dueAt: null,
          status: 'published',
          sensorDatasets: [
            AssignmentSensorDataset(
              id: 'ds-1',
              deviceId: 'dev-air',
              metric: 'pm25',
              timeStart: null,
              timeEnd: null,
              label: null,
            ),
          ],
        );
      },
    );

    await tester.tap(find.text('ผูกข้อมูล'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ผูกข้อมูล').last);
    await tester.pumpAndSettle();

    expect(calledAssignmentId, 'asg-1');
    expect(calledDeviceId, 'dev-air');
    expect(calledMetric, 'pm25');
    // อ่านกลับจากหลังบ้านจริง ไม่ใช่เติมรายการในเครื่องเอง
    expect(find.textContaining('เซนเซอร์คุณภาพอากาศ · pm25'), findsOneWidget);
  });

  testWidgets('ช่วงเวลา: chip "7 วันล่าสุด" ส่ง timeStart/timeEnd จริงไปที่ RPC', (
    tester,
  ) async {
    DateTime? gotStart;
    DateTime? gotEnd;
    await pumpEditor(
      tester,
      listDevices: () async => const [airQualityDevice],
      linkSensorDataset:
          ({
            required assignmentId,
            required deviceId,
            required metric,
            timeStart,
            timeEnd,
            label,
          }) async {
            gotStart = timeStart;
            gotEnd = timeEnd;
          },
      loadAssignmentDetail: (_) async => detailNoDatasets,
    );

    await tester.tap(find.text('ผูกข้อมูล'));
    await tester.pumpAndSettle();

    // ค่าเริ่มต้นคือ "ไม่กำหนด" ทั้งสองช่อง — นักเรียนได้ 24 ชม.ล่าสุด
    expect(find.text('ไม่กำหนด'), findsNWidgets(2));

    await tester.tap(find.text('7 วันล่าสุด'));
    await tester.pumpAndSettle();
    expect(find.text('ไม่กำหนด'), findsNothing);

    final before = DateTime.now();
    await tester.tap(find.widgetWithText(FilledButton, 'ผูกข้อมูล').last);
    await tester.pumpAndSettle();

    expect(gotStart, isNotNull);
    expect(gotEnd, isNotNull);
    final span = gotEnd!.difference(gotStart!);
    expect(span.inHours, 7 * 24);
    expect(gotEnd!.difference(before).inMinutes.abs() <= 1, isTrue);
  });
}
