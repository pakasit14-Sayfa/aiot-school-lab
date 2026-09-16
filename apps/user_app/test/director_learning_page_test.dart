import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_learning_page.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/controllers/director_learning_controller.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_core/models/school_homeroom_attendance.dart';

const summary = ClassroomsOverviewItem(
  roomCount: 2,
  courseCount: 4,
  activeStudentCount: 3,
  assignmentsDueThisWeek: 1,
);
const empty = ClassroomsOverviewItem(
  roomCount: 0,
  courseCount: 0,
  activeStudentCount: 0,
  assignmentsDueThisWeek: 0,
);
const attendance = [
  SchoolHomeroomAttendance(
    gradeLevel: 'ม.1',
    room: '1',
    studentCount: 2,
    present: 1,
    late: 0,
    absent: 0,
    excused: 0,
    unknown: 1,
  ),
  SchoolHomeroomAttendance(
    gradeLevel: 'ม.2',
    room: '1',
    studentCount: 1,
    present: 0,
    late: 0,
    absent: 0,
    excused: 0,
    unknown: 1,
  ),
];
DirectorLearningController fixture({
  Future<ClassroomsOverviewItem?> Function()? overview,
  Future<List<SchoolHomeroomAttendance>> Function(DateTime)? loadAttendance,
  Future<List<AutoFlaggedStudent>> Function()? autoFlags,
  Future<String?> Function(AutoFlaggedStudent)? openCase,
  Future<List<StudentSupportCase>> Function()? cases,
  Future<List<StudentSupportIntervention>> Function(String)? interventions,
  Future<StudentFollowupSummary?> Function()? followupSummary,
  DateTime? date,
}) => DirectorLearningController(
  overview: overview ?? () async => summary,
  tracks: () async => const [
    LearningTrackOverview(
      trackId: 't1',
      name: 'สายจริง',
      color: '#112233',
      sortOrder: 0,
      studentCount: 2,
      roomCount: 1,
    ),
  ],
  rooms: () async => const [
    LearningTrackRoom(
      gradeLevel: 'ม.1',
      room: '1',
      studentCount: 2,
      trackId: 't1',
      trackName: 'สายจริง',
    ),
  ],
  attendance: loadAttendance ?? (_) async => attendance,
  cases: cases ?? () async => [],
  interventions: interventions ?? (_) async => [],
  autoFlags: autoFlags,
  openCase: openCase,
  followupSummary: followupSummary,
  date: date,
);
Widget page(DirectorLearningController controller) => MaterialApp(
  home: Scaffold(
    body: DirectorLearningPage(
      key: ValueKey(controller),
      controller: controller,
    ),
  ),
);

void main() {
  testWidgets(
    'loading, error, retry and empty are distinct without fabricated totals',
    (tester) async {
      final pending = Completer<ClassroomsOverviewItem?>();
      var attempt = 0;
      final controller = DirectorLearningController(
        overview: () => ++attempt == 1 ? pending.future : Future.value(empty),
        tracks: () async => [],
        rooms: () async => [],
        attendance: (_) async => [],
        cases: () async => [],
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(page(controller));
      expect(find.text('กำลังโหลดข้อมูลนักเรียน'), findsOneWidget);
      expect(find.text('ภาพรวมปัจจุบันของโรงเรียน'), findsNothing);
      pending.completeError(StateError('private diagnostic'));
      await tester.pumpAndSettle();
      expect(find.text('โหลดข้อมูลไม่สำเร็จ'), findsOneWidget);
      expect(find.textContaining('private diagnostic'), findsNothing);
      await tester.tap(find.text('ลองอีกครั้ง'));
      await tester.pumpAndSettle();
      expect(find.text('ยังไม่มีข้อมูลนักเรียนหรือการเรียน'), findsOneWidget);
    },
  );
  testWidgets(
    'real counts, unknown attendance, missing grades and effective filters',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = fixture();
      addTearDown(controller.dispose);
      await tester.pumpWidget(page(controller));
      await tester.pumpAndSettle();
      expect(find.text('นักเรียนที่ใช้งานอยู่ 3 คน'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      // ม.1/1: present=1,unknown=1 → เช็คไปแล้วบางส่วน (100% ของคนที่เช็ค
      // แล้วเท่านั้น ไม่ใช่ 100% ของทั้งห้อง) และ ม.2/1: present=0,unknown=1
      // → ยังไม่เช็คเลยทั้งห้อง — ทั้งคู่ต้องขึ้น "ยังไม่เช็คชื่อ 1 คน" เหมือน
      // กัน (โครงต้นไม้ V3: ดูจุดนี้ยังคงพฤติกรรมเดิมของ _roomDetailCard)
      expect(find.text('ยังไม่เช็คชื่อ 1 คน'), findsNWidgets(2));
      // ม.1 มีห้องเดียว (ม.1/1) ทั้งหัวข้อระดับชั้นและแถวห้องเลยขึ้น 100%
      // ตรงกันทั้งคู่ — คนละ Text widget กัน (แถวระดับชั้น vs แถวห้อง)
      expect(find.text('100%'), findsNWidgets(2));
      expect(find.text('ม.1/1'), findsOneWidget);
      expect(find.text('ม.2/1'), findsOneWidget);
      expect(find.text('ยังไม่มีคะแนนที่ยืนยันแล้ว'), findsOneWidget);
      expect(find.textContaining('1,248'), findsNothing);
      await tester.tap(find.text('ทุกระดับชั้น'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ม.2').last);
      await tester.pumpAndSettle();
      expect(find.text('ม.1/1'), findsNothing);
      expect(find.text('ม.2/1'), findsOneWidget);
      await tester.tap(find.text('ทุกสายการเรียน'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('สายจริง').last);
      await tester.pumpAndSettle();
      expect(find.text('ยังไม่มีข้อมูลนักเรียนในตัวกรองนี้'), findsOneWidget);
      // Was onPressed:null when this "งานติดตามที่ยังไม่รองรับ" placeholder
      // had no backend at all — real now (see director_student_followup_page_test.dart
      // for the RPC-backed behavior this button actually triggers). It's a
      // FilledButton.icon (subclass) under label text, so match the shared
      // ButtonStyleButton base rather than a specific button type.
      expect(
        (tester.widget(
                  find.ancestor(
                    of: find.text('เปิดระบบติดตามนักเรียน'),
                    matching: find.byWidgetPredicate(
                      (w) => w is ButtonStyleButton,
                    ),
                  ),
                )
                as ButtonStyleButton)
            .onPressed,
        isNotNull,
      );
    },
  );
  test('switching date discards late results from the earlier date', () async {
    final old = Completer<List<SchoolHomeroomAttendance>>();
    final controller = fixture(
      loadAttendance: (date) => date.day == 1 ? old.future : Future.value([]),
    );
    addTearDown(controller.dispose);
    final first = controller.load(onDate: DateTime(2026, 9, 1));
    await controller.load(onDate: DateTime(2026, 9, 2));
    old.complete(attendance);
    await first;
    expect(controller.date, DateTime(2026, 9, 2));
    expect(controller.attendance, isEmpty);
  });
  testWidgets('responsive at 320, 390, 768 and 1440 pixels', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = fixture();
    addTearDown(controller.dispose);
    await tester.pumpWidget(page(controller));
    for (final size in [
      const Size(320, 568),
      const Size(390, 844),
      const Size(768, 1024),
      const Size(1440, 900),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Layout at $size');
    }
  });

  testWidgets(
    'opens an automatic case, refreshes it into cases, and loads history',
    (tester) async {
      final flag = const AutoFlaggedStudent(
        studentId: 'student-1',
        studentName: 'นักเรียนทดสอบ',
        reason: 'งานค้าง',
        detail: 'ค้างส่ง 2 งาน',
        actionLabel: 'ติดตามงาน',
        severity: 'high',
      );
      var opened = false;
      var historyRequested = false;
      final controller = DirectorLearningController(
        overview: () async => summary,
        tracks: () async => [],
        rooms: () async => [],
        attendance: (_) async => [],
        autoFlags: () async => opened ? [] : [flag],
        cases: () async => opened
            ? [
                StudentSupportCase(
                  caseId: 'case-1',
                  studentId: flag.studentId,
                  studentName: flag.studentName,
                  studentEmail: '',
                  courseName: 'ภาพรวมทั่วไป',
                  category: 'academic',
                  riskLevel: 'high',
                  status: 'open',
                  title: '${flag.reason}: ${flag.detail}',
                  createdByName: 'ผู้อำนวยการ',
                  interventionCount: 0,
                  createdAt: DateTime(2026),
                  updatedAt: DateTime(2026),
                ),
              ]
            : [],
        interventions: (_) async {
          historyRequested = true;
          return [];
        },
        openCase: (_) async {
          opened = true;
          return 'case-1';
        },
      );
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.flaggedStudents, hasLength(1));
      await controller.openCaseFromFlag(flag);
      expect(controller.flaggedStudents, isEmpty);
      expect(controller.cases, hasLength(1));
      await controller.history(controller.cases.single.caseId);
      expect(historyRequested, isTrue);
    },
  );
  testWidgets(
    'watchlist shows a real auto-flagged student and dispatches care from the UI',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const flag = AutoFlaggedStudent(
        studentId: 'student-9',
        studentName: 'เด็กหญิงทดสอบ',
        reason: 'ขาดเรียนต่อเนื่อง',
        detail: 'ขาด 3 วันติดกัน',
        actionLabel: 'สั่งการดูแล',
        severity: 'urgent',
        gradeLevel: 'ม.2',
        room: 'ม.2/3',
        advisorName: 'ครูสมหญิง ใจดี',
      );
      var caseOpened = false;
      final controller = fixture(
        autoFlags: () async => caseOpened ? [] : [flag],
        openCase: (_) async {
          caseOpened = true;
          return 'case-9';
        },
        cases: () async => caseOpened
            ? [
                StudentSupportCase(
                  caseId: 'case-9',
                  studentId: flag.studentId,
                  studentName: flag.studentName,
                  studentEmail: '',
                  courseName: 'ภาพรวมทั่วไป',
                  category: 'behavioral',
                  riskLevel: 'high',
                  status: 'open',
                  title: '${flag.reason}: ${flag.detail}',
                  createdByName: 'ผู้อำนวยการ',
                  interventionCount: 0,
                  createdAt: DateTime(2026),
                  updatedAt: DateTime(2026),
                ),
              ]
            : [],
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(page(controller));
      await tester.pumpAndSettle();
      expect(find.textContaining('EXECUTIVE WATCHLIST'), findsOneWidget);
      expect(find.text('เด็กหญิงทดสอบ'), findsOneWidget);
      expect(find.text('ขาด 3 วันติดกัน'), findsOneWidget);
      expect(find.text('ม.2/3'), findsOneWidget);
      expect(find.text('วิกฤต'), findsOneWidget);
      expect(find.text('ครูที่ปรึกษา: ครูสมหญิง ใจดี'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'ดูประวัติ'),
            )
            .onPressed,
        isNull,
        reason: 'ยังไม่เคยเปิดเคสจริง ปุ่มดูประวัติต้องกดไม่ได้',
      );

      await tester.tap(find.text('สั่งการดูแล'));
      await tester.pumpAndSettle();
      expect(caseOpened, isTrue);
      expect(find.textContaining('EXECUTIVE WATCHLIST'), findsNothing);
    },
  );

  testWidgets(
    'watchlist history button opens when the student already has a real case on file',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const flag = AutoFlaggedStudent(
        studentId: 'student-9',
        studentName: 'เด็กหญิงทดสอบ',
        reason: 'คะแนนเฉลี่ยต่ำ',
        detail: 'เฉลี่ย 36%',
        actionLabel: 'ดูคะแนน',
        severity: 'normal',
      );
      var historyRequested = false;
      final controller = fixture(
        autoFlags: () async => [flag],
        cases: () async => [
          StudentSupportCase(
            caseId: 'case-old',
            studentId: flag.studentId,
            studentName: flag.studentName,
            studentEmail: '',
            courseName: 'ภาพรวมทั่วไป',
            category: 'academic',
            riskLevel: 'medium',
            status: 'resolved',
            title: 'ค้างส่งงาน: ค้างส่ง 2 งาน',
            createdByName: 'ผู้อำนวยการ',
            interventionCount: 2,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        ],
        interventions: (id) async {
          historyRequested = id == 'case-old';
          return [];
        },
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(page(controller));
      await tester.pumpAndSettle();
      expect(find.text('เฝ้าระวัง'), findsOneWidget);
      final historyButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'ดูประวัติ'),
      );
      expect(
        historyButton.onPressed,
        isNotNull,
        reason: 'นักเรียนคนนี้มีเคสจริงในระบบแล้ว ต้องกดดูประวัติได้',
      );
      await tester.tap(find.text('ดูประวัติ'));
      await tester.pumpAndSettle();
      expect(historyRequested, isTrue);
    },
  );

  testWidgets(
    'support history dialog shows real case fields and a real intervention timeline, not the invented 3-step one',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = fixture(
        cases: () async => [
          StudentSupportCase(
            caseId: 'case-real',
            studentId: 'student-real',
            studentName: 'ด.ช.ทดสอบ จริงใจ',
            studentEmail: '',
            courseName: 'AIoT ชีววิทยาและสิ่งแวดล้อม',
            category: 'behavioral',
            riskLevel: 'high',
            status: 'open',
            title: 'ขาดเรียนต่อเนื่อง',
            notes: 'ขาดเรียน 3 วันติด ไม่มีใบลา',
            createdByName: 'ผู้อำนวยการ',
            interventionCount: 1,
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
            updatedAt: DateTime.now(),
            gradeLevel: 'ม.3',
            room: 'ม.3/2',
          ),
        ],
        interventions: (_) async => [
          StudentSupportIntervention(
            interventionId: 'iv-1',
            caseId: 'case-real',
            actionType: 'parent_meeting',
            notes: 'โทรแจ้งผู้ปกครองแล้ว นัดเข้าพบวันศุกร์',
            recordedByName: 'ครูสมหญิง ใจดี',
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(page(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ดูประวัติ (1)'));
      await tester.pumpAndSettle();

      // หัวการ์ดใช้ข้อมูลจริงจาก StudentSupportCase ที่มีอยู่แล้ว
      expect(find.text('ด.ช.ทดสอบ จริงใจ'), findsOneWidget);
      expect(find.textContaining('ห้อง ม.3/ม.3/2'), findsOneWidget);
      expect(
        find.textContaining('AIoT ชีววิทยาและสิ่งแวดล้อม'),
        findsOneWidget,
      );
      expect(
        find.textContaining('ประเด็นที่ต้องติดตาม: ขาดเรียนต่อเนื่อง'),
        findsOneWidget,
      );
      expect(
        find.textContaining('หมวดหมู่: ด้านพฤติกรรม & การเข้าเรียน • เปิดเคส'),
        findsOneWidget,
      );
      expect(find.text('ขาดเรียน 3 วันติด ไม่มีใบลา'), findsWidgets);

      // ไทม์ไลน์แสดงบันทึกจริง 1 รายการ ไม่ใช่ empty-state
      expect(find.text('ติดต่อผู้ปกครอง'), findsOneWidget);
      expect(
        find.text('โทรแจ้งผู้ปกครองแล้ว นัดเข้าพบวันศุกร์'),
        findsOneWidget,
      );
      expect(find.textContaining('ครูสมหญิง ใจดี'), findsOneWidget);
      expect(find.text('ยังไม่มีบันทึกการช่วยเหลือ'), findsNothing);

      // ต้นฉบับวันที่ 7 แต่งไทม์ไลน์ตายตัว 3 ขั้น + ปุ่มโทร — ของจริงต้องไม่มี
      expect(find.textContaining('ระบบตรวจพบ'), findsNothing);
      expect(find.textContaining('ผู้อำนวยการเข้าติดตาม'), findsNothing);
      expect(find.text('โทรหาครูประจำชั้น'), findsNothing);
    },
  );

  testWidgets(
    'student care system dimension rows show a real close-rate percentage, not the invented 5-metric checklist',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = fixture(
        cases: () async => [
          StudentSupportCase(
            caseId: 'c1',
            studentId: 's1',
            studentName: 'นักเรียน หนึ่ง',
            studentEmail: '',
            courseName: 'วิชาทดสอบ',
            category: 'academic',
            riskLevel: 'medium',
            status: 'resolved',
            title: 'ผลการเรียนตก',
            createdByName: 'ครู',
            interventionCount: 0,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
          StudentSupportCase(
            caseId: 'c2',
            studentId: 's2',
            studentName: 'นักเรียน สอง',
            studentEmail: '',
            courseName: 'วิชาทดสอบ',
            category: 'academic',
            riskLevel: 'medium',
            status: 'open',
            title: 'ผลการเรียนตก',
            createdByName: 'ครู',
            interventionCount: 0,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        ],
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(page(controller));
      await tester.pumpAndSettle();

      // 1 ใน 2 เคสด้านการเรียนปิดแล้ว = 50% ไม่ใช่ตัวเลขคุณภาพงานที่แต่งขึ้น
      // แบบ "คัดกรองครบ 1,228/1,248 คน" ของเวอร์ชัน 7 ก.ย. — ข้อความ "ด้านการ
      // เรียน" ขึ้น 2 จุดจริง (legend ของวงแหวนสรุป + badge ของแต่ละเคสใน
      // รายการด้านล่าง) วงแหวนซ้อน 4 ชั้น (V5) ไม่มีตัวเลขกลางวงแล้ว ตัวเลข
      // % ปิดของแต่ละมิติอยู่ที่ legend ทั้งหมด
      expect(find.text('ด้านการเรียน'), findsWidgets);
      expect(find.text('50%'), findsOneWidget);

      for (final invented in <String>[
        'การคัดกรองและประเมิน SDQ',
        'โครงการเยี่ยมบ้าน',
        'การส่งเสริมและพัฒนาทักษะชีวิต',
        'การให้คำปรึกษาและสุขภาพจิต',
        'ทุนการศึกษาและสวัสดิการ',
      ]) {
        expect(find.textContaining(invented), findsNothing, reason: invented);
      }
    },
  );

  // red-team: หน้านี้ยาวมาก 9+ ส่วน ไม่มีลำดับความสำคัญ — ย้าย "สิ่งที่ต้อง
  // ดำเนินการ" ขึ้นมาไว้ต่อจาก watchlist แทนที่จะอยู่ล่างสุดของหน้า
  testWidgets(
    'executive action items digest appears above the detailed cards, not buried at the bottom',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = fixture(
        loadAttendance: (_) async => const [
          SchoolHomeroomAttendance(
            gradeLevel: 'ม.1',
            room: '1',
            studentCount: 10,
            present: 2,
            late: 0,
            absent: 8,
            excused: 0,
            unknown: 0,
          ),
        ],
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(page(controller));
      await tester.pumpAndSettle();

      final actionItemsTop = tester
          .getTopLeft(find.textContaining('ข้อเสนอแนะเชิงบริหารและงานติดตาม'))
          .dy;
      final programAnalyticsTop = tester
          .getTopLeft(
            find.textContaining('การวิเคราะห์ผลการเรียนและสายการเรียน'),
          )
          .dy;
      final gradeDeepDiveTop = tester
          .getTopLeft(
            find.text('ข้อมูลเจาะลึกรายระดับชั้น (Grade-Level Deep Dive)'),
          )
          .dy;
      expect(
        actionItemsTop,
        lessThan(programAnalyticsTop),
        reason: 'สรุปสิ่งที่ต้องดำเนินการต้องอยู่เหนือการ์ดรายละเอียด',
      );
      expect(
        actionItemsTop,
        lessThan(gradeDeepDiveTop),
        reason: 'ต้องอยู่เหนือการ์ดเจาะลึกรายระดับชั้นด้วยเช่นกัน',
      );
      // red-team: ย้ายการ์ดนี้ขึ้นมาไว้เหนือ "ข้อมูลเจาะลึกรายระดับชั้น" แล้ว
      // ข้อความอ้างอิงต้องบอก "ด้านล่าง" ไม่ใช่ "ด้านบน" ที่ชี้ผิดทาง
      expect(
        find.textContaining('ข้อมูลเจาะลึกรายระดับชั้น" ด้านล่าง'),
        findsOneWidget,
      );
      expect(find.textContaining('ด้านบน'), findsNothing);
    },
  );

  // red-team: "เคสดูแล" บนการ์ดรายระดับชั้นเดิมนับจาก controller.cases ทั้งหมด
  // เสมอ ไม่สนตัวกรองสถานะที่เลือกอยู่ ทำให้ตัวเลขไม่ตรงกับรายการเคสด้านล่าง
  testWidgets(
    'grade card case count matches the selected status filter, not every case ever',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = fixture(
        cases: () async => [
          StudentSupportCase(
            caseId: 'c1',
            studentId: 's1',
            studentName: 'นักเรียน หนึ่ง',
            studentEmail: '',
            courseName: 'วิชาทดสอบ',
            category: 'academic',
            riskLevel: 'medium',
            status: 'open',
            title: 'เรื่องที่ 1',
            createdByName: 'ครู',
            interventionCount: 0,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
            gradeLevel: 'ม.1',
          ),
          StudentSupportCase(
            caseId: 'c2',
            studentId: 's2',
            studentName: 'นักเรียน สอง',
            studentEmail: '',
            courseName: 'วิชาทดสอบ',
            category: 'academic',
            riskLevel: 'medium',
            status: 'resolved',
            title: 'เรื่องที่ 2',
            createdByName: 'ครู',
            interventionCount: 0,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
            gradeLevel: 'ม.1',
          ),
        ],
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(page(controller));
      await tester.pumpAndSettle();

      final countFinder = find.byKey(const ValueKey('grade_case_count_ม.1'));
      expect(tester.widget<Text>(countFinder).data, '2');

      await tester.tap(find.widgetWithText(ChoiceChip, 'ปิดเคสสำเร็จ'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(countFinder).data,
        '1',
        reason:
            'กรอง "ปิดเคสสำเร็จ" แล้วต้องเหลือแค่เคสที่ปิดจริง ไม่ใช่ยอดรวมเดิม',
      );
    },
  );

  testWidgets(
    'follow-up system card shows real counts from the summary RPC, not invented ones',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = fixture(
        followupSummary: () async => const StudentFollowupSummary(
          homeVisitsThisMonth: 7,
          homeVisitsFollowUpNeeded: 1,
          sdqAssessmentsTotal: 9,
          sdqAssessmentsThisMonth: 1,
          scholarshipsActive: 6,
          scholarshipAwardsPending: 1,
          directivesOpen: 8,
          directivesOverdue: 1,
        ),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(page(controller));
      await tester.pumpAndSettle();

      expect(find.text('งานติดตามนักเรียนรายบุคคล'), findsOneWidget);
      expect(find.text('7'), findsOneWidget); // home visits this month
      expect(find.text('9'), findsOneWidget); // sdq total
      expect(find.text('6'), findsOneWidget); // scholarships active
      expect(find.text('8'), findsOneWidget); // directives open
      // Both actions must be real, not onPressed:null placeholders. Just 2
      // now — was 4 separate buttons that all opened the same page on
      // different starting tabs, which read as 4 fake choices once you
      // noticed they landed on one screen; consolidated to one entry point
      // plus the genuinely distinct "export a file" action.
      for (final label in ['เปิดระบบติดตามนักเรียน', 'ส่งออกรายงานการเรียน']) {
        // "เปิดระบบติดตามนักเรียน" is a FilledButton.icon, "ส่งออกรายงานการเรียน"
        // an OutlinedButton.icon — both .icon factories build internal
        // subclasses, so match the shared ButtonStyleButton base instead of
        // one concrete type.
        final button =
            tester.widget(
                  find.ancestor(
                    of: find.text(label),
                    matching: find.byWidgetPredicate(
                      (w) => w is ButtonStyleButton,
                    ),
                  ),
                )
                as ButtonStyleButton;
        expect(
          button.onPressed,
          isNotNull,
          reason: '"$label" ต้องกดได้จริง ไม่ใช่ onPressed:null แบบเดิม',
        );
      }
    },
  );

  testWidgets(
    'a summary load failure degrades only the follow-up card, not the whole page',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = fixture(
        followupSummary: () async => throw StateError('summary_unreachable'),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(page(controller));
      await tester.pumpAndSettle();

      // The rest of the page — real, previously-working data — still loads.
      expect(find.text('นักเรียนที่ใช้งานอยู่ 3 คน'), findsOneWidget);
      expect(
        find.textContaining('ยังโหลดสรุปงานติดตามไม่สำเร็จ'),
        findsOneWidget,
      );
      expect(find.textContaining('summary_unreachable'), findsNothing);
    },
  );

  testWidgets(
    'opening the follow-up system from the real navigation path does not crash '
    '(DirectorStudentFollowupPage is pushed bare via MaterialPageRoute, with no '
    'outer Scaffold providing a Material ancestor for its own TabBar — a widget '
    'test that wraps the page in its own Scaffold, like director_student_followup_page_test.dart '
    'does, would hide this)',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = fixture();
      addTearDown(controller.dispose);
      await tester.pumpWidget(page(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('เปิดระบบติดตามนักเรียน'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('งานติดตามนักเรียนรายบุคคล'), findsOneWidget);
      expect(find.text('เยี่ยมบ้าน'), findsOneWidget);
      expect(find.text('SDQ'), findsOneWidget);
    },
  );

  testWidgets(
    'redesigned filter menu marks the currently selected option with a checkmark',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = fixture();
      addTearDown(controller.dispose);
      await tester.pumpWidget(page(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ทุกระดับชั้น'));
      await tester.pumpAndSettle();

      // "ทุกระดับชั้น" is the current selection (nothing picked yet) — its
      // menu row carries the checkmark, the other option (ม.1) doesn't.
      final allRow = find.ancestor(
        of: find.text('ทุกระดับชั้น').last,
        matching: find.byType(Row),
      );
      expect(
        find.descendant(
          of: allRow.first,
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      final gradeRow = find.ancestor(
        of: find.text('ม.1'),
        matching: find.byType(Row),
      );
      expect(
        find.descendant(
          of: gradeRow.first,
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    '"วันนี้" quick-jump: hidden when already on today, jumps for real when shown',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Already on today — no quick-jump link needed.
      final onToday = fixture();
      addTearDown(onToday.dispose);
      await tester.pumpWidget(page(onToday));
      await tester.pumpAndSettle();
      expect(find.text('วันนี้'), findsNothing);

      // Showing an old date — link appears and actually reloads onto today,
      // not just changes a label.
      final onOldDate = fixture(date: DateTime(2020, 1, 1));
      addTearDown(onOldDate.dispose);
      await tester.pumpWidget(page(onOldDate));
      await tester.pumpAndSettle();
      expect(find.text('1/1/2020'), findsOneWidget);
      expect(find.text('วันนี้'), findsOneWidget);

      await tester.tap(find.text('วันนี้'));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      expect(onOldDate.date.year, now.year);
      expect(onOldDate.date.month, now.month);
      expect(onOldDate.date.day, now.day);
      expect(find.text('วันนี้'), findsNothing);
    },
  );
}
