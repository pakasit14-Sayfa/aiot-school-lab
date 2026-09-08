import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/student_redesign_prototype/student_safety_page.dart';
import 'package:shared_core/shared_core.dart';

/// StudentSafetyPage is the SOS button — the single highest-stakes real
/// write in the whole Student lane. These tests pin down that submitting
/// really reaches the real RPC with the category/severity/reason actually
/// chosen, that the 3-second hold-to-confirm can't be short-circuited, and
/// that an already-open incident disables the button (no duplicate SOS).

final _report = MyIncidentReport(
  id: 'inc-1',
  category: IncidentCategory.sos,
  room: 'ม.1/1',
  status: 'new',
  createdAt: DateTime(2026, 9, 1, 9),
  acknowledgedAt: null,
  closedAt: null,
);

Future<void> _pump(
  WidgetTester tester, {
  Future<MyStudentRoom?> Function()? loadRoom,
  Future<List<MyIncidentReport>> Function()? loadIncidents,
  Future<String> Function({
    required IncidentCategory category,
    String? room,
    String? reason,
    String? severity,
  })?
  submitIncident,
  Stream<List<Map<String, dynamic>>> Function()? watchIncidents,
}) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: StudentSafetyPage(
        loadRoom: loadRoom ?? () async => const MyStudentRoom(room: 'ม.1/1', gradeLevel: 'ม.1'),
        loadIncidents: loadIncidents ?? () async => const [],
        submitIncident: submitIncident,
        watchIncidents: watchIncidents ?? () => const Stream.empty(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the SOS button is disabled while an incident is already open', (
    tester,
  ) async {
    var submitCalls = 0;
    await _pump(
      tester,
      loadIncidents: () async => [_report],
      submitIncident:
          ({required category, room, reason, severity}) async {
        submitCalls++;
        return 'new-id';
      },
    );

    await tester.tap(find.text('SOS'));
    await tester.pumpAndSettle();

    // Disabled button (onTap: null) shows no confirm sheet, so the reason
    // field never appears and the RPC is never reached.
    expect(find.text('ระบุเหตุผลและยืนยันการแจ้งเหตุ'), findsNothing);
    expect(submitCalls, 0);
  });

  testWidgets('releasing before 3 seconds cancels — nothing is submitted', (
    tester,
  ) async {
    var submitCalls = 0;
    await _pump(
      tester,
      submitIncident:
          ({required category, room, reason, severity}) async {
        submitCalls++;
        return 'new-id';
      },
    );

    await tester.tap(find.text('SOS'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('🩺 เจ็บป่วย / ไม่สบายด่วน'));
    await tester.pump();

    final holdButton = find.byIcon(Icons.emergency_rounded).last;
    final gesture = await tester.startGesture(tester.getCenter(holdButton));
    await tester.pump(const Duration(milliseconds: 800));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(submitCalls, 0, reason: 'releasing early must not submit anything');
    expect(find.text('ระบุเหตุผลและยืนยันการแจ้งเหตุ'), findsOneWidget);
  });

  testWidgets(
    'holding for the full 3 seconds submits the real category/room/reason/severity',
    (tester) async {
      IncidentCategory? gotCategory;
      String? gotRoom;
      String? gotReason;
      String? gotSeverity;

      await _pump(
        tester,
        submitIncident:
            ({required category, room, reason, severity}) async {
          gotCategory = category;
          gotRoom = room;
          gotReason = reason;
          gotSeverity = severity;
          return 'new-id';
        },
      );

      await tester.tap(find.text('SOS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('🔴 เหตุใหญ่ / ด่วน'));
      await tester.tap(find.text('🚨 ฉุกเฉินร้ายแรง / บุกรุก'));
      await tester.pump();

      final holdButton = find.byIcon(Icons.emergency_rounded).last;
      final gesture = await tester.startGesture(tester.getCenter(holdButton));
      await tester.pump(const Duration(milliseconds: 3100));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(gotCategory, IncidentCategory.sos);
      expect(gotRoom, 'ม.1/1');
      expect(gotReason, '🚨 ฉุกเฉินร้ายแรง / บุกรุก');
      expect(gotSeverity, 'high');
      // Confirmation sheet closed and success sheet appeared — real submit,
      // not a client-side-only fake.
      expect(find.text('ส่งสัญญาณแจ้งเหตุเรียบร้อยแล้ว'), findsOneWidget);
    },
  );

  testWidgets('holding without picking a reason is refused, nothing submitted', (
    tester,
  ) async {
    var submitCalls = 0;
    await _pump(
      tester,
      submitIncident:
          ({required category, room, reason, severity}) async {
        submitCalls++;
        return 'new-id';
      },
    );

    await tester.tap(find.text('SOS'));
    await tester.pumpAndSettle();

    final holdButton = find.byIcon(Icons.emergency_rounded).last;
    await tester.tap(holdButton);
    await tester.pump();

    expect(submitCalls, 0, reason: 'a required reason must gate the hold-to-confirm');
    expect(find.textContaining('กรุณาเลือกชิปเหตุผล'), findsOneWidget);
  });

  testWidgets('an empty history shows an honest empty state', (tester) async {
    await _pump(tester);
    expect(find.text('ยังไม่มีประวัติการแจ้งเหตุ'), findsOneWidget);
  });
}
