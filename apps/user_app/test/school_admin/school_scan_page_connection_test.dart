import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/school_scan_page.dart';
import 'package:shared_core/shared_core.dart';

/// Until 2026-09-07 this page could not reach the backend at all — it did not
/// even import `shared_core`. Scanning a code showed the raw string and an
/// "เปิดข้อมูล" button whose only effect was a SnackBar naming the code back
/// to you. Nothing was ever looked up.
///
/// The lookup now goes through `list_school_devices` (verified against the
/// running database to take `p_token` and to allow `school_admin`). These
/// tests pin the states apart — in particular that "not found" and "lookup
/// failed" stay distinct, so an admin is never told a device does not exist
/// when the truth is that the query never succeeded.

DeviceOption _device({
  String id = 'dev-1',
  String name = 'เซนเซอร์ห้องทดลอง',
  String type = 'sensor',
  String? location = 'อาคาร 1 ชั้น 2',
  String status = 'online',
}) => DeviceOption(
  id: id,
  name: name,
  type: type,
  location: location,
  status: status,
);

class _ScanHarness extends StatelessWidget {
  const _ScanHarness({required this.page});
  final SchoolScanPage page;

  @override
  Widget build(BuildContext context) => MaterialApp(home: page);
}

/// The scanner widget itself needs a camera, which does not exist in a widget
/// test, so the lookup is driven through the page's public seam instead of by
/// faking a barcode capture.
Future<void> _pumpAndLookup(
  WidgetTester tester, {
  required Future<List<DeviceOption>> Function() loadDevices,
  String code = 'dev-1',
}) async {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    _ScanHarness(page: SchoolScanPage(loadDevices: loadDevices)),
  );
  await tester.pump();

  final state = tester.state(find.byType(SchoolScanPage)) as dynamic;
  // ignore: avoid_dynamic_calls
  state.lookupDeviceForTest(code);
}

void main() {
  testWidgets('a matching device shows its real fields', (tester) async {
    await _pumpAndLookup(tester, loadDevices: () async => [_device()]);
    await tester.pumpAndSettle();

    expect(find.text('เซนเซอร์ห้องทดลอง'), findsOneWidget);
    expect(find.text('อาคาร 1 ชั้น 2'), findsOneWidget);
    expect(find.text('online'), findsOneWidget);
  });

  testWidgets('an empty location is reported honestly, not left blank', (
    tester,
  ) async {
    await _pumpAndLookup(
      tester,
      loadDevices: () async => [_device(location: '')],
    );
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีข้อมูล'), findsOneWidget);
  });

  testWidgets('an unknown code says not found, quoting the code', (
    tester,
  ) async {
    await _pumpAndLookup(
      tester,
      loadDevices: () async => [_device(id: 'other')],
      code: 'UNKNOWN-99',
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('UNKNOWN-99'), findsOneWidget);
    expect(find.text('ยังไม่มีข้อมูล'), findsOneWidget);
  });

  testWidgets(
    'a failed lookup is distinct from not found, and offers a retry',
    (tester) async {
      var calls = 0;
      await _pumpAndLookup(
        tester,
        loadDevices: () async {
          calls++;
          throw StateError('backend detail that must stay internal');
        },
      );
      await tester.pumpAndSettle();

      expect(find.text('ค้นหาไม่สำเร็จ'), findsOneWidget);
      // Critical distinction: never claim the device is absent when the query
      // itself did not succeed.
      expect(find.text('ยังไม่มีข้อมูล'), findsNothing);
      expect(find.textContaining('backend detail'), findsNothing);
      expect(calls, 1);

      await tester.tap(find.text('ลองใหม่'));
      await tester.pumpAndSettle();
      expect(calls, 2, reason: 'retry must actually re-issue the lookup');
    },
  );

  testWidgets('a slow lookup shows progress, not an empty result', (
    tester,
  ) async {
    final gate = Completer<List<DeviceOption>>();
    await _pumpAndLookup(tester, loadDevices: () => gate.future);
    await tester.pump();

    expect(find.text('กำลังค้นหาอุปกรณ์…'), findsOneWidget);
    expect(find.text('ยังไม่มีข้อมูล'), findsNothing);

    gate.complete([_device()]);
    await tester.pumpAndSettle();
    expect(find.text('กำลังค้นหาอุปกรณ์…'), findsNothing);
  });

  testWidgets('scan history starts honestly empty, not the old fake 3 rows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      _ScanHarness(page: SchoolScanPage(loadDevices: () async => [])),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.history_rounded));
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีการสแกนในเซสชันนี้'), findsOneWidget);
    // The old hardcoded rows must never come back.
    expect(find.text('DEV-PM-0004'), findsNothing);
    expect(find.text('KIT-LAB1-01'), findsNothing);
    expect(find.text('DEV-AIR-0002'), findsNothing);
  });

  testWidgets('manually entering a code records a real history entry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      _ScanHarness(page: SchoolScanPage(loadDevices: () async => [])),
    );
    await tester.pump();

    await tester.tap(find.text('กรอกรหัส'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'MANUAL-CODE-42');
    await tester.tap(find.text('ค้นหา'));
    await tester.pumpAndSettle();

    // The scan-result sheet shows the raw value straight away — proof the
    // manual-entry path reached _recordScan/_showScanResult.
    expect(find.text('MANUAL-CODE-42'), findsOneWidget);

    final state = tester.state(find.byType(SchoolScanPage)) as dynamic;
    // ignore: avoid_dynamic_calls
    expect(state.historyForTest, contains('MANUAL-CODE-42'));
  });
}
