import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_lesson_editor_page.dart';
import 'package:shared_core/shared_core.dart';

/// ปุ่ม "ผูกข้อมูล AIoT Sensor" เคยถูกปิดไว้ด้วยเหตุผลที่ไม่จริงแล้ว (ว่าฝั่ง
/// นักเรียนไม่มีโค้ดอ่านลิงก์ — ทั้ง 2 หน้าบทเรียนนักเรียนอ่าน `sensorLinks`
/// อยู่) ตอนนี้ต่อจริง: รายการอุปกรณ์จาก list_school_devices และบันทึกผ่าน
/// link_lesson_sensor — เทสต์นี้ล็อกว่าค่าที่เลือกถูกส่งไปหลังบ้านจริง
LessonModel _lesson({String id = 'lesson-1'}) => LessonModel(
  id: id,
  courseCode: 'CS101',
  courseName: 'IoT Basics',
  title: 'บทที่ 1: เซนเซอร์ PM2.5',
  status: LessonStatus.draft,
  lastEdited: 'เมื่อสักครู่',
  materialsCount: 0,
  sensorChartsCount: 0,
  blocks: [
    ContentBlockModel(id: 'b-1', type: ContentBlockType.text, text: 'เนื้อหา'),
  ],
  materials: [],
  sensorLinks: [],
);

const _pm25 = DeviceOption(
  id: 'dev-pm25',
  name: 'PM2.5 ห้อง 101',
  type: 'pm25_sensor',
  location: 'อาคาร 1 ชั้น 1',
  status: 'online',
);

Future<void> _pump(
  WidgetTester tester, {
  required LessonModel lesson,
  required Future<List<DeviceOption>> Function() listDevices,
  Future<void> Function({
    required String lessonId,
    required String deviceId,
    required String metric,
    String? caption,
  })?
  linkSensor,
}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: TeacherLessonEditorPage(
        lesson: lesson,
        listDevices: listDevices,
        linkSensor: linkSensor,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  await tester.tap(find.textContaining('ผูก AIoT'));
  await tester.pump();
}

void main() {
  testWidgets('linking a sensor sends the chosen device/metric to the real RPC', (
    tester,
  ) async {
    String? sentLesson, sentDevice, sentMetric, sentCaption;
    await _pump(
      tester,
      lesson: _lesson(),
      listDevices: () async => const [_pm25],
      linkSensor: ({
        required lessonId,
        required deviceId,
        required metric,
        caption,
      }) async {
        sentLesson = lessonId;
        sentDevice = deviceId;
        sentMetric = metric;
        sentCaption = caption;
      },
    );

    final button = find.text('+ ผูกข้อมูล AIoT Sensor');
    expect(button, findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(
        find.ancestor(
          of: button,
          matching: find.byWidgetPredicate((w) => w is ElevatedButton),
        ),
      ).onPressed,
      isNotNull,
      reason: 'the backend exists on both sides — the button must be live',
    );
    await tester.tap(button);
    await tester.pumpAndSettle();

    // อุปกรณ์จริงจาก list_school_devices อยู่ในตัวเลือก
    expect(find.textContaining('PM2.5 ห้อง 101'), findsWidgets);
    await tester.enterText(
      find.widgetWithText(TextField, 'คำอธิบายกราฟ (ถ้ามี)'),
      'ฝุ่นตอนเช้า',
    );
    await tester.tap(find.text('ผูกข้อมูล'));
    await tester.pumpAndSettle();

    expect(sentLesson, 'lesson-1');
    expect(sentDevice, 'dev-pm25');
    expect(sentMetric, 'pm25', reason: 'pm25_sensor only measures pm25');
    expect(sentCaption, 'ฝุ่นตอนเช้า');
    expect(find.text('ผูกข้อมูลเซนเซอร์กับบทเรียนแล้ว'), findsOneWidget);
  });

  testWidgets('a failed link stays in the dialog with a fixed sentence, no leaked exception', (
    tester,
  ) async {
    await _pump(
      tester,
      lesson: _lesson(),
      listDevices: () async => const [_pm25],
      linkSensor: ({
        required lessonId,
        required deviceId,
        required metric,
        caption,
      }) async => throw Exception('PostgrestException: link_boom'),
    );

    await tester.tap(find.text('+ ผูกข้อมูล AIoT Sensor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ผูกข้อมูล'));
    await tester.pumpAndSettle();

    expect(find.text('ผูกข้อมูลเซนเซอร์ไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'), findsOneWidget);
    expect(find.textContaining('link_boom'), findsNothing);
    expect(find.text('ผูกข้อมูลเซนเซอร์กับบทเรียนแล้ว'), findsNothing);
  });

  testWidgets('an unsaved draft cannot link a sensor yet, and says why', (
    tester,
  ) async {
    await _pump(
      tester,
      lesson: _lesson(id: ''),
      listDevices: () async => const [_pm25],
    );

    final button = find.text('+ ผูกข้อมูล AIoT Sensor (บันทึกบทเรียนก่อน)');
    expect(button, findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(
        find.ancestor(
          of: button,
          matching: find.byWidgetPredicate((w) => w is ElevatedButton),
        ),
      ).onPressed,
      isNull,
    );
  });
}
