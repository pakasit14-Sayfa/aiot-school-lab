import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/controllers/director_emergency_controller.dart';
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
    IncidentReportCloser? closeIncident,
    EmergencyEventCloser? closeEmergency,
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
            closeIncidentReport: closeIncident,
            closeEmergencyEvent: closeEmergency,
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

  testWidgets('no button is left that only raises a "ยังไม่มีระบบ…" snackbar', (
    tester,
  ) async {
    await pumpPage(
      tester,
      events: () async => const [],
      summary: () async => const [],
      incidents: () async => [
        TeacherIncidentReport(
          id: 'incident-1',
          category: IncidentCategory.sos,
          room: 'ม.3/2',
          status: 'acknowledged',
          reporterName: 'นักเรียนทดสอบ',
          createdAt: DateTime.utc(2026, 9, 7, 8),
        ),
      ],
    );
    for (final label in [
      'แผนที่จุดเกิดเหตุ',
      'โทรครูเวร',
      'แจ้งเตือนซ้ำ',
      'เปิดดูกล้อง CCTV ห้องนี้',
    ]) {
      expect(find.text(label), findsNothing, reason: label);
    }

    // "ประวัติเหตุการณ์" used to say "กำลังเปิดรายงาน…" and open nothing;
    // now it resets the real history list to show everything.
    await tester.tap(find.text('ปิดเหตุแล้ว').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ประวัติเหตุการณ์'));
    await tester.pumpAndSettle();
    expect(find.textContaining('กำลังเปิดรายงาน'), findsNothing);
    expect(find.text('SOS จากนักเรียน'), findsWidgets);
  });

  testWidgets('the SOS detail does not invent a notified team or a broadcast', (
    tester,
  ) async {
    await pumpPage(
      tester,
      events: () async => const [],
      summary: () async => const [],
      incidents: () async => [
        TeacherIncidentReport(
          id: 'incident-1',
          category: IncidentCategory.sos,
          room: 'ม.3/2',
          status: 'acknowledged',
          reporterName: 'นักเรียนทดสอบ',
          createdAt: DateTime.utc(2026, 9, 7, 8),
        ),
      ],
    );
    await tester.tap(find.text('✓ ผอ. รับเรื่องแล้ว'));
    await tester.pumpAndSettle();

    expect(find.text('ครูเวรอาคาร 3'), findsNothing);
    expect(find.textContaining('ครูห้องพยาบาล / อนามัยโรงเรียน'), findsNothing);
    expect(find.text('ได้รับแจ้งแล้ว'), findsNothing);
    expect(find.text('Standby พร้อม'), findsNothing);
    expect(find.textContaining('ส่งผ่านแอปและระบบข้อความด่วน'), findsNothing);
    expect(
      find.textContaining('กำลังเข้าพื้นที่พร้อมชุดปฐมพยาบาล'),
      findsNothing,
    );
    expect(find.text('โทรด่วนหาครูประจำห้อง'), findsNothing);
    expect(
      find.textContaining('ยังไม่มีตารางเวรและการยืนยันรับแจ้ง'),
      findsOneWidget,
    );
  });

  group('closing an SOS', () {
    final openIncident = TeacherIncidentReport(
      id: 'incident-1',
      category: IncidentCategory.sos,
      room: 'ม.3/2',
      status: 'acknowledged',
      reporterName: 'นักเรียนทดสอบ',
      createdAt: DateTime.utc(2026, 9, 7, 8),
    );

    TeacherIncidentReport resolvedIncident() => TeacherIncidentReport(
      id: openIncident.id,
      category: openIncident.category,
      room: openIncident.room,
      status: 'resolved',
      reporterName: openIncident.reporterName,
      createdAt: openIncident.createdAt,
    );

    EmergencyEventItem emergencyEvent(String status) => EmergencyEventItem(
      id: 'event-1',
      schoolId: 'school-1',
      deviceName: 'ปุ่มหน้าอาคาร',
      location: 'อาคาร 1',
      triggeredAt: DateTime.utc(2026, 9, 7, 10),
      status: status,
      warningLightOn: status != 'closed',
    );

    for (final physical in [false, true]) {
      for (final missing in [false, true]) {
        testWidgets(
          '${physical ? "hardware" : "SOS"} ${missing ? "missing row" : "read failure"} never confirms closure',
          (tester) async {
            var closeCalled = false;
            Future<List<T>> read<T>(T row) async {
              if (!closeCalled) return [row];
              if (missing) return [];
              throw StateError('canonical-read-secret');
            }

            await pumpPage(
              tester,
              events: () => physical
                  ? read(emergencyEvent('acknowledged'))
                  : Future.value([]),
              summary: () async => [],
              incidents: () => physical ? Future.value([]) : read(openIncident),
              closeIncident:
                  (
                    _, {
                    required resolutionType,
                    required resolutionNote,
                  }) async {
                    closeCalled = true;
                  },
              closeEmergency: ({required eventId, required reviewNote}) async {
                closeCalled = true;
              },
            );
            await tester.tap(
              find.byKey(const Key('director-emergency-close-hero')),
            );
            await tester.pumpAndSettle();
            expect(closeCalled, isTrue);
            expect(
              find.text('ปิดเหตุไม่สำเร็จ เหตุการณ์ยังเปิดอยู่'),
              findsOneWidget,
            );
            expect(find.text('✓ ปิดเหตุเรียบร้อยแล้ว'), findsNothing);
            expect(
              find.text('ไม่มีเหตุฉุกเฉินที่กำลังดำเนินอยู่'),
              findsNothing,
            );
            expect(
              find.byKey(const Key('director-emergency-close-hero')),
              findsOneWidget,
            );
            expect(find.textContaining('canonical-read-secret'), findsNothing);
            expect(
              find.textContaining('backend_close_not_confirmed'),
              findsNothing,
            );
          },
        );
      }
    }

    for (final detail in [false, true]) {
      for (final confirmed in [false, true]) {
        testWidgets(
          '${detail ? "detail" : "modal"} ${confirmed ? "closes only after confirmation" : "stays open after rejected write"}',
          (tester) async {
            var closed = false;
            await pumpPage(
              tester,
              events: () async => [],
              summary: () async => [],
              incidents: () async => [
                closed && confirmed ? resolvedIncident() : openIncident,
              ],
              closeIncident:
                  (
                    _, {
                    required resolutionType,
                    required resolutionNote,
                  }) async {
                    closed = true;
                  },
            );
            if (detail) {
              await tester.tap(find.text('SOS จากนักเรียน').first);
            } else {
              await tester.tap(find.text('✓ ผอ. รับเรื่องแล้ว'));
            }
            await tester.pumpAndSettle();
            final button = find.byKey(
              Key('director-emergency-close-${detail ? "detail" : "modal"}'),
            );
            await tester.tap(button);
            await tester.pumpAndSettle();
            expect(closed, isTrue);
            expect(
              find.text('✓ ปิดเหตุเรียบร้อยแล้ว'),
              confirmed ? findsOneWidget : findsNothing,
            );
            expect(
              find.text('ปิดเหตุไม่สำเร็จ เหตุการณ์ยังเปิดอยู่'),
              confirmed ? findsNothing : findsOneWidget,
            );
            expect(button, confirmed ? findsNothing : findsOneWidget);
            if (!confirmed) {
              expect(
                find
                    .text('ปิดเหตุไม่สำเร็จ เหตุการณ์ยังเปิดอยู่')
                    .hitTestable(),
                findsOneWidget,
                reason:
                    'Failure feedback must be visible above the modal barrier',
              );
              await tester.tap(find.text('ตกลง'));
              await tester.pumpAndSettle();
              expect(button.hitTestable(), findsOneWidget);
              expect(find.text('✓ ปิดเหตุเรียบร้อยแล้ว'), findsNothing);
            }
            expect(
              find.textContaining('backend_close_not_confirmed'),
              findsNothing,
            );
          },
        );
      }
    }

    testWidgets('RPC failure keeps the SOS open and hides raw backend errors', (
      tester,
    ) async {
      await pumpPage(
        tester,
        events: () async => const [],
        summary: () async => const [],
        incidents: () async => [openIncident],
        closeIncident:
            (_, {required resolutionType, required resolutionNote}) async =>
                throw StateError('secret-backend-error'),
      );

      await tester.tap(find.byKey(const Key('director-emergency-close-hero')));
      await tester.pumpAndSettle();

      expect(
        find.text('ปิดเหตุไม่สำเร็จ เหตุการณ์ยังเปิดอยู่'),
        findsOneWidget,
      );
      expect(find.text('✓ ปิดเหตุเรียบร้อยแล้ว'), findsNothing);
      expect(find.text('ปิดเหตุการณ์ (เสร็จสิ้น)'), findsOneWidget);
      expect(find.textContaining('secret-backend-error'), findsNothing);
      expect(find.textContaining('StateError'), findsNothing);
    });

    testWidgets('an unconfirmed backend write is reported as a failure', (
      tester,
    ) async {
      await pumpPage(
        tester,
        events: () async => const [],
        summary: () async => const [],
        incidents: () async => [openIncident],
        closeIncident:
            (_, {required resolutionType, required resolutionNote}) async {},
      );

      await tester.tap(find.byKey(const Key('director-emergency-close-hero')));
      await tester.pumpAndSettle();

      expect(
        find.text('ปิดเหตุไม่สำเร็จ เหตุการณ์ยังเปิดอยู่'),
        findsOneWidget,
      );
      expect(find.text('✓ ปิดเหตุเรียบร้อยแล้ว'), findsNothing);
      expect(find.text('ปิดเหตุการณ์ (เสร็จสิ้น)'), findsOneWidget);
    });

    testWidgets('success is shown only after the canonical row is resolved', (
      tester,
    ) async {
      var closed = false;
      await pumpPage(
        tester,
        events: () async => const [],
        summary: () async => const [],
        incidents: () async => [
          if (closed) resolvedIncident() else openIncident,
        ],
        closeIncident:
            (_, {required resolutionType, required resolutionNote}) async {
              closed = true;
            },
      );

      await tester.tap(find.byKey(const Key('director-emergency-close-hero')));
      await tester.pumpAndSettle();

      expect(find.text('✓ ปิดเหตุเรียบร้อยแล้ว'), findsOneWidget);
      expect(find.text('ปิดเหตุไม่สำเร็จ เหตุการณ์ยังเปิดอยู่'), findsNothing);
      expect(find.text('ไม่มีเหตุฉุกเฉินที่กำลังดำเนินอยู่'), findsOneWidget);
      expect(find.text('ปิดเหตุการณ์ (เสร็จสิ้น)'), findsNothing);
    });

    testWidgets('the modal close control uses the same safe failure path', (
      tester,
    ) async {
      await pumpPage(
        tester,
        events: () async => const [],
        summary: () async => const [],
        incidents: () async => [openIncident],
        closeIncident:
            (_, {required resolutionType, required resolutionNote}) async =>
                throw StateError('modal-secret'),
      );

      await tester.tap(find.text('✓ ผอ. รับเรื่องแล้ว'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('director-emergency-close-modal')));
      await tester.pumpAndSettle();

      expect(
        find.text('ปิดเหตุไม่สำเร็จ เหตุการณ์ยังเปิดอยู่'),
        findsOneWidget,
      );
      expect(find.text('✓ ปิดเหตุเรียบร้อยแล้ว'), findsNothing);
      expect(
        find.byKey(const Key('director-emergency-close-modal')),
        findsOneWidget,
      );
      expect(find.textContaining('modal-secret'), findsNothing);
    });

    testWidgets('the event-detail close control uses the safe failure path', (
      tester,
    ) async {
      final report = TeacherIncidentReport(
        id: 'incident-detail',
        category: IncidentCategory.anomaly,
        room: 'ม.2/1',
        status: 'acknowledged',
        reporterName: 'นักเรียนทดสอบ',
        createdAt: DateTime.utc(2026, 9, 7, 9),
        reason: 'เหตุสำหรับทดสอบรายละเอียด',
      );
      await pumpPage(
        tester,
        events: () async => const [],
        summary: () async => const [],
        incidents: () async => [report],
        closeIncident:
            (_, {required resolutionType, required resolutionNote}) async =>
                throw StateError('detail-secret'),
      );

      await tester.tap(find.text('เหตุสำหรับทดสอบรายละเอียด').first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('director-emergency-close-detail')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('ปิดเหตุไม่สำเร็จ เหตุการณ์ยังเปิดอยู่'),
        findsOneWidget,
      );
      expect(find.text('✓ ปิดเหตุเรียบร้อยแล้ว'), findsNothing);
      expect(
        find.byKey(const Key('director-emergency-close-detail')),
        findsOneWidget,
      );
      expect(find.textContaining('detail-secret'), findsNothing);
    });

    testWidgets('a physical emergency is confirmed from its canonical row', (
      tester,
    ) async {
      var closed = false;
      await pumpPage(
        tester,
        events: () async => [
          emergencyEvent(closed ? 'closed' : 'acknowledged'),
        ],
        summary: () async => const [],
        incidents: () async => const [],
        closeEmergency: ({required eventId, required reviewNote}) async {
          closed = true;
        },
      );

      await tester.tap(find.byKey(const Key('director-emergency-close-hero')));
      await tester.pumpAndSettle();

      expect(find.text('✓ ปิดเหตุเรียบร้อยแล้ว'), findsOneWidget);
      expect(find.text('ไม่มีเหตุฉุกเฉินที่กำลังดำเนินอยู่'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
    });

    testWidgets('a physical emergency RPC failure keeps the event open', (
      tester,
    ) async {
      await pumpPage(
        tester,
        events: () async => [emergencyEvent('acknowledged')],
        summary: () async => const [],
        incidents: () async => const [],
        closeEmergency: ({required eventId, required reviewNote}) async =>
            throw StateError('physical-secret'),
      );

      await tester.tap(find.byKey(const Key('director-emergency-close-hero')));
      await tester.pumpAndSettle();

      expect(
        find.text('ปิดเหตุไม่สำเร็จ เหตุการณ์ยังเปิดอยู่'),
        findsOneWidget,
      );
      expect(find.text('✓ ปิดเหตุเรียบร้อยแล้ว'), findsNothing);
      expect(find.textContaining('physical-secret'), findsNothing);
      expect(
        find.byKey(const Key('director-emergency-close-hero')),
        findsOneWidget,
      );
    });

    testWidgets('an unconfirmed physical emergency write stays open', (
      tester,
    ) async {
      await pumpPage(
        tester,
        events: () async => [emergencyEvent('acknowledged')],
        summary: () async => const [],
        incidents: () async => const [],
        closeEmergency: ({required eventId, required reviewNote}) async {},
      );

      await tester.tap(find.byKey(const Key('director-emergency-close-hero')));
      await tester.pumpAndSettle();

      expect(
        find.text('ปิดเหตุไม่สำเร็จ เหตุการณ์ยังเปิดอยู่'),
        findsOneWidget,
      );
      expect(find.text('✓ ปิดเหตุเรียบร้อยแล้ว'), findsNothing);
      expect(
        find.byKey(const Key('director-emergency-close-hero')),
        findsOneWidget,
      );
    });
  });
}
