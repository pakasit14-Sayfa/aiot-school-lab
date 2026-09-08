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
  })?
  uploadFile,
  Future<String> Function(String fileId)? getDownloadUrl,
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
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a real load failure shows an honest error state, no fabricated demo courses', (
    tester,
  ) async {
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
  });

  testWidgets('a signed-out session shows the error state too, not a silent fake library', (
    tester,
  ) async {
    await _pump(tester, hasSessionOverride: false);
    expect(find.text('โหลดข้อมูลคลังความรู้ไม่สำเร็จ'), findsOneWidget);
  });

  testWidgets('real files load and show the real name/size, not fabricated content', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('เอกสารประกอบ.pdf'), findsOneWidget);
    expect(find.textContaining('200.0 KB'), findsOneWidget);
  });

  testWidgets('downloading a file resolves the real signed URL for its real id', (
    tester,
  ) async {
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
  });

  testWidgets('a failed download shows an honest message, no leaked exception text', (
    tester,
  ) async {
    await _pump(
      tester,
      getDownloadUrl: (_) async =>
          throw StateError('backend detail that must stay internal'),
    );

    await tester.tap(find.byIcon(Icons.download_rounded));
    await tester.pumpAndSettle();

    expect(find.text('ไม่สามารถดาวน์โหลดไฟล์ได้'), findsOneWidget);
    expect(find.textContaining('backend detail'), findsNothing);
  });
}
