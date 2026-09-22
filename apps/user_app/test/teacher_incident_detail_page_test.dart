import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import '../lib/pages/teacher_redesign_prototype/controllers/staff_emergency_actions.dart';
import '../lib/pages/teacher_redesign_prototype/teacher_incident_inbox_page.dart';

// TeacherIncidentDetailPage takes its StaffEmergencyActions as a constructor
// parameter and never calls any service directly, so it is fully testable
// through injection with no live Supabase client — this is the widget-level
// coverage the earlier teacher-SOS handoff explicitly flagged as missing.

TeacherIncidentReport _incident({String id = 'inc-1', String status = 'new'}) =>
    TeacherIncidentReport(
      id: id,
      category: IncidentCategory.anomaly,
      room: 'ม.3/1',
      status: status,
      reporterName: 'นักเรียน ทดสอบ',
      createdAt: DateTime(2026, 9, 5),
      reason: 'พบควันในห้องเรียน',
    );

StaffEmergencyActions _controller({
  Future<void> Function(String)? acknowledgeIncident,
  Future<void> Function(String)? escalateIncident,
  Future<void> Function(String, String, String)? closeIncident,
  Future<String?> Function(StaffEmergencySource, String)? readStatus,
  Future<void> Function(String, String)? saveIncidentNote,
  Future<String?> Function(String)? readLatestIncidentNote,
}) => StaffEmergencyActions(
  acknowledgeIncident: acknowledgeIncident ?? (_) async {},
  acknowledgeHardware: (_) async {},
  escalateIncident: escalateIncident ?? (_) async {},
  closeIncident: closeIncident ?? (_, __, ___) async {},
  closeHardware: (_, __) async {},
  readStatus: readStatus ?? (_, __) async => 'acknowledged',
  saveIncidentNote: saveIncidentNote ?? (_, __) async {},
  readLatestIncidentNote: readLatestIncidentNote ?? (_) async => null,
);

/// Pushes the detail page as a real second route on top of a placeholder
/// first route, so "does the page pop" can be proven by the placeholder
/// reappearing — not merely asserted from the return value of a method call.
Future<void> _pumpPushed(
  WidgetTester tester,
  TeacherIncidentReport incident,
  StaffEmergencyActions actions,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeacherIncidentDetailPage(
                    incident: incident,
                    actions: actions,
                  ),
                ),
              ),
              child: const Text('open detail'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open detail'));
  await tester.pumpAndSettle();
}

void main() {
  group('acknowledge', () {
    testWidgets(
      'confirmed success pops only after the canonical status matches',
      (tester) async {
        var acked = false;
        final actions = _controller(
          acknowledgeIncident: (_) async => acked = true,
          readStatus: (_, __) async => acked ? 'acknowledged' : 'new',
        );
        await _pumpPushed(tester, _incident(), actions);

        expect(find.text('open detail'), findsNothing);
        await tester.tap(find.text('รับเรื่อง'));
        await tester.pumpAndSettle();
        expect(find.text('open detail'), findsOneWidget);
        expect(find.text('รับเรื่องเรียบร้อยแล้ว'), findsOneWidget);
      },
    );

    testWidgets(
      'a rejected write shows a stable failure and the page stays usable',
      (tester) async {
        final actions = _controller(
          acknowledgeIncident: (_) async =>
              throw StateError('secret backend detail'),
        );
        await _pumpPushed(tester, _incident(), actions);
        await tester.tap(find.text('รับเรื่อง'));
        await tester.pumpAndSettle();

        expect(
          find.text('open detail'),
          findsNothing,
          reason: 'page stays open on failure',
        );
        expect(find.text('ไม่สามารถรับเรื่องได้ กรุณาลองใหม่'), findsOneWidget);
        expect(find.textContaining('secret backend detail'), findsNothing);
        expect(find.text('รับเรื่อง'), findsOneWidget);
      },
    );

    testWidgets(
      'a write that succeeds but does not canonically confirm is unconfirmed, never a false success',
      (tester) async {
        final actions = _controller(
          acknowledgeIncident: (_) async {},
          readStatus: (_, __) async => 'new',
        );
        await _pumpPushed(tester, _incident(), actions);
        await tester.tap(find.text('รับเรื่อง'));
        await tester.pumpAndSettle();

        expect(find.text('open detail'), findsNothing);
        expect(
          find.textContaining('ส่งคำขอแล้ว แต่ยังยืนยันสถานะล่าสุดไม่ได้'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'the control is hidden (not just soft-blocked) while a request is pending',
      (tester) async {
        final response = Completer<void>();
        var writes = 0;
        final actions = _controller(
          acknowledgeIncident: (_) {
            writes++;
            return response.future;
          },
        );
        await _pumpPushed(tester, _incident(), actions);
        await tester.tap(find.text('รับเรื่อง'));
        await tester.pump();

        expect(
          find.text('รับเรื่อง'),
          findsNothing,
          reason:
              'buttons are replaced by a spinner while a request is in flight',
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        response.complete();
        await tester.pumpAndSettle();
        expect(writes, 1);
      },
    );
  });

  group('escalate', () {
    testWidgets(
      'requires confirmation, then confirms success only after status becomes escalated',
      (tester) async {
        var status = 'new';
        final actions = _controller(
          escalateIncident: (_) async => status = 'escalated',
          readStatus: (_, __) async => status,
        );
        await _pumpPushed(tester, _incident(), actions);

        await tester.tap(find.text('ยกระดับเหตุ'));
        await tester.pumpAndSettle();
        expect(
          find.text('open detail'),
          findsNothing,
          reason:
              'the confirmation dialog must appear before any write happens',
        );

        await tester.tap(find.widgetWithText(FilledButton, 'ยกระดับเหตุ'));
        await tester.pumpAndSettle();

        expect(find.text('open detail'), findsOneWidget);
        expect(
          find.text('ยกระดับเป็นเหตุฉุกเฉินเรียบร้อยแล้ว'),
          findsOneWidget,
        );
      },
    );

    testWidgets('cancelling the confirmation dialog never calls the write', (
      tester,
    ) async {
      var writes = 0;
      final actions = _controller(escalateIncident: (_) async => writes++);
      await _pumpPushed(tester, _incident(), actions);

      await tester.tap(find.text('ยกระดับเหตุ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยกเลิก'));
      await tester.pumpAndSettle();

      expect(writes, 0);
      expect(find.text('open detail'), findsNothing);
    });

    testWidgets(
      'a rejected escalate shows a stable failure, distinct from unconfirmed',
      (tester) async {
        final actions = _controller(
          escalateIncident: (_) async => throw StateError('forbidden'),
        );
        await _pumpPushed(tester, _incident(), actions);
        await tester.tap(find.text('ยกระดับเหตุ'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'ยกระดับเหตุ'));
        await tester.pumpAndSettle();

        expect(find.text('ไม่สามารถยกระดับได้ กรุณาลองใหม่'), findsOneWidget);
        expect(find.text('open detail'), findsNothing);
      },
    );
  });

  group('close', () {
    testWidgets(
      'the chosen resolution reaches the RPC unchanged and confirms on exact match',
      (tester) async {
        var status = 'acknowledged';
        String? capturedType;
        String? capturedNote;
        final actions = _controller(
          closeIncident: (id, note, type) async {
            capturedType = type;
            capturedNote = note;
            status = type;
          },
          readStatus: (_, __) async => status,
        );
        await _pumpPushed(tester, _incident(status: 'acknowledged'), actions);

        await tester.tap(find.text('ปิดเหตุ (เสร็จสิ้น)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('แจ้งเท็จ/กดพลาด'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          ),
          'นักเรียนกดพลาด ไม่มีเหตุจริง',
        );
        // A pump between entering text and the next tap lets the text field's
        // own focus/selection settle before the dialog starts popping —
        // skipping it makes the dialog-then-page pop sequence that follows
        // race the text field's pending frame and throw a spurious
        // "duplicate GlobalKeys" overlay error unrelated to the page logic
        // under test.
        await tester.pump();
        await tester.tap(find.widgetWithText(ElevatedButton, 'ปิดเหตุ'));
        await tester.pumpAndSettle();

        expect(capturedType, 'cancelled');
        expect(capturedNote, 'นักเรียนกดพลาด ไม่มีเหตุจริง');
        expect(find.text('open detail'), findsOneWidget);
        expect(find.text('ปิดเหตุเรียบร้อยแล้ว'), findsOneWidget);
      },
    );

    testWidgets('a blank note is blocked before any write, dialog stays open', (
      tester,
    ) async {
      var writes = 0;
      final actions = _controller(
        closeIncident: (_, __, ___) async => writes++,
      );
      await _pumpPushed(tester, _incident(status: 'acknowledged'), actions);

      await tester.tap(find.text('ปิดเหตุ (เสร็จสิ้น)'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'ปิดเหตุ'));
      await tester.pumpAndSettle();

      expect(writes, 0);
      expect(
        find.text('ยืนยันปิดเหตุ'),
        findsOneWidget,
        reason: 'dialog is still open',
      );
    });

    testWidgets(
      'a failed close keeps the dialog open with the typed note retained',
      (tester) async {
        final actions = _controller(
          closeIncident: (_, __, ___) async => throw StateError('offline'),
        );
        await _pumpPushed(tester, _incident(status: 'acknowledged'), actions);

        await tester.tap(find.text('ปิดเหตุ (เสร็จสิ้น)'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          ),
          'บันทึกที่พิมพ์ไว้',
        );
        await tester.pump();
        await tester.tap(find.widgetWithText(ElevatedButton, 'ปิดเหตุ'));
        await tester.pumpAndSettle();

        expect(find.text('ยืนยันปิดเหตุ'), findsOneWidget);
        expect(find.text('บันทึกที่พิมพ์ไว้'), findsOneWidget);
        expect(find.text('ไม่สามารถปิดเหตุได้ กรุณาลองใหม่'), findsOneWidget);
      },
    );

    testWidgets(
      'an already-escalated incident hides the close action entirely — the outer terminal-state gate, not just the dialog, keeps it unreachable',
      (tester) async {
        // _close()'s own isEscalated branch (disables "แจ้งเท็จ" with an
        // explanation) can only ever run for an incident whose status
        // becomes escalated *after* the dialog is already open (a stale
        // widget.incident snapshot racing a concurrent escalation
        // elsewhere) — build()'s own isTerminal check already treats
        // 'escalated' as terminal and never renders the close button for
        // an incident that starts out escalated, which this proves.
        final actions = _controller();
        await _pumpPushed(tester, _incident(status: 'escalated'), actions);

        expect(find.text('ปิดเหตุ (เสร็จสิ้น)'), findsNothing);
        expect(
          find.textContaining('ถูกยกระดับไปยังผู้บริหารแล้ว'),
          findsOneWidget,
        );
      },
    );
  });

  group('save note', () {
    testWidgets(
      'confirms and clears the field only when the canonical read matches',
      (tester) async {
        String? saved;
        final actions = _controller(
          saveIncidentNote: (id, note) async => saved = note,
          readLatestIncidentNote: (_) async => saved,
        );
        await _pumpPushed(tester, _incident(status: 'in_progress'), actions);

        await tester.enterText(
          find.byType(TextField),
          'ตรวจสอบที่เกิดเหตุแล้ว',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'บันทึก'));
        await tester.pumpAndSettle();

        expect(saved, 'ตรวจสอบที่เกิดเหตุแล้ว');
        expect(find.text('open detail'), findsOneWidget);
        expect(find.text('บันทึกความคืบหน้าเรียบร้อยแล้ว'), findsOneWidget);
      },
    );

    testWidgets('a blank note cannot be submitted', (tester) async {
      var writes = 0;
      final actions = _controller(saveIncidentNote: (_, __) async => writes++);
      await _pumpPushed(tester, _incident(status: 'in_progress'), actions);

      await tester.tap(find.widgetWithText(ElevatedButton, 'บันทึก'));
      await tester.pumpAndSettle();

      expect(writes, 0);
      expect(
        find.text('open detail'),
        findsNothing,
        reason: 'nothing happened, page stays open',
      );
    });

    testWidgets(
      'a rejected save shows a safe error and the typed text is retained',
      (tester) async {
        final actions = _controller(
          saveIncidentNote: (_, __) async =>
              throw StateError('secret SQL detail'),
        );
        await _pumpPushed(tester, _incident(status: 'in_progress'), actions);

        await tester.enterText(find.byType(TextField), 'ข้อความที่พิมพ์ไว้');
        await tester.tap(find.widgetWithText(ElevatedButton, 'บันทึก'));
        await tester.pumpAndSettle();

        expect(find.text('ไม่สามารถบันทึกได้ กรุณาลองใหม่'), findsOneWidget);
        expect(find.textContaining('secret SQL detail'), findsNothing);
        expect(find.text('ข้อความที่พิมพ์ไว้'), findsOneWidget);
        expect(find.text('open detail'), findsNothing);
      },
    );

    testWidgets(
      'a canonical mismatch after a successful write is unconfirmed, text retained',
      (tester) async {
        final actions = _controller(
          saveIncidentNote: (_, __) async {},
          readLatestIncidentNote: (_) async => 'a different note entirely',
        );
        await _pumpPushed(tester, _incident(status: 'in_progress'), actions);

        await tester.enterText(find.byType(TextField), 'ข้อความของฉัน');
        await tester.tap(find.widgetWithText(ElevatedButton, 'บันทึก'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('ส่งคำขอแล้ว แต่ยังยืนยันการบันทึกไม่ได้'),
          findsOneWidget,
        );
        expect(find.text('ข้อความของฉัน'), findsOneWidget);
        expect(find.text('open detail'), findsNothing);
      },
    );
  });

  group('terminal state', () {
    testWidgets('a resolved incident shows no action buttons or note editor', (
      tester,
    ) async {
      final actions = _controller();
      await _pumpPushed(tester, _incident(status: 'resolved'), actions);

      expect(find.text('รับเรื่อง'), findsNothing);
      expect(find.text('ปิดเหตุ (เสร็จสิ้น)'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining('ถูกปิดหรือยกเลิกไปแล้ว'), findsOneWidget);
    });
  });
}
