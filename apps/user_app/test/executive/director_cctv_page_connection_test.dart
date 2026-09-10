import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_cctv_page.dart';
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
        body: DirectorCctvPage(listSchoolDevices: listSchoolDevices),
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

  testWidgets('zero real cameras shows an honest empty state, not fabricated tiles', (
    tester,
  ) async {
    await _pump(tester, listSchoolDevices: () async => const []);
    expect(find.text('พบ 0 กล้อง'), findsOneWidget);
  });

  testWidgets(
    'the AI alerts section discloses it is unavailable instead of showing fake alerts',
    (tester) async {
      await _pump(tester, listSchoolDevices: () async => const []);
      expect(
        find.text('ระบบแจ้งเตือนอัตโนมัติจาก AI Camera ยังไม่รองรับในระบบนี้'),
        findsOneWidget,
      );
      // None of the old fabricated alert titles should ever appear.
      expect(find.textContaining('ตรวจพบพฤติกรรมเสี่ยง'), findsNothing);
    },
  );

  testWidgets(
    'the summary cards use real online/offline counts, not the old fake 24/22/2',
    (tester) async {
      await _pump(
        tester,
        listSchoolDevices: () async => const [_onlineCamera, _offlineCamera],
      );
      expect(find.text('2'), findsWidgets); // total = 2
      expect(find.text('1'), findsWidgets); // online = 1, offline = 1
      // The AI/alert/storage tiles have zero real backing - must say so.
      expect(find.text('ยังไม่รองรับ'), findsNWidgets(3));
    },
  );
}
