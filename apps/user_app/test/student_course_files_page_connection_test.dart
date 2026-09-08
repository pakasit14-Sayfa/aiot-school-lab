import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/student_redesign_prototype/widgets/student_course_files_page.dart';
import 'package:shared_core/shared_core.dart';

/// Opening a file resolves a real signed download URL - these tests pin
/// down the list load shows real course/file data and that
/// CourseFileCard (used standalone, public class) reaches the real
/// getDownloadUrl RPC with the real file id, for both the download path
/// and the image-preview path.

const _course = CourseSummary(
  id: 'course-1',
  subjectName: 'ฟิสิกส์',
  gradeLevel: 'ม.4',
  room: '201',
  status: 'active',
  termId: 'term-1',
);

final _pdfFile = CourseFile(
  id: 'file-1',
  storagePath: 'course-1/doc.pdf',
  fileName: 'เอกสารประกอบ.pdf',
  sizeBytes: 100000,
  uploadedBy: 'u-1',
  uploaderFirstName: 'ครู',
  uploaderLastName: 'สมศรี',
  createdAt: DateTime(2026, 9, 1),
);

final _imageFile = CourseFile(
  id: 'file-2',
  storagePath: 'course-1/photo.png',
  fileName: 'ภาพประกอบ.png',
  sizeBytes: 50000,
  uploadedBy: 'u-1',
  uploaderFirstName: 'ครู',
  uploaderLastName: 'สมศรี',
  createdAt: DateTime(2026, 9, 1),
);

void main() {
  testWidgets('a real course with a real file shows the real subject/file name, not fabricated content', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StudentCourseFilesPage(
          loadCourses: () async => const [_course],
          listFiles: (_) async => [_pdfFile],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ฟิสิกส์'), findsWidgets);
    expect(find.text('เอกสารประกอบ.pdf'), findsOneWidget);
  });

  testWidgets('a real load failure shows an honest error, no leaked exception text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StudentCourseFilesPage(
          loadCourses: () async =>
              throw StateError('backend detail that must stay internal'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('โหลดข้อมูลไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('backend detail'), findsNothing);
  });

  testWidgets('opening a non-image file resolves the real signed URL for the real file id', (
    tester,
  ) async {
    String? requestedId;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CourseFileCard(
            file: _pdfFile,
            getDownloadUrl: (fileId) async {
              requestedId = fileId;
              // A blank scheme launchUrl call would fail in the test
              // harness with no real browser; return a value and let the
              // launch failure be caught by the widget's own try/catch -
              // what matters here is that the real id reached the seam.
              return 'https://example.com/signed/file-1';
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(InkWell).first);
    // Not pumpAndSettle: launchUrl has no platform-channel implementation
    // in the test harness and its future never resolves, which would hang
    // pumpAndSettle forever. The real id already reached the seam by the
    // time the (never-completing) launch call is awaited.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(requestedId, 'file-1');
  });

  testWidgets('opening an image previews it via the real signed URL, not a fake path', (
    tester,
  ) async {
    String? requestedId;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CourseFileCard(
            file: _imageFile,
            getDownloadUrl: (fileId) async {
              requestedId = fileId;
              return 'https://example.com/signed/file-2.png';
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(InkWell).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(requestedId, 'file-2');
  });

  testWidgets('a failed download shows an honest message, no leaked exception text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CourseFileCard(
            file: _pdfFile,
            getDownloadUrl: (_) async =>
                throw StateError('backend detail that must stay internal'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    expect(find.textContaining('ดาวน์โหลดไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('backend detail'), findsNothing);
  });
}
