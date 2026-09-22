import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/student_redesign_prototype/widgets/lesson_block_view.dart';
import 'package:my_first_app/pages/student_redesign_prototype/widgets/student_lesson_view_page.dart';
import 'package:shared_core/shared_core.dart';

/// ครูจัดเนื้อหาเป็นบล็อกในหน้าแก้ไขบทเรียน แล้วบันทึกลง
/// `lessons.content['blocks']` — จนถึง 2026-09-22 หน้านักเรียนอ่านแค่
/// `content['body']` ข้อความแบน หัวข้อจึงหายทั้งหมดและกล่องเตือน/กล่องสรุป
/// กลายเป็นข้อความธรรมดา เทสต์ชุดนี้ตรึงไว้ว่าบล็อกไปถึงนักเรียนจริง
/// และบทเรียนรุ่นเก่าที่ยังไม่มีบล็อกต้องไม่จอว่าง

const _course = CourseDetail(
  id: 'course-1',
  subjectName: 'วิทยาศาสตร์ ม.2',
  gradeLevel: 'ม.2',
  room: '203',
  description: null,
  status: 'active',
  termId: 'term-1',
  teacherNames: 'ครูสมชาย',
);

const _materials = [
  LessonMaterial(
    id: 'mat-img',
    type: 'image',
    title: 'ผังการต่อสาย.png',
    url: 'lessons/1/wiring.png',
    sortOrder: 0,
  ),
  LessonMaterial(
    id: 'mat-file',
    type: 'file',
    title: 'ใบงาน.pdf',
    url: 'lessons/1/sheet.pdf',
    sortOrder: 1,
  ),
];

LessonDetail _lesson(Map<String, dynamic>? content) => LessonDetail(
  id: 'lesson-1',
  courseId: 'course-1',
  title: 'การวัดอุณหภูมิในห้องเรียน',
  content: content,
  status: 'published',
  publishedAt: DateTime(2026, 9, 20),
  materials: _materials,
  sensorLinks: const [],
  progressPct: 10,
  completed: false,
);

Future<void> _pump(WidgetTester tester, Map<String, dynamic>? content) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: StudentLessonViewPage(
        lessonId: 'lesson-1',
        getLesson: (_) async => _lesson(content),
        getCourse: (_) async => _course,
        updateProgress: ({required lessonId, required progressPct}) async {},
        markComplete: (_) async {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Map<String, dynamic> _blocks(List<Map<String, String>> raw) => {
  'body': raw
      .where((b) => b['type'] != 'heading')
      .map((b) => b['text'])
      .join('\n\n'),
  'blocks': [
    for (var i = 0; i < raw.length; i++) {'id': 'b$i', ...raw[i]},
  ],
};

void main() {
  group('หน้านักเรียนอ่าน content.blocks', () {
    testWidgets('บล็อกหัวข้อต้องแสดง ไม่ใช่หายไปกับ body', (tester) async {
      await _pump(
        tester,
        _blocks([
          {'type': 'heading', 'text': 'การติดตั้งเซนเซอร์'},
          {'type': 'text', 'text': 'วางเซนเซอร์ให้ห่างหน้าต่าง'},
        ]),
      );

      expect(find.text('การติดตั้งเซนเซอร์'), findsOneWidget);
      expect(find.text('วางเซนเซอร์ให้ห่างหน้าต่าง'), findsOneWidget);
    });

    testWidgets('กล่องเตือนและกล่องสรุปแยกออกจากข้อความธรรมดา', (tester) async {
      await _pump(
        tester,
        _blocks([
          {'type': 'calloutWarning', 'text': 'อย่าถอดสายขณะบันทึก'},
          {'type': 'summaryBox', 'text': 'อุณหภูมิสูงสุดช่วงบ่าย'},
        ]),
      );

      expect(find.text('อย่าถอดสายขณะบันทึก'), findsOneWidget);
      expect(find.text('อุณหภูมิสูงสุดช่วงบ่าย'), findsOneWidget);
      // ป้ายของกล่องสรุป — ถ้าวาดเป็นข้อความธรรมดาจะไม่มีคำนี้
      expect(find.text('สรุป'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('บล็อกรายการแตกเป็นข้อ ๆ ไม่ใช่ข้อความก้อนเดียว', (
      tester,
    ) async {
      await _pump(
        tester,
        _blocks([
          {'type': 'bulletList', 'text': 'ข้อหนึ่ง\nข้อสอง\nข้อสาม'},
        ]),
      );

      expect(find.text('ข้อหนึ่ง'), findsOneWidget);
      expect(find.text('ข้อสอง'), findsOneWidget);
      expect(find.text('ข้อสาม'), findsOneWidget);
    });

    testWidgets('บล็อกไฟล์แสดงชื่อไฟล์จริงพร้อมปุ่มเปิด', (tester) async {
      await _pump(
        tester,
        _blocks([
          {'type': 'fileDownload', 'text': '', 'materialId': 'mat-file'},
        ]),
      );

      // ชื่อไฟล์โผล่สองที่ตามที่ควรเป็น: ในบล็อก และในหัวข้อ 'เอกสารและไฟล์'
      // ของหน้า — ปุ่ม 'เปิดไฟล์' เป็นของบล็อกอย่างเดียว
      expect(find.text('ใบงาน.pdf'), findsNWidgets(2));
      expect(find.text('เปิดไฟล์'), findsOneWidget);
    });

    testWidgets('บล็อกลิงก์แสดง URL พร้อมปุ่มเปิดลิงก์', (tester) async {
      await _pump(
        tester,
        _blocks([
          {
            'type': 'externalLink',
            'text': '',
            'mediaUrl': 'https://example.org/aiot',
            'caption': 'อ่านเพิ่มเติม',
          },
        ]),
      );

      expect(find.text('อ่านเพิ่มเติม'), findsOneWidget);
      expect(find.text('https://example.org/aiot'), findsOneWidget);
      expect(find.text('เปิดลิงก์'), findsOneWidget);
    });

    testWidgets('บล็อกสื่อที่ยังไม่ได้เลือกไฟล์ต้องบอก ไม่ใช่กรอบว่าง', (
      tester,
    ) async {
      await _pump(
        tester,
        _blocks([
          {'type': 'image', 'text': '', 'materialId': ''},
        ]),
      );

      expect(find.textContaining('ยังไม่ได้เลือกไฟล์'), findsOneWidget);
    });

    testWidgets('บล็อกสื่อที่ชี้ไปไฟล์ที่ถูกลบแล้วต้องบอก ไม่ใช่เงียบ', (
      tester,
    ) async {
      await _pump(
        tester,
        _blocks([
          {'type': 'fileDownload', 'text': '', 'materialId': 'ไฟล์ที่ถูกลบไป'},
        ]),
      );

      expect(find.textContaining('ยังไม่ได้เลือกไฟล์'), findsOneWidget);
    });

    testWidgets('บล็อกกราฟชี้ไปหัวข้อเซนเซอร์ ไม่วาดกราฟซ้ำ', (tester) async {
      await _pump(
        tester,
        _blocks([
          {'type': 'sensorChart', 'text': '', 'sensorMetric': 'temperature'},
        ]),
      );

      expect(find.textContaining('temperature'), findsOneWidget);
    });
  });

  group('บทเรียนรุ่นเก่าที่ยังไม่มีบล็อก', () {
    testWidgets('ตกกลับไปแสดง body ไม่ใช่จอว่าง', (tester) async {
      await _pump(tester, const {'body': 'เนื้อหาที่พิมพ์ไว้ตั้งแต่ปีที่แล้ว'});

      expect(find.text('เนื้อหาที่พิมพ์ไว้ตั้งแต่ปีที่แล้ว'), findsOneWidget);
    });

    testWidgets('ไม่มีทั้ง blocks และ body ต้องบอกว่าไม่มีเนื้อหา', (
      tester,
    ) async {
      await _pump(tester, null);

      expect(find.text('ไม่มีเนื้อหาข้อความในบทเรียนนี้'), findsOneWidget);
    });
  });

  group('ตัวแปลงข้อมูลที่สองเลนใช้ร่วมกัน', () {
    test('lessonBlocksFromContent ข้ามค่าที่พัง แทนที่จะโยน', () {
      final blocks = lessonBlocksFromContent(const {
        'blocks': [
          {'id': 'a', 'type': 'heading', 'text': 'หัวข้อ'},
          'ขยะที่ไม่ใช่ Map',
          {'type': 'ชนิดที่ไม่รู้จัก', 'text': 'ยังต้องอ่านได้'},
        ],
      });

      expect(blocks.length, 2);
      expect(blocks[0].type, ContentBlockType.heading);
      expect(blocks[1].type, ContentBlockType.text);
      expect(blocks[1].id, 'b-2');
    });

    test('lessonBodyFromBlocks ตัดหัวข้อและสื่อแนบออกจาก body', () {
      final body = lessonBodyFromBlocks([
        ContentBlockModel(
          id: 'a',
          type: ContentBlockType.heading,
          text: 'หัวข้อ',
        ),
        ContentBlockModel(
          id: 'b',
          type: ContentBlockType.text,
          text: 'เนื้อหา',
        ),
        ContentBlockModel(
          id: 'c',
          type: ContentBlockType.text,
          text: 'สื่อแนบ: ไฟล์.pdf',
        ),
      ]);

      expect(body, 'เนื้อหา');
    });

    test('เขียนแล้วอ่านกลับต้องได้บล็อกเดิม', () {
      final original = ContentBlockModel(
        id: 'x',
        type: ContentBlockType.summaryBox,
        text: 'สรุป',
        caption: 'คำบรรยาย',
        sensorMetric: 'pm25',
      );
      final restored = ContentBlockModel.fromJson(
        original.toJson(),
        fallbackId: 'ไม่ควรถูกใช้',
      );

      expect(restored.id, 'x');
      expect(restored.type, ContentBlockType.summaryBox);
      expect(restored.text, 'สรุป');
      expect(restored.caption, 'คำบรรยาย');
      expect(restored.sensorMetric, 'pm25');
    });

    test('materialId เดินทางไป-กลับผ่าน jsonb ได้', () {
      final blocks = lessonBlocksFromContent(const {
        'blocks': [
          {'id': 'a', 'type': 'image', 'materialId': 'mat-img'},
        ],
      });

      expect(blocks.single.materialId, 'mat-img');
      expect(blocks.single.toJson()['materialId'], 'mat-img');
    });
  });

  testWidgets('LessonBlockView เดี่ยว ๆ ไม่ล้นที่ความกว้างมือถือแคบสุด', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: LessonBlockView(
              blocks: [],
              fallbackBody:
                  'ข้อความยาวพอที่จะต้องตัดบรรทัดบนจอแคบที่สุด '
                  'ที่เรารองรับ คือ 360 จุดตามที่ probe ของเลนครูใช้',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
