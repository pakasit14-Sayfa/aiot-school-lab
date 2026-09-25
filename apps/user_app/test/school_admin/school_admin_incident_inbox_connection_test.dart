import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/controllers/school_admin_incident_inbox_controller.dart';
import 'package:my_first_app/pages/school_admin/school_admin_incident_inbox_page.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  testWidgets(
    'loads canonical incidents and shows the exact database empty copy',
    (tester) async {
      var backend = <TeacherIncidentReport>[];
      final controller = _controller(
        loadIncidents: () async => List<TeacherIncidentReport>.of(backend),
      );

      await _pumpPage(tester, controller);

      expect(find.text('ยังไม่มีข้อมูล'), findsOneWidget);
      expect(find.text('ยังไม่มีเหตุการณ์จากฐานข้อมูล'), findsOneWidget);

      backend = <TeacherIncidentReport>[_report()];
      await tester.tap(find.byTooltip('รีเฟรชข้อมูล'));
      await tester.pumpAndSettle();

      expect(find.textContaining('นักเรียนทดสอบ'), findsOneWidget);
      expect(find.text('ยังไม่มีข้อมูล'), findsNothing);
    },
  );

  testWidgets('filter empty state is distinct from an empty database', (
    tester,
  ) async {
    final controller = _controller();
    await _pumpPage(tester, controller);

    await tester.enterText(find.byType(TextField).first, 'ไม่พบคำนี้แน่นอน');
    await tester.pump();

    expect(find.text('ยังไม่มีข้อมูล'), findsOneWidget);
    expect(find.text('ไม่มีรายการที่ตรงกับตัวกรองหรือคำค้นหา'), findsOneWidget);
  });

  testWidgets('refresh failure keeps canonical data visible with retry', (
    tester,
  ) async {
    var failRefresh = false;
    final controller = _controller(
      loadIncidents: () async {
        if (failRefresh) throw StateError('backend details');
        return <TeacherIncidentReport>[_report()];
      },
    );
    await _pumpPage(tester, controller);

    failRefresh = true;
    await tester.tap(find.byTooltip('รีเฟรชข้อมูล'));
    await tester.pumpAndSettle();

    expect(find.text('โหลดรายการเหตุการณ์ไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('นักเรียนทดสอบ'), findsOneWidget);
    expect(find.textContaining('backend details'), findsNothing);

    failRefresh = false;
    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();

    expect(find.text('โหลดรายการเหตุการณ์ไม่สำเร็จ'), findsNothing);
    expect(find.textContaining('นักเรียนทดสอบ'), findsOneWidget);
  });

  testWidgets('acknowledge shows success only after canonical refetch', (
    tester,
  ) async {
    var backend = <TeacherIncidentReport>[_report()];
    final controller = _controller(
      loadIncidents: () async => List<TeacherIncidentReport>.of(backend),
      acknowledge: (id) async {
        backend = <TeacherIncidentReport>[_report(status: 'acknowledged')];
      },
    );
    await _pumpPage(tester, controller);

    await tester.tap(find.text('รับเรื่อง'));
    await tester.pumpAndSettle();

    expect(find.textContaining('เรียบร้อยแล้ว'), findsOneWidget);
    expect(find.text('เหตุใหม่ (0)'), findsOneWidget);
    expect(find.text('รับเรื่อง'), findsNothing);
  });

  testWidgets('failed close keeps dialog and note so the user can retry', (
    tester,
  ) async {
    var backend = <TeacherIncidentReport>[_report(status: 'acknowledged')];
    var allowClose = false;
    final controller = _controller(
      loadIncidents: () async => List<TeacherIncidentReport>.of(backend),
      close:
          ({
            required id,
            required resolutionType,
            required resolutionNote,
          }) async {
            if (allowClose) {
              backend = <TeacherIncidentReport>[_report(status: 'resolved')];
            }
          },
    );
    await _pumpPage(tester, controller);

    await tester.tap(find.text('ปิดเหตุการณ์'));
    await tester.pumpAndSettle();
    final noteField = find.byType(TextField).last;
    await tester.enterText(noteField, 'ตรวจสอบและแก้ไขแล้ว');
    await tester.tap(find.text('ยืนยันปิดเหตุการณ์'));
    await tester.pumpAndSettle();

    expect(find.text('ยืนยันปิดเหตุการณ์'), findsOneWidget);
    expect(find.text('ตรวจสอบและแก้ไขแล้ว'), findsOneWidget);
    // Two separate surfaces legitimately share this substring: the
    // controller's background error state and this dialog's own retry
    // SnackBar. Assert the exact dialog message so the finder isn't
    // ambiguous between them.
    expect(
      find.text('ปิดเหตุการณ์ไม่สำเร็จ กรุณาตรวจสอบแล้วลองใหม่'),
      findsOneWidget,
    );

    allowClose = true;
    await tester.tap(find.text('ยืนยันปิดเหตุการณ์'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('ยืนยันปิดเหตุการณ์'), findsNothing);
    expect(find.text('ปิดเหตุการณ์เรียบร้อยแล้ว'), findsOneWidget);
  });

  testWidgets('detail failure hides raw errors and retry loads staff detail', (
    tester,
  ) async {
    var failDetail = true;
    final controller = _controller(
      loadDetail: (id) async {
        if (failDetail) throw StateError('sensitive database text');
        return _detail(id: id);
      },
    );
    await _pumpPage(tester, controller);

    await tester.tap(find.text('ดูรายละเอียด'));
    await tester.pumpAndSettle();

    expect(find.text('โหลดรายละเอียดเหตุการณ์ไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('sensitive database text'), findsNothing);

    failDetail = false;
    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();

    expect(find.text('ประตูชำรุด'), findsOneWidget);
    expect(find.text('A-101'), findsOneWidget);
  });

  testWidgets(
    'severity shows its real Thai label, never the raw backend value',
    (tester) async {
      final controller = _controller(
        loadDetail: (id) async => _detail(id: id, severity: 'high'),
      );
      await _pumpPage(tester, controller);

      await tester.tap(find.text('ดูรายละเอียด'));
      await tester.pumpAndSettle();

      expect(find.text('เหตุใหญ่'), findsOneWidget);
      expect(find.text('high'), findsNothing);
    },
  );

  testWidgets(
    'unset severity is honestly minor, not a fabricated "ปกติ" assessment',
    (tester) async {
      final controller = _controller(
        loadDetail: (id) async => _detail(id: id, severity: null),
      );
      await _pumpPage(tester, controller);

      await tester.tap(find.text('ดูรายละเอียด'));
      await tester.pumpAndSettle();

      expect(find.text('เหตุเล็ก'), findsOneWidget);
      expect(find.text('ปกติ'), findsNothing);
    },
  );
}

Future<void> _pumpPage(
  WidgetTester tester,
  SchoolAdminIncidentInboxController controller,
) async {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    controller.dispose();
  });
  await tester.pumpWidget(
    MaterialApp(home: SchoolAdminIncidentInboxPage(controller: controller)),
  );
  await tester.pumpAndSettle();
}

SchoolAdminIncidentInboxController _controller({
  Future<List<TeacherIncidentReport>> Function()? loadIncidents,
  Future<IncidentReportDetail> Function(String id)? loadDetail,
  Future<void> Function(String id)? acknowledge,
  Future<void> Function({
    required String id,
    required String resolutionType,
    required String resolutionNote,
  })?
  close,
}) => SchoolAdminIncidentInboxController(
  loadIncidents:
      loadIncidents ?? () async => <TeacherIncidentReport>[_report()],
  loadDetail: loadDetail ?? (id) async => _detail(id: id),
  acknowledgeIncident: acknowledge ?? (id) async {},
  closeIncident:
      close ??
      ({
        required id,
        required resolutionType,
        required resolutionNote,
      }) async {},
);

TeacherIncidentReport _report({String status = 'new'}) => TeacherIncidentReport(
  id: 'incident-12345678',
  category: IncidentCategory.anomaly,
  room: 'A-101',
  status: status,
  reporterName: 'นักเรียนทดสอบ',
  createdAt: DateTime.utc(2030, 1, 1),
  reason: 'ประตูชำรุด',
  severity: 'medium',
);

IncidentReportDetail _detail({required String id, String? severity = 'medium'}) =>
    IncidentReportDetail(
      id: id,
      category: IncidentCategory.anomaly,
      room: 'A-101',
      status: 'new',
      resolutionType: null,
      resolutionNote: null,
      createdAt: DateTime.utc(2030, 1, 1),
      acknowledgedAt: null,
      closedAt: null,
      reason: 'ประตูชำรุด',
      severity: severity,
    );
