import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_aiot_dashboard_page.dart';
import 'package:shared_core/shared_core.dart';

/// This page used to seed _devices/_thresholds/_alerts with mock data on
/// initState, replaced only `if (list.isNotEmpty)` - a school with zero
/// real devices/thresholds/alerts saw fake ones forever. These tests pin
/// down real loading/empty states and that acknowledging an alert calls
/// the real RPC.

const _device = DeviceOption(
  id: 'dev-1',
  name: 'เซนเซอร์ห้อง ม.1/1',
  type: 'sensor',
  location: 'ม.1/1',
  status: 'online',
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<DeviceOption>> Function()? listSchoolDevices,
  Future<Map<String, SensorModel>> Function()? getAllDeviceSensors,
  Future<List<DeviceRelayState>> Function()? listDeviceRelayStates,
  Future<List<Map<String, dynamic>>> Function()? listThresholds,
  Future<List<Map<String, dynamic>>> Function({String? status})? listAlerts,
  Future<void> Function(String alertId)? acknowledgeAlert,
}) async {
  tester.view.physicalSize = const Size(1400, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: TeacherAiotDashboardPage(
        listSchoolDevices: listSchoolDevices ?? () async => const [],
        getAllDeviceSensors: getAllDeviceSensors ?? () async => const {},
        listDeviceRelayStates: listDeviceRelayStates ?? () async => const [],
        listThresholds: listThresholds ?? () async => const [],
        listAlerts: listAlerts ?? ({status}) async => const [],
        acknowledgeAlert: acknowledgeAlert,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'zero real devices shows an honest empty state, not fabricated sensor cards',
    (tester) async {
      await _pump(tester);
      expect(
        find.text('ยังไม่มีอุปกรณ์ AIoT ที่ลงทะเบียนไว้ในระบบ'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'a real device with a real sensor reading shows the real name, not invented data',
    (tester) async {
      await _pump(
        tester,
        listSchoolDevices: () async => const [_device],
        getAllDeviceSensors: () async => {
          'ม.1/1': SensorModel(
            pm25: 12.5,
            temperature: 27.3,
            humidity: 55,
            lux: 300,
            updatedAt: DateTime(2026, 9, 8, 9),
            metricUpdatedAt: {'pm25': DateTime(2026, 9, 8, 9)},
          ),
        },
      );
      expect(find.text('เซนเซอร์ห้อง ม.1/1'), findsOneWidget);
      expect(
        find.text('ยังไม่มีอุปกรณ์ AIoT ที่ลงทะเบียนไว้ในระบบ'),
        findsNothing,
      );
      expect(find.text('Online'), findsOneWidget);
    },
  );

  testWidgets(
    'a real device with a real offline status shows Offline, not a hardcoded Online',
    (tester) async {
      const offlineDevice = DeviceOption(
        id: 'dev-2',
        name: 'เซนเซอร์ห้อง ม.1/2',
        type: 'sensor',
        location: 'ม.1/2',
        status: 'offline',
      );
      await _pump(tester, listSchoolDevices: () async => const [offlineDevice]);
      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Online'), findsNothing);
    },
  );

  testWidgets(
    'zero real alerts shows an honest empty state on the alerts tab',
    (tester) async {
      await _pump(tester);
      await tester.tap(find.text('แจ้งเตือน (Alerts)'));
      await tester.pumpAndSettle();
      expect(find.text('ยังไม่มีการแจ้งเตือนในระบบ'), findsOneWidget);
    },
  );

  testWidgets(
    'acknowledging a real alert calls the real RPC with the real alert id',
    (tester) async {
      String? acknowledgedId;
      await _pump(
        tester,
        listAlerts: ({status}) async => [
          {
            'id': 'alert-1',
            'device_name': 'เซนเซอร์ห้อง ม.1/1',
            'device_code': 'ม.1/1',
            'metric': 'pm25',
            'value': 80,
            'triggered_at': '2026-09-08T09:00:00Z',
            'status': 'new',
          },
        ],
        acknowledgeAlert: (alertId) async {
          acknowledgedId = alertId;
        },
      );

      await tester.tap(find.text('แจ้งเตือน (Alerts)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('รับทราบ Alert'));
      await tester.pumpAndSettle();

      expect(acknowledgedId, 'alert-1');
      expect(find.text('รับทราบ Alert'), findsNothing);
    },
  );

  testWidgets(
    'a failed acknowledge shows an honest message, no leaked exception text',
    (tester) async {
      await _pump(
        tester,
        listAlerts: ({status}) async => [
          {
            'id': 'alert-1',
            'device_name': 'เซนเซอร์ห้อง ม.1/1',
            'device_code': 'ม.1/1',
            'metric': 'pm25',
            'value': 80,
            'triggered_at': '2026-09-08T09:00:00Z',
            'status': 'new',
          },
        ],
        acknowledgeAlert: (_) async =>
            throw StateError('backend detail that must stay internal'),
      );

      await tester.tap(find.text('แจ้งเตือน (Alerts)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('รับทราบ Alert'));
      await tester.pumpAndSettle();

      expect(find.text('รับทราบไม่สำเร็จ กรุณาลองใหม่'), findsOneWidget);
      expect(find.textContaining('backend detail'), findsNothing);
    },
  );
}
