import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_cctv_page.dart';
import 'package:shared_core/models/school_device_identity.dart';
import 'package:shared_core/shared_core.dart';

const _onlineCamera = DeviceOption(
  id: 'cam-1',
  name: 'ทางเข้าอาคาร 1',
  type: 'camera',
  location: 'อาคาร 1',
  status: 'online',
);

const _offlineCamera = DeviceOption(
  id: 'cam-2',
  name: 'โถงอาคาร 3',
  type: 'camera',
  location: 'อาคาร 3',
  status: 'offline',
);

// A real location string from the seeded camera — the old const filter list
// ('อาคาร 1', 'อาคาร 2', ...) could never equal it.
const _realLocationCamera = DeviceOption(
  id: 'cam-3',
  name: 'กล้อง CCTV ทางเข้าหลัก',
  type: 'camera',
  location: 'อาคาร 3 (วิทยาศาสตร์) · ทางเข้าหลัก',
  status: 'online',
);

const _nonCameraDevice = DeviceOption(
  id: 'dev-1',
  name: 'เซนเซอร์ PM2.5',
  type: 'pm25_sensor',
  location: 'อาคาร 1',
  status: 'online',
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<DeviceOption>> Function()? listSchoolDevices,
  Future<SchoolDeviceDetail?> Function(String)? loadDeviceDetail,
}) async {
  tester.view.physicalSize = const Size(1400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DirectorCctvPage(
          listSchoolDevices: listSchoolDevices,
          loadDeviceDetail: loadDeviceDetail,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'real camera devices show the real name/location/status, not fabricated tiles',
    (tester) async {
      await _pump(
        tester,
        listSchoolDevices: () async => const [_onlineCamera, _offlineCamera],
      );
      expect(find.text('ทางเข้าอาคาร 1'), findsOneWidget);
      expect(find.text('โถงอาคาร 3'), findsOneWidget);
      // Neither of the old hardcoded IDs should ever appear.
      expect(find.textContaining('CAM-B1-01'), findsNothing);
      expect(find.textContaining('CAM-GATE-01'), findsNothing);
    },
  );

  testWidgets('a non-camera device is excluded from the camera inventory', (
    tester,
  ) async {
    await _pump(
      tester,
      listSchoolDevices: () async => const [_onlineCamera, _nonCameraDevice],
    );
    expect(find.text('ทางเข้าอาคาร 1'), findsOneWidget);
    expect(find.text('เซนเซอร์ PM2.5'), findsNothing);
  });

  testWidgets(
    'zero real cameras shows an honest empty state, not fabricated tiles',
    (tester) async {
      await _pump(tester, listSchoolDevices: () async => const []);
      expect(find.text('พบ 0 กล้อง'), findsOneWidget);
    },
  );

  testWidgets(
    'no AI / recording / storage claims are made — there is no backend for any of them',
    (tester) async {
      await _pump(tester, listSchoolDevices: () async => const [_onlineCamera]);
      // The old "แจ้งเตือนจาก AI Camera" / "พื้นที่จัดเก็บ & AI Detection"
      // cards, the "AI ปิด" / "ไม่บันทึก" tags and the "LIVE" badge asserted a
      // state nothing records. None may come back.
      for (final claim in [
        'แจ้งเตือนจาก AI Camera',
        'พื้นที่จัดเก็บ & AI Detection',
        'AI ปิด',
        'AI เปิด',
        'ไม่บันทึก',
        'REC',
        'LIVE',
        'ไม่มีข้อมูลเวลาล่าสุด',
      ]) {
        expect(find.text(claim), findsNothing, reason: claim);
      }
      expect(find.textContaining('ตรวจพบพฤติกรรมเสี่ยง'), findsNothing);
    },
  );

  testWidgets(
    'the hero summary uses real online/offline counts, not the old fake 24/22/2',
    (tester) async {
      await _pump(
        tester,
        listSchoolDevices: () async => const [_onlineCamera, _offlineCamera],
      );
      // วงแหวนสรุปกลางการ์ด: online/total จริง
      expect(find.text('1/2'), findsOneWidget);
      // มีกล้อง Offline แค่ตัวเดียว - พาดหัวเอ่ยชื่อกล้องนั้นตรงๆ แทนจำนวน
      expect(
        find.text('2 กล้องทั้งหมด · โถงอาคาร 3 กำลัง Offline'),
        findsOneWidget,
      );
      expect(find.text('ควรตรวจสอบ — 1 กล้อง Offline'), findsOneWidget);
    },
  );

  testWidgets(
    'the building filter offers the real locations and keeps the matching camera',
    (tester) async {
      await _pump(
        tester,
        listSchoolDevices: () async => const [
          _realLocationCamera,
          _onlineCamera,
        ],
      );
      expect(find.text('กล้อง CCTV ทางเข้าหลัก'), findsOneWidget);

      // Open the building dropdown: every option must be a real location.
      await tester.tap(find.text('ทุกอาคาร'));
      await tester.pumpAndSettle();
      expect(find.text('อาคาร 3 (วิทยาศาสตร์) · ทางเข้าหลัก'), findsWidgets);
      expect(find.text('สนามกีฬา'), findsNothing);
      expect(find.text('ทางเข้าโรงเรียน'), findsNothing);

      await tester.tap(find.text('อาคาร 3 (วิทยาศาสตร์) · ทางเข้าหลัก').last);
      await tester.pumpAndSettle();

      // The chosen building still shows its camera — the old const list
      // filtered every real camera out.
      expect(find.text('กล้อง CCTV ทางเข้าหลัก'), findsOneWidget);
      expect(find.text('ทางเข้าอาคาร 1'), findsNothing);
      expect(find.text('พบ 1 กล้อง'), findsOneWidget);
    },
  );

  testWidgets('a failed camera load is an error with retry, not "no cameras"', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      listSchoolDevices: () async {
        calls++;
        if (calls == 1) throw StateError('backend-secret');
        return const [_onlineCamera];
      },
    );
    expect(find.text('ยังไม่มีกล้องในระบบนี้'), findsNothing);
    expect(find.text('โหลดรายชื่อกล้องไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('backend-secret'), findsNothing);

    await tester.tap(find.text('ลองใหม่').first);
    await tester.pumpAndSettle();
    expect(calls, 2, reason: 'retry must re-issue the load');
    expect(find.text('ทางเข้าอาคาร 1'), findsOneWidget);
    expect(find.text('โหลดรายชื่อกล้องไม่สำเร็จ'), findsNothing);
  });

  testWidgets(
    'the camera detail has no inert record/playback/fullscreen buttons',
    (tester) async {
      await _pump(tester, listSchoolDevices: () async => const [_onlineCamera]);
      await tester.tap(find.text('ทางเข้าอาคาร 1'));
      await tester.pumpAndSettle();
      expect(find.text('บันทึกภาพ'), findsNothing);
      expect(find.text('Playback'), findsNothing);
      expect(find.text('เต็มจอ'), findsNothing);
    },
  );

  testWidgets(
    'the camera detail shows the real heartbeat, and "never reported" when null',
    (tester) async {
      await _pump(
        tester,
        listSchoolDevices: () async => const [_onlineCamera],
        loadDeviceDetail: (id) async => SchoolDeviceDetail(
          id: id,
          name: 'ทางเข้าอาคาร 1',
          type: 'camera',
          status: 'online',
          effectiveStatus: 'online',
          serialNo: null,
          deviceCode: null,
          kitCode: null,
          categoryCode: null,
          location: 'อาคาร 1',
          building: null,
          room: null,
          ipAddress: null,
          firmwareVersion: 'cam-fw 2.1.0',
          lastSeenAt: DateTime(2026, 9, 16, 8, 5),
          registeredAt: null,
          updatedAt: null,
        ),
      );
      await tester.tap(find.text('ทางเข้าอาคาร 1'));
      await tester.pumpAndSettle();
      expect(find.text('การรายงานตัวของอุปกรณ์'), findsOneWidget);
      expect(find.text('16/09/2569 08:05'), findsOneWidget);
      expect(find.text('cam-fw 2.1.0'), findsOneWidget);
      expect(find.text('ยังไม่เคยรายงาน'), findsOneWidget);
      expect(find.text('AI Detection'), findsNothing);
    },
  );
}
