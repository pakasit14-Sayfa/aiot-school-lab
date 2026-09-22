import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/school_admin_report_requirements_page.dart';
import 'package:shared_core/shared_core.dart';

/// Pins loading / data / empty / error apart for the requirement register,
/// and guards the write→confirm contract on create/close — the real "3/6"
/// tracking on the reports page has nothing to count against until at
/// least one of these exists for real, not just a fake success snackbar.

ReportRequirement _requirement({
  String id = 'req-1',
  String title = 'รายงานประจำเดือน',
  bool overdue = false,
  int expected = 2,
  int filed = 0,
}) => ReportRequirement(
  requirementId: id,
  title: title,
  reportType: 'monthly',
  expectedCount: expected,
  filedCount: filed,
  isOverdue: overdue,
  missingDepartments: const [],
);

SchoolDepartment _department({
  String id = 'dept-1',
  String name = 'ฝ่ายวิชาการ',
}) => SchoolDepartment(
  departmentId: id,
  name: name,
  kind: 'administrative',
  sortOrder: 1,
  memberCount: 3,
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<ReportRequirement>> Function({bool onlyOpen})? loadRequirements,
  Future<List<SchoolDepartment>> Function()? loadDepartments,
  Future<String> Function({
    required String title,
    required String reportType,
    required List<String> departmentIds,
    DateTime? dueDate,
    String? description,
  })?
  createRequirement,
  Future<void> Function(String requirementId)? closeRequirement,
}) async {
  tester.view.physicalSize = const Size(1400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SchoolAdminReportRequirementsPage(
        loadRequirements:
            loadRequirements ??
            ({onlyOpen = false}) async => <ReportRequirement>[],
        loadDepartments:
            loadDepartments ?? () async => <SchoolDepartment>[_department()],
        createRequirement: createRequirement,
        closeRequirement: closeRequirement,
      ),
    ),
  );
}

void main() {
  testWidgets('real requirements are rendered', (tester) async {
    await _pump(
      tester,
      loadRequirements: ({onlyOpen = false}) async => [_requirement()],
    );
    await tester.pumpAndSettle();

    expect(find.text('รายงานประจำเดือน'), findsOneWidget);
  });

  testWidgets('no requirements says so, not an error', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีรายการรายงานที่ต้องส่ง'), findsOneWidget);
  });

  testWidgets('a failed load is distinct from empty, with retry', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      loadRequirements: ({onlyOpen = false}) async {
        calls++;
        throw StateError('backend detail that must stay internal');
      },
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('โหลดข้อมูลไม่สำเร็จ'), findsOneWidget);
    expect(calls, 1);
  });

  testWidgets('an overdue requirement is flagged distinctly', (tester) async {
    await _pump(
      tester,
      loadRequirements: ({onlyOpen = false}) async => [
        _requirement(overdue: true),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('เกินกำหนด'), findsOneWidget);
  });

  testWidgets('creating is blocked with a message when no departments exist', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      loadDepartments: () async => <SchoolDepartment>[],
      createRequirement:
          ({
            required title,
            required reportType,
            required departmentIds,
            dueDate,
            description,
          }) async {
            calls++;
            return 'unused';
          },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('สร้างรายการ'));
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีฝ่ายในระบบให้กำหนดผู้รับผิดชอบ'), findsOneWidget);
    expect(calls, 0);
    // The create dialog must never even open for this case.
    expect(find.text('สร้างรายการรายงานที่ต้องส่ง'), findsNothing);
  });

  testWidgets('creating requires at least one department to be selected', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      createRequirement:
          ({
            required title,
            required reportType,
            required departmentIds,
            dueDate,
            description,
          }) async {
            calls++;
            return 'unused';
          },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('สร้างรายการ'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'ชื่อรายงานที่ต้องส่ง'),
      'รายงานทดสอบ',
    );
    await tester.tap(find.text('สร้าง'));
    await tester.pumpAndSettle();

    expect(find.text('กรุณาเลือกอย่างน้อย 1 ฝ่าย'), findsOneWidget);
    expect(calls, 0);
  });

  testWidgets(
    'creating a real requirement calls the seam and reloads the list',
    (tester) async {
      var created = false;
      List<String>? capturedDeptIds;
      await _pump(
        tester,
        loadRequirements: ({onlyOpen = false}) async =>
            created ? [_requirement(title: 'รายงานทดสอบ')] : [],
        createRequirement:
            ({
              required title,
              required reportType,
              required departmentIds,
              dueDate,
              description,
            }) async {
              created = true;
              capturedDeptIds = departmentIds;
              return 'new-id';
            },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('สร้างรายการ'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'ชื่อรายงานที่ต้องส่ง'),
        'รายงานทดสอบ',
      );
      await tester.tap(find.text('ฝ่ายวิชาการ'));
      await tester.tap(find.text('สร้าง'));
      await tester.pumpAndSettle();

      expect(capturedDeptIds, ['dept-1']);
      expect(find.text('สร้างรายการรายงานที่ต้องส่งแล้ว'), findsOneWidget);
      expect(find.text('รายงานทดสอบ'), findsOneWidget);
    },
  );

  testWidgets('a failed create shows an error, not a false success', (
    tester,
  ) async {
    await _pump(
      tester,
      createRequirement:
          ({
            required title,
            required reportType,
            required departmentIds,
            dueDate,
            description,
          }) async => throw StateError('rpc rejected'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('สร้างรายการ'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'ชื่อรายงานที่ต้องส่ง'),
      'รายงานทดสอบ',
    );
    await tester.tap(find.text('ฝ่ายวิชาการ'));
    await tester.tap(find.text('สร้าง'));
    await tester.pumpAndSettle();

    expect(find.text('สร้างรายการไม่สำเร็จ กรุณาลองใหม่'), findsOneWidget);
    expect(find.text('สร้างรายการรายงานที่ต้องส่งแล้ว'), findsNothing);
  });

  testWidgets('closing only reports success once the seam actually resolves', (
    tester,
  ) async {
    await _pump(
      tester,
      loadRequirements: ({onlyOpen = false}) async => [_requirement()],
      closeRequirement: (id) async {
        throw StateError('rpc rejected');
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ปิดรายการ'));
    await tester.pumpAndSettle();

    expect(find.text('ปิดรายการไม่สำเร็จ กรุณาลองใหม่'), findsOneWidget);
  });

  testWidgets('closing succeeds and reloads when the seam resolves', (
    tester,
  ) async {
    var closed = false;
    await _pump(
      tester,
      loadRequirements: ({onlyOpen = false}) async =>
          closed ? [] : [_requirement()],
      closeRequirement: (id) async {
        closed = true;
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ปิดรายการ'));
    await tester.pumpAndSettle();

    expect(find.text('ปิดรายการแล้ว'), findsOneWidget);
    expect(find.text('ยังไม่มีรายการรายงานที่ต้องส่ง'), findsOneWidget);
  });
}
