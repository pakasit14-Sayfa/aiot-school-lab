import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_knowledge_library_page.dart';
import 'package:shared_core/shared_core.dart';

/// _loadFallbackMock() used to swap any real load failure (session
/// expired, RPC down) for two fully fabricated demo courses with no error
/// indicator at all - a teacher had no way to tell the library was broken
/// vs genuinely stocked. These tests pin down that a real failure shows a
/// real error state, and that upload/download reach the real service.

const _course = CourseSummary(
  id: 'course-1',
  subjectName: 'ฟิสิกส์',
  gradeLevel: 'ม.4',
  room: '201',
  status: 'active',
  termId: 'term-1',
);

final _file = CourseFile(
  id: 'file-1',
  storagePath: 'course-1/doc.pdf',
  fileName: 'เอกสารประกอบ.pdf',
  sizeBytes: 204800,
  uploadedBy: 'u-1',
  uploaderFirstName: 'ครู',
  uploaderLastName: 'สมศรี',
  createdAt: DateTime(2026, 9, 1),
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<CourseSummary>> Function()? loadCourses,
  Future<List<CourseFile>> Function(String courseId)? listFiles,
  Future<void> Function({
    required String courseId,
    required String fileName,
    required Uint8List bytes,
    String? category,
  })?
  uploadFile,
  Future<String> Function(String fileId)? getDownloadUrl,
  Future<String> Function({
    required String courseId,
    required String url,
    String? title,
    String? category,
  })?
  addLink,
  Future<void> Function({
    required String fileId,
    String? fileName,
    String? category,
    String? url,
  })?
  updateFile,
  Future<void> Function(String fileId)? deleteFile,
  bool hasSessionOverride = true,
}) async {
  tester.view.physicalSize = const Size(1400, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: TeacherKnowledgeLibraryPage(
        hasSessionOverride: hasSessionOverride,
        loadCourses: loadCourses ?? () async => const [_course],
        listFiles: listFiles ?? (_) async => [_file],
        uploadFile: uploadFile,
        getDownloadUrl: getDownloadUrl,
        addLink: addLink,
        updateFile: updateFile,
        deleteFile: deleteFile,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  _libraryV2();

  testWidgets(
    'a real load failure shows an honest error state, no fabricated demo courses',
    (tester) async {
      await _pump(
        tester,
        loadCourses: () async =>
            throw StateError('backend detail that must stay internal'),
      );

      expect(find.text('โหลดข้อมูลคลังความรู้ไม่สำเร็จ'), findsOneWidget);
      expect(find.textContaining('backend detail'), findsNothing);
      // The old fake fallback subjects must never appear.
      expect(find.textContaining('AIoT สมาร์ตแล็บ'), findsNothing);
      expect(find.textContaining('ฟิสิกส์ประยุกต์'), findsNothing);
    },
  );

  testWidgets(
    'a signed-out session shows the error state too, not a silent fake library',
    (tester) async {
      await _pump(tester, hasSessionOverride: false);
      expect(find.text('โหลดข้อมูลคลังความรู้ไม่สำเร็จ'), findsOneWidget);
    },
  );

  testWidgets(
    'real files load and show the real name/size, not fabricated content',
    (tester) async {
      await _pump(tester);
      expect(find.text('เอกสารประกอบ.pdf'), findsOneWidget);
      expect(find.textContaining('200.0 KB'), findsOneWidget);
    },
  );

  /// list_course_files ของวิชาหนึ่งล้ม เคยถูกกลืนเงียบแล้วโชว์ "ยังไม่มีไฟล์
  /// ในวิชานี้" — ครูอ่านว่าวิชาว่างทั้งที่โหลดไม่ขึ้น
  testWidgets(
    'a failed per-subject file load is distinct from an empty subject',
    (tester) async {
      await _pump(
        tester,
        listFiles: (_) async =>
            throw Exception('PostgrestException: files_boom'),
      );
      expect(find.text('โหลดไฟล์ของวิชานี้ไม่สำเร็จ'), findsOneWidget);
      expect(find.text('ยังไม่มีไฟล์ในวิชานี้'), findsNothing);
      expect(find.textContaining('files_boom'), findsNothing);
    },
  );

  testWidgets(
    'downloading a file resolves the real signed URL for its real id',
    (tester) async {
      String? requestedId;
      await _pump(
        tester,
        getDownloadUrl: (fileId) async {
          requestedId = fileId;
          return 'https://example.com/signed';
        },
      );

      await tester.tap(find.byIcon(Icons.download_rounded));
      await tester.pumpAndSettle();

      expect(requestedId, 'file-1');
    },
  );

  testWidgets(
    'a failed download shows an honest message, no leaked exception text',
    (tester) async {
      await _pump(
        tester,
        getDownloadUrl: (_) async =>
            throw StateError('backend detail that must stay internal'),
      );

      await tester.tap(find.byIcon(Icons.download_rounded));
      await tester.pumpAndSettle();

      expect(find.text('ไม่สามารถดาวน์โหลดไฟล์ได้'), findsOneWidget);
      expect(find.textContaining('backend detail'), findsNothing);
    },
  );
}

/// คลังรับลิงก์ · แสดงหมวดจริง · บอกว่าถูกใช้กี่ใบงาน · แก้/ลบได้ (2026-09-23)
///
/// ก่อนหน้านี้คลังมีแต่ register/list/download — ลบอะไรไม่ได้เลยทั้งระบบ และ
/// หมวดที่ครูกรอกในชีตอัปโหลดถูกทิ้งทุกครั้ง หน้าจอ hardcode ว่า
/// 'เอกสารประกอบการเรียน' ทุกไฟล์
void _libraryV2() {
  CourseFile link({int usedBy = 0}) => CourseFile(
    id: 'link-1',
    kind: CourseFileKind.link,
    fileName: 'วิดีโอสาธิต',
    url: 'https://example.org/clip',
    category: 'บทที่ 1',
    uploadedBy: 'u-1',
    uploaderFirstName: 'ครู',
    uploaderLastName: 'สมศรี',
    createdAt: DateTime(2026, 9, 2),
    usedByAssignments: usedBy,
  );

  CourseFile pdf({String? category, int usedBy = 0}) => CourseFile(
    id: 'file-1',
    storagePath: 'course-1/doc.pdf',
    fileName: 'เอกสารประกอบ.pdf',
    sizeBytes: 204800,
    category: category,
    uploadedBy: 'u-1',
    uploaderFirstName: 'ครู',
    uploaderLastName: 'สมศรี',
    createdAt: DateTime(2026, 9, 1),
    usedByAssignments: usedBy,
  );

  testWidgets('หมวดที่ครูกรอกต้องถูกแสดง ไม่ใช่ข้อความตายตัวทุกไฟล์', (
    tester,
  ) async {
    await _pump(tester, listFiles: (_) async => [pdf(category: 'บทที่ 3')]);
    await tester.pumpAndSettle();
    expect(find.textContaining('บทที่ 3'), findsWidgets);
    expect(find.textContaining('เอกสารประกอบการเรียน'), findsNothing);
  });

  testWidgets('ไฟล์ที่ไม่มีหมวด ต้องบอกว่ายังไม่ระบุ ไม่ใช่เดาให้', (
    tester,
  ) async {
    await _pump(tester, listFiles: (_) async => [pdf()]);
    await tester.pumpAndSettle();
    expect(find.textContaining('ยังไม่ระบุหมวด'), findsWidgets);
  });

  testWidgets('ลิงก์แสดงเป็นลิงก์ พร้อมชื่อโฮสต์', (tester) async {
    await _pump(tester, listFiles: (_) async => [link()]);
    await tester.pumpAndSettle();
    expect(find.text('วิดีโอสาธิต'), findsOneWidget);
    expect(find.textContaining('example.org'), findsWidgets);
  });

  testWidgets('ของที่ใบงานใช้อยู่ ต้องติดป้ายบอกจำนวนก่อนครูกดลบ', (
    tester,
  ) async {
    await _pump(tester, listFiles: (_) async => [pdf(usedBy: 2)]);
    await tester.pumpAndSettle();
    expect(find.text('2 ใบงาน'), findsOneWidget);
  });

  testWidgets('เพิ่มลิงก์เข้าคลังเรียกหลังบ้านจริงด้วยวิชาที่เลือกอยู่', (
    tester,
  ) async {
    String? gotCourse;
    String? gotUrl;
    String? gotCategory;
    await _pump(
      tester,
      listFiles: (_) async => [],
      addLink: ({required courseId, required url, title, category}) async {
        gotCourse = courseId;
        gotUrl = url;
        gotCategory = category;
        return 'link-new';
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ใส่ลิงก์'));
    await tester.pumpAndSettle();

    // ลิงก์ผิดรูปต้องไม่ผ่านตั้งแต่หน้าจอ
    await tester.enterText(find.byType(TextField).first, 'ไม่ใช่ลิงก์');
    await tester.tap(find.text('เพิ่ม'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ต้องขึ้นต้นด้วย'), findsOneWidget);
    expect(gotUrl, isNull);

    await tester.enterText(
      find.byType(TextField).first,
      'https://example.org/v',
    );
    await tester.enterText(find.byType(TextField).at(2), 'บทที่ 2');
    await tester.tap(find.text('เพิ่ม'));
    await tester.pumpAndSettle();

    expect(gotCourse, 'course-1');
    expect(gotUrl, 'https://example.org/v');
    expect(gotCategory, 'บทที่ 2');
  });

  testWidgets('ลบของที่ใบงานยังใช้อยู่ ต้องบอกทางออก ไม่ใช่ error ดิบ', (
    tester,
  ) async {
    await _pump(
      tester,
      listFiles: (_) async => [pdf(usedBy: 3)],
      deleteFile: (_) async =>
          throw StateError('file_in_use_by_3 assignments'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();

    // ปุ่มลบต้องปิดไว้ตั้งแต่ต้น พร้อมบอกเหตุผล
    expect(find.textContaining('ใช้อยู่ใน 3 ใบงาน'), findsOneWidget);
  });

  testWidgets('เปลี่ยนหมวดส่งค่าไปหลังบ้านแล้วโหลดใหม่ ไม่ใช่แก้ในเครื่อง', (
    tester,
  ) async {
    String? sentCategory;
    var reads = 0;
    await _pump(
      tester,
      listFiles: (_) async {
        reads++;
        return [pdf(category: sentCategory)];
      },
      updateFile: ({required fileId, fileName, category, url}) async {
        sentCategory = category;
      },
    );
    await tester.pumpAndSettle();
    final readsBefore = reads;

    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('เปลี่ยนหมวด'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'บทที่ 9');
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();

    expect(sentCategory, 'บทที่ 9');
    // ต้องอ่านกลับจากหลังบ้าน ไม่ใช่เชื่อค่าที่พิมพ์
    expect(reads, greaterThan(readsBefore));
    expect(find.textContaining('บทที่ 9'), findsWidgets);
  });
}
