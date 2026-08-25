import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:my_first_app/pages/school_admin/school_admin_dashboard_page.dart';
import 'package:my_first_app/pages/school_admin/school_admin_energy_page.dart';
import 'package:my_first_app/pages/school_admin/school_admin_cctv_page.dart';
import 'package:my_first_app/pages/school_admin/school_admin_device_schedule_page.dart';
import 'package:my_first_app/pages/school_admin/school_admin_device_control_page.dart';
import 'package:my_first_app/pages/school_admin/school_admin_incident_inbox_page.dart';
import 'package:my_first_app/pages/school_admin/school_admin_esg_page.dart';

const artifactDir = '/Users/sayfa/.gemini/antigravity-cli/brain/69d565a1-b35b-4c44-84a1-f18065de1cb2';

Future<void> _capture(WidgetTester tester, String filename) async {
  await tester.runAsync(() async {
    final boundary = tester.renderObject(find.byKey(const Key('capture_boundary'))) as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    File('$artifactDir/$filename').writeAsBytesSync(pngBytes);
    // Also copy to Downloads folder
    final dlDir = Directory('/Users/sayfa/Downloads/school_admin_screenshots');
    if (!dlDir.existsSync()) dlDir.createSync(recursive: true);
    File('/Users/sayfa/Downloads/$filename').writeAsBytesSync(pngBytes);
    File('/Users/sayfa/Downloads/school_admin_screenshots/$filename').writeAsBytesSync(pngBytes);
  });
}

Widget _wrap(Widget child, {Size size = const Size(1280, 1000)}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.purple,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    ),
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Center(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: RepaintBoundary(
            key: const Key('capture_boundary'),
            child: child,
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    currentUserModel = const UserModel(
      uid: 'admin-1',
      name: 'อาจารย์สมศักดิ์ ผู้ดูแลระบบ',
      email: 'admin@aiot-school-lab.local',
      role: UserRole.schoolAdmin,
      schoolId: 'df6fb123-6fde-4546-8bd9-cc16dcae2946',
    );
  });

  testWidgets('Capture School Admin Dashboard', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_wrap(
      const SchoolAdminDashboardPage(),
      size: const Size(1400, 1000),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await _capture(tester, 'school_admin_dashboard.png');
  });

  testWidgets('Capture School Admin Drawer Menu', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_wrap(
      const SchoolAdminDashboardPage(),
      size: const Size(390, 844),
    ));
    await tester.pump();

    tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
    await tester.pump(const Duration(milliseconds: 300));

    await _capture(tester, 'school_admin_menu.png');
  });

  testWidgets('Capture School Admin Energy Page', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    await tester.pumpWidget(_wrap(
      SchoolAdminEnergyPage(
        initialEnergySummary: const EnergyUsageSummary(
          deviceCount: 14,
          totalKwh: 4520.5,
          electricityRateThb: 4.50,
          isRateDefault: false,
          estimatedCostThb: 20342.25,
          disclaimer: 'คำนวณจากอัตราค่าไฟจริงของโรงเรียน',
        ),
        initialWaterSummary: const WaterUsageSummary(
          deviceCount: 8,
          totalM3: 340.2,
          waterRateThb: 18.00,
          isRateDefault: false,
          estimatedCostThb: 6123.60,
          disclaimer: 'คำนวณจากอัตราค่าน้ำประปาจริง',
        ),
        initialEnergyScore: const UtilityEfficiencyScore(
          score: 88.5,
          label: 'ดีเยี่ยม',
          current: 4520.5,
          previous: 5160.0,
        ),
        initialWaterScore: const UtilityEfficiencyScore(
          score: 79.0,
          label: 'ดี',
          current: 340.2,
          previous: 357.0,
        ),
        initialEnergyTrend: List.generate(
          7,
          (i) => UtilityTrendPoint(
            day: now.subtract(Duration(days: 6 - i)),
            value: 140.0 + (i * 8.5) % 35,
          ),
        ),
        initialWaterTrend: List.generate(
          7,
          (i) => UtilityTrendPoint(
            day: now.subtract(Duration(days: 6 - i)),
            value: 11.0 + (i * 2.1) % 6,
          ),
        ),
      ),
    ));
    await tester.pump();

    await _capture(tester, 'school_admin_energy.png');
  });

  testWidgets('Capture School Admin CCTV Page', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    await tester.pumpWidget(_wrap(
      SchoolAdminCctvPage(
        initialGrants: [
          CameraAccessGrantItem(
            grantId: 'g-1',
            cameraName: 'โถงกลาง อาคาร 1 (ทางเข้าหลัก)',
            location: 'ทางเข้าหลัก',
            building: 'อาคาร 1',
            room: '101',
            userId: 'u-1',
            userName: 'นายสมชาย ครูประจำชั้น ม.3/1',
            userEmail: 'somchai@school.local',
            userRole: 'teacher',
            reason: 'เฝ้าระวังความปลอดภัยและกิจกรรมการเรียนการสอนประจำวัน',
            validFrom: now.subtract(const Duration(days: 1)),
            validUntil: now.add(const Duration(days: 6)),
            grantedAt: now.subtract(const Duration(days: 1)),
            grantedByName: 'อาจารย์สมศักดิ์ ผู้ดูแลระบบ',
            isActive: true,
          ),
          CameraAccessGrantItem(
            grantId: 'g-2',
            cameraName: 'ทางเดินชั้น 2 อาคารวิทยาศาสตร์',
            location: 'หน้าห้อง Lab 202',
            building: 'อาคาร 2',
            room: '202',
            userId: 'u-2',
            userName: 'นางสาวพิมพ์ใจ หัวหน้าฝ่ายอาคารสถานที่',
            userEmail: 'pimjai@school.local',
            userRole: 'school_admin',
            reason: 'ตรวจสอบความปลอดภัยระบบห้องปฏิบัติการวิทยาศาสตร์',
            validFrom: now.subtract(const Duration(days: 3)),
            validUntil: now.add(const Duration(days: 11)),
            grantedAt: now.subtract(const Duration(days: 3)),
            grantedByName: 'อาจารย์สมศักดิ์ ผู้ดูแลระบบ',
            isActive: true,
          ),
          CameraAccessGrantItem(
            grantId: 'g-3',
            cameraName: 'ประตูรั้วด้านหลังโรงเรียน',
            location: 'ประตู 3',
            building: 'ภายนอกอาคาร',
            room: 'ป้อมยาม 2',
            userId: 'u-3',
            userName: 'นายสุรชัย เจ้าหน้าที่ติดตั้งภายนอก (Contractor)',
            userEmail: 'surachai.tech@vendor.local',
            userRole: 'staff',
            reason: 'ซ่อมบำรุงสายเคเบิลกล้องวงจรปิด',
            validFrom: now.subtract(const Duration(days: 10)),
            validUntil: now.add(const Duration(days: 4)),
            grantedAt: now.subtract(const Duration(days: 10)),
            grantedByName: 'อาจารย์สมศักดิ์ ผู้ดูแลระบบ',
            isActive: false, // เพิกถอนสิทธิ์แล้ว
          ),
        ],
      ),
    ));
    await tester.pump();

    await _capture(tester, 'school_admin_cctv.png');
  });

  testWidgets('Capture School Admin Device Schedule Page', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    await tester.pumpWidget(_wrap(
      SchoolAdminDeviceSchedulePage(
        initialSchedules: [
          DeviceSchedule(
            id: 'sch-1',
            schoolId: 'df6fb123-6fde-4546-8bd9-cc16dcae2946',
            deviceId: 'dev-1',
            deviceName: 'ไฟส่องสว่างสนามหน้าเสาธง',
            deviceLocation: 'ลานกิจกรรมกลางแจ้ง',
            label: 'เปิดไฟส่องสว่างเช้า (จันทร์-ศุกร์ 06:00)',
            command: const {'action': 'turn_on'},
            daysOfWeek: const [1, 2, 3, 4, 5],
            timeOfDay: '06:00',
            enabled: true,
            createdBy: 'admin-1',
            createdAt: now.subtract(const Duration(days: 5)),
          ),
          DeviceSchedule(
            id: 'sch-2',
            schoolId: 'df6fb123-6fde-4546-8bd9-cc16dcae2946',
            deviceId: 'dev-1',
            deviceName: 'ไฟส่องสว่างสนามหน้าเสาธง',
            deviceLocation: 'ลานกิจกรรมกลางแจ้ง',
            label: 'ปิดไฟส่องสว่างเย็น (จันทร์-ศุกร์ 18:00)',
            command: const {'action': 'turn_off'},
            daysOfWeek: const [1, 2, 3, 4, 5],
            timeOfDay: '18:00',
            enabled: true,
            createdBy: 'admin-1',
            createdAt: now.subtract(const Duration(days: 5)),
          ),
          DeviceSchedule(
            id: 'sch-3',
            schoolId: 'df6fb123-6fde-4546-8bd9-cc16dcae2946',
            deviceId: 'dev-2',
            deviceName: 'ปั๊มน้ำรดน้ำสวนหย่อมและแปลงเกษตร',
            deviceLocation: 'สวนเกษตรพอเพียง',
            label: 'รดน้ำต้นไม้อัตโนมัติ (ทุกวัน 06:30)',
            command: const {'action': 'turn_on'},
            daysOfWeek: const [0, 1, 2, 3, 4, 5, 6],
            timeOfDay: '06:30',
            enabled: true,
            createdBy: 'admin-1',
            createdAt: now.subtract(const Duration(days: 3)),
          ),
        ],
      ),
    ));
    await tester.pump();

    await _capture(tester, 'school_admin_schedule.png');
  });

  testWidgets('Capture School Admin Device Control Page', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_wrap(
      const SchoolAdminDeviceControlPage(
        initialRelays: [
          DeviceOption(
            id: 'dev-1',
            name: 'ไฟส่องสว่างทางเดิน ชั้น 1',
            type: 'relay',
            location: 'อาคาร 1 โถงกลาง',
            status: 'online',
          ),
          DeviceOption(
            id: 'dev-2',
            name: 'ไฟส่องสว่างทางเดิน ชั้น 2',
            type: 'relay',
            location: 'อาคาร 1 โถงกลาง',
            status: 'online',
          ),
          DeviceOption(
            id: 'dev-3',
            name: 'ปั๊มน้ำระบบสปริงเกลอร์สนามหญ้า',
            type: 'relay',
            location: 'สนามกีฬา สนามกลางแจ้ง',
            status: 'online',
          ),
          DeviceOption(
            id: 'dev-4',
            name: 'ไฟสปอร์ตไลท์สนามฟุตบอล',
            type: 'relay',
            location: 'สนามกีฬา สนามฟุตบอล',
            status: 'offline',
          ),
        ],
      ),
    ));
    await tester.pump();

    await _capture(tester, 'school_admin_device_control.png');
  });

  testWidgets('Capture School Admin Incident Inbox Page', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    await tester.pumpWidget(_wrap(
      SchoolAdminIncidentInboxPage(
        initialIncidents: [
          TeacherIncidentReport(
            id: 'inc-1',
            category: IncidentCategory.anomaly,
            room: 'อาคาร 2 ห้อง 204',
            status: 'reported',
            reporterName: 'ครูสมชาย สมใจ',
            createdAt: now.subtract(const Duration(hours: 2)),
            reason: 'หลอดไฟ LED ทางเดินหน้าห้อง 204 กะพริบต่อเนื่อง ขอให้ตรวจสอบและเปลี่ยนหลอดใหม่',
            severity: 'medium',
          ),
          TeacherIncidentReport(
            id: 'inc-2',
            category: IncidentCategory.sos,
            room: 'อาคาร 1 ห้องน้ำชาย ชั้น 1',
            status: 'in_progress',
            reporterName: 'ครูพรพิมล รัตนศิลป์',
            createdAt: now.subtract(const Duration(hours: 5)),
            acknowledgedAt: now.subtract(const Duration(hours: 4)),
            reason: 'ก๊อกน้ำรั่วซึม มีน้ำหยดตลอดเวลาจากท่อใต้อ่างล้างมือ เกรงว่าจะสิ้นเปลืองน้ำประปา',
            severity: 'high',
          ),
          TeacherIncidentReport(
            id: 'inc-3',
            category: IncidentCategory.anomaly,
            room: 'อาคาร 3 ห้อง 302',
            status: 'resolved',
            reporterName: 'อาจารย์สมศักดิ์ ผู้ดูแลระบบ',
            createdAt: now.subtract(const Duration(days: 1)),
            acknowledgedAt: now.subtract(const Duration(hours: 20)),
            reason: 'ปลั๊กไฟห้องทดลองวิทยาศาสตร์ไม่ทำงาน ช่างเข้ามาแก้ไขระบบเบรกเกอร์เรียบร้อยแล้ว',
            severity: 'low',
          ),
        ],
      ),
    ));
    await tester.pump();

    await _capture(tester, 'school_admin_incidents.png');
  });

  testWidgets('Capture School Admin ESG Page', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_wrap(
      const SchoolAdminEsgPage(
        initialEnergyScore: UtilityEfficiencyScore(
          score: 88.5,
          label: 'ดีเยี่ยม',
          current: 4520.5,
          previous: 5160.0,
        ),
        initialWaterScore: UtilityEfficiencyScore(
          score: 79.0,
          label: 'ดี',
          current: 340.2,
          previous: 357.0,
        ),
        initialEnergySummary: EnergyUsageSummary(
          deviceCount: 14,
          totalKwh: 4520.5,
          electricityRateThb: 4.50,
          isRateDefault: false,
          estimatedCostThb: 20342.25,
          disclaimer: 'คำนวณจากอัตราค่าไฟจริง',
        ),
        initialWaterSummary: WaterUsageSummary(
          deviceCount: 8,
          totalM3: 340.2,
          waterRateThb: 18.00,
          isRateDefault: false,
          estimatedCostThb: 6123.60,
          disclaimer: 'คำนวณจากอัตราค่าน้ำประปาจริง',
        ),
      ),
    ));
    await tester.pump();

    await _capture(tester, 'school_admin_esg.png');
  });
}
