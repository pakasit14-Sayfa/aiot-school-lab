import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_emergency_page.dart';
import 'package:shared_core/shared_core.dart';

/// This page is the one screen where a fabricated row is not a cosmetic
/// problem. It used to render, for a school with nothing wrong:
///
///   - a full active-SOS hero card: "SOS จากนักเรียน ห้อง ม.3/2", location
///     "อาคาร 3 ชั้น 2", "แจ้งมา 28 วิ", reported by "ครูสมหญิง ใจดี"
///   - four emergency duty teams naming ครูสมชาย, ครูพิมพ์ใจ, ครูสุพรรณี and
///     อ.วินัย, with live statuses like "กำลังไปจุดเกิดเหตุ"
///   - an 86-line list of past incidents, and summary counters computed from it
///
/// None of it existed. Every read was guarded by `_hasRealData ? real : fake`,
/// and `_hasRealData` is false exactly when the school has no incidents — so
/// the safest possible state rendered as the worst one. The three reads also
/// swallowed their own failures into empty lists, which made an unreachable
/// backend indistinguishable from a quiet day.
///
/// There is no Supabase client in a widget test, so every service call throws.
/// That is the failure path, and this suite pins what it must show: an honest
/// "we do not know" — never an invented emergency, and never a false all-clear.
void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    EmergencyEventsLoader? events,
    IncidentSummaryLoader? summary,
    IncidentReportsLoader? incidents,
  }) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        // The page is a bare Column, not a Scaffold — its TextField needs a
        // Material ancestor to build at all.
        home: Scaffold(
          body: DirectorEmergencyPage(
            watchUpdates: false,
            loadEmergencyEvents:
                events ?? () async => throw StateError('unreachable'),
            loadIncidentSummary:
                summary ?? () async => throw StateError('unreachable'),
            loadIncidentReports:
                incidents ?? () async => throw StateError('unreachable'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('never invents an emergency, a room, or a responder', (
    tester,
  ) async {
    await pumpPage(tester);

    for (final invented in <String>[
      'SOS จากนักเรียน ห้อง ม.3/2',
      'ห้อง ม.3/2 • แจ้งมา 28 วิ',
      'ปุ่ม SOS ห้อง ม.3/2',
      'อาคาร 3 ชั้น 2',
      'ผู้แจ้ง: ครูสมหญิง ใจดี',
      'ครูเวรประจำวัน (อาคาร 1–3)',
      'ครูสมชาย, ครูพิมพ์ใจ (พร้อม 3 ท่าน)',
      'ครูสุพรรณี (ห้องพยาบาล อาคาร 1)',
      'อ.วินัย พร้อมครูผู้ช่วย 2 ท่าน',
      'กำลังไปจุดเกิดเหตุ',
      'ประจำจุดตรวจ',
      'พร้อมดูแลทันที',
    ]) {
      expect(
        find.textContaining(invented),
        findsNothing,
        reason: 'ยังพบของที่แต่งขึ้น: $invented',
      );
    }
  });

  testWidgets('a failed read says so instead of reporting an all-clear', (
    tester,
  ) async {
    await pumpPage(tester);

    // The distinction that matters most on this page: "we could not check"
    // must never be drawn as "nothing is wrong".
    expect(find.text('ยังไม่ทราบสถานะเหตุฉุกเฉิน'), findsOneWidget);
    expect(find.textContaining('อย่าถือว่าไม่มีเหตุ'), findsOneWidget);
    expect(find.text('ไม่มีเหตุฉุกเฉินที่กำลังดำเนินอยู่'), findsNothing);

    expect(
      find.textContaining('โหลดข้อมูลเหตุฉุกเฉินไม่สำเร็จ'),
      findsOneWidget,
    );
    // No raw backend text on screen.
    expect(find.textContaining('Exception'), findsNothing);
  });

  testWidgets('the duty roster is an honest gap, not a staffed team list', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('ยังไม่มีข้อมูลเวรฉุกเฉิน'), findsOneWidget);
    expect(
      find.textContaining('ประสานงานตามช่องทางของโรงเรียนโดยตรง'),
      findsOneWidget,
    );
  });

  testWidgets('counters do not count invented incidents', (tester) async {
    await pumpPage(tester);

    // sosPendingCount used to fall back to the literal 1, so a school with no
    // incidents was told one SOS was pending.
    expect(find.text('พบสัญญาณ SOS รอการตอบสนอง'), findsNothing);
  });

  testWidgets('a confirmed-empty school gets a real all-clear', (tester) async {
    await pumpPage(
      tester,
      events: () async => const <EmergencyEventItem>[],
      summary: () async => const <IncidentSummaryItem>[],
      incidents: () async => const <TeacherIncidentReport>[],
    );

    // Reads succeeded and returned nothing — this is the one case where an
    // all-clear is honest.
    expect(find.text('ไม่มีเหตุฉุกเฉินที่กำลังดำเนินอยู่'), findsOneWidget);
    expect(find.text('ยังไม่ทราบสถานะเหตุฉุกเฉิน'), findsNothing);
    expect(find.textContaining('โหลดข้อมูลเหตุฉุกเฉินไม่สำเร็จ'), findsNothing);
    expect(find.textContaining('SOS จากนักเรียน ห้อง ม.3/2'), findsNothing);
  });
}
