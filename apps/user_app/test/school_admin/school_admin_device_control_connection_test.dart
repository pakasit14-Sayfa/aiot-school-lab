import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/school_admin_device_control_page.dart';
import 'package:shared_core/shared_core.dart';

/// This page told an administrator that a light had been switched off when
/// all that had happened was a row being written to a command queue.
///
/// `queue_device_command` enqueues; the gateway polls it, drives the board,
/// and the device calls `ack_device_command`, which is what updates
/// `device_relay_states`. The page announced "ส่งคำสั่ง ปิด X สำเร็จ" the
/// instant the queue call returned and flipped the switch to match — so with
/// an offline device the screen said the light was off while it stayed on.
///
/// It also tracked state in a map that started empty on every page load, so
/// every relay rendered as off regardless of the hardware, and the
/// "สั่งเปิดไว้" counter measured this browser tab rather than the school.

DeviceOption _relay(String id, {String name = 'ไฟอาคาร 1', String? location}) =>
    DeviceOption(
      id: id,
      name: name,
      type: 'relay',
      location: location ?? 'อาคาร 1',
      status: 'online',
    );

DeviceRelayState _state(
  String deviceId, {
  required bool on,
  DateTime? updatedAt,
}) => DeviceRelayState(
  deviceId: deviceId,
  deviceName: 'ไฟอาคาร 1',
  location: 'อาคาร 1',
  relayNo: 1,
  state: on,
  updatedAt: updatedAt ?? DateTime(2026, 9, 6, 14, 30),
);

Future<void> _pump(
  WidgetTester tester, {
  required List<DeviceOption> devices,
  required RelayStateLoader states,
  DeviceCommandSender? send,
  Duration poll = const Duration(milliseconds: 50),
  Duration timeout = const Duration(milliseconds: 300),
}) async {
  tester.view.physicalSize = const Size(1400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SchoolAdminDeviceControlPage(
        loadDevices: () async => devices,
        loadRelayStates: states,
        sendCommand:
            send ?? ({required deviceId, required command}) async => 'cmd-1',
        confirmationPollInterval: poll,
        confirmationTimeout: timeout,
      ),
    ),
  );
}

void main() {
  testWidgets('a relay that has never reported is unknown, not off', (
    tester,
  ) async {
    await _pump(
      tester,
      devices: [_relay('d1')],
      states: () async => const <DeviceRelayState>[],
    );
    await tester.pumpAndSettle();

    expect(
      find.text('ยังไม่ทราบสถานะ — อุปกรณ์ยังไม่เคยรายงาน'),
      findsOneWidget,
    );
    expect(find.text('ยังไม่มีอุปกรณ์ตัวใดรายงานสถานะกลับมา'), findsNothing);
    expect(
      find.textContaining('ยังไม่มีอุปกรณ์ตัวใดรายงานสถานะกลับมา'),
      findsOneWidget,
    );
    // Counted as unknown rather than quietly folded into "off".
    expect(find.text('1 / 1 จุด'), findsWidgets);
  });

  testWidgets('the switch reflects the state the device confirmed', (
    tester,
  ) async {
    // The old page always drew this off: it read a map that starts empty.
    await _pump(
      tester,
      devices: [_relay('d1')],
      states: () async => [_state('d1', on: true)],
    );
    await tester.pumpAndSettle();

    final sw = tester.widget<Switch>(find.byType(Switch));
    expect(sw.value, isTrue);
    expect(
      find.textContaining('อุปกรณ์ยืนยันว่าเปิดอยู่'),
      findsOneWidget,
    );
    expect(find.textContaining('6/9/2026 14:30 น.'), findsWidgets);
  });

  testWidgets('queueing a command is reported as queued, never as success', (
    tester,
  ) async {
    await _pump(
      tester,
      devices: [_relay('d1')],
      // The device never acknowledges.
      states: () async => const <DeviceRelayState>[],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump();

    expect(
      find.textContaining('เข้าคิวแล้ว รออุปกรณ์ยืนยัน'),
      findsOneWidget,
    );
    // The exact claim this page used to make off the back of the queue call.
    expect(find.textContaining('สำเร็จ'), findsNothing);
    expect(find.text('ส่งคำสั่งแล้ว รออุปกรณ์ยืนยัน'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  testWidgets('success is claimed only once the device reports the new state', (
    tester,
  ) async {
    bool acknowledged = false;
    await _pump(
      tester,
      devices: [_relay('d1')],
      states: () async =>
          acknowledged ? [_state('d1', on: true)] : const <DeviceRelayState>[],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump();
    expect(find.text('ส่งคำสั่งแล้ว รออุปกรณ์ยืนยัน'), findsOneWidget);
    expect(find.textContaining('อุปกรณ์ยืนยันว่าเปิดอยู่'), findsNothing);

    // The board acts and acknowledges.
    acknowledged = true;
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();

    expect(find.textContaining('อุปกรณ์ยืนยันว่าเปิดอยู่'), findsOneWidget);
    expect(find.text('ส่งคำสั่งแล้ว รออุปกรณ์ยืนยัน'), findsNothing);
  });

  testWidgets('a command the device never confirms is surfaced, not assumed', (
    tester,
  ) async {
    await _pump(
      tester,
      devices: [_relay('d1')],
      states: () async => const <DeviceRelayState>[],
      poll: const Duration(milliseconds: 30),
      timeout: const Duration(milliseconds: 60),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(
      find.text('อุปกรณ์ยังไม่ยืนยัน — ตรวจสอบหน้างาน'),
      findsOneWidget,
    );
    expect(find.textContaining('อุปกรณ์ยืนยันว่า'), findsNothing);
  });

  testWidgets('the on-count reports the hardware, not this browser tab', (
    tester,
  ) async {
    await _pump(
      tester,
      devices: [
        _relay('d1', name: 'ไฟทางเดิน'),
        _relay('d2', name: 'ไฟห้องประชุม'),
        _relay('d3', name: 'ปั๊มน้ำ'),
      ],
      states: () async => [_state('d1', on: true), _state('d2', on: false)],
    );
    await tester.pumpAndSettle();

    // One confirmed on, one confirmed off, one never reported.
    expect(find.text('1 / 3 จุด'), findsWidgets);
    expect(find.text('ยังไม่ทราบสถานะ'), findsOneWidget);
  });

  testWidgets('a failed load hides the raw backend error', (tester) async {
    await _pump(
      tester,
      devices: const [],
      states: () async => throw StateError('relay_states_boom'),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('โหลดรายชื่ออุปกรณ์ควบคุมไม่สำเร็จ กรุณาลองใหม่'),
      findsOneWidget,
    );
    expect(find.textContaining('relay_states_boom'), findsNothing);
    expect(find.textContaining('StateError'), findsNothing);
  });

  testWidgets('a failed command does not move the switch or claim success', (
    tester,
  ) async {
    await _pump(
      tester,
      devices: [_relay('d1')],
      states: () async => [_state('d1', on: false)],
      send: ({required deviceId, required command}) async =>
          throw StateError('queue_boom'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('ส่งคำสั่งไม่สำเร็จ กรุณาลองใหม่'), findsOneWidget);
    expect(find.textContaining('queue_boom'), findsNothing);
    // Still showing the last state the device confirmed.
    final sw = tester.widget<Switch>(find.byType(Switch));
    expect(sw.value, isFalse);
    expect(find.textContaining('อุปกรณ์ยืนยันว่าปิดอยู่'), findsOneWidget);
  });

  testWidgets('shows a loading indicator before the first load settles', (
    tester,
  ) async {
    final completer = Completer<List<DeviceRelayState>>();
    await _pump(
      tester,
      devices: [_relay('d1')],
      states: () => completer.future,
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(const <DeviceRelayState>[]);
    await tester.pumpAndSettle();
  });
}
