import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_emergency_page.dart';
import 'package:shared_core/shared_core.dart';

TeacherIncidentReport incident(String status) => TeacherIncidentReport(
  id: 'incident-1',
  category: IncidentCategory.sos,
  room: 'ม.3/2',
  status: status,
  reporterName: 'นักเรียนทดสอบ',
  createdAt: DateTime.utc(2026, 9, 7, 8),
);

void main() {
  testWidgets('waits for reads before an all-clear or close success', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final initialRead = Completer<List<TeacherIncidentReport>>();
    final confirmation = Completer<List<TeacherIncidentReport>>();
    var closeCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DirectorEmergencyPage(
            watchUpdates: false,
            loadEmergencyEvents: () async => [],
            loadIncidentSummary: () async => [],
            loadIncidentReports: () =>
                closeCalls == 0 ? initialRead.future : confirmation.future,
            closeIncidentReport:
                (id, {required resolutionType, required resolutionNote}) async {
                  expect(id, 'incident-1');
                  expect(resolutionType, 'resolved');
                  expect(resolutionNote, isNotEmpty);
                  closeCalls++;
                },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.text('ไม่มีเหตุฉุกเฉินที่กำลังดำเนินอยู่'), findsNothing);

    initialRead.complete([incident('acknowledged')]);
    await tester.pumpAndSettle();
    expect(find.text('ศูนย์บัญชาการเหตุฉุกเฉินและความปลอดภัย'), findsOneWidget);
    expect(find.text('✓ ผอ. รับเรื่องแล้ว'), findsOneWidget);
    final closeButton = find.byKey(const Key('director-emergency-close-hero'));
    await tester.tap(closeButton);
    await tester.pump();
    expect(closeCalls, 1);
    expect(find.text('✓ ปิดเหตุเรียบร้อยแล้ว'), findsNothing);
    expect(closeButton, findsOneWidget);

    confirmation.complete([incident('resolved')]);
    await tester.pumpAndSettle();
    expect(find.text('✓ ปิดเหตุเรียบร้อยแล้ว'), findsOneWidget);
    expect(find.text('ไม่มีเหตุฉุกเฉินที่กำลังดำเนินอยู่'), findsOneWidget);
    expect(closeButton, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('canonical empty state fits phone, tablet and desktop', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in const [
      Size(320, 568),
      Size(375, 667),
      Size(390, 844),
      Size(430, 932),
      Size(768, 1024),
      Size(834, 1194),
      Size(1024, 768),
      Size(1280, 800),
      Size(1440, 900),
      Size(1920, 1080),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DirectorEmergencyPage(
              key: ValueKey(size),
              watchUpdates: false,
              loadEmergencyEvents: () async => [],
              loadIncidentSummary: () async => [],
              loadIncidentReports: () async => [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ไม่มีเหตุฉุกเฉินที่กำลังดำเนินอยู่'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Viewport: $size');
    }
  });
}
