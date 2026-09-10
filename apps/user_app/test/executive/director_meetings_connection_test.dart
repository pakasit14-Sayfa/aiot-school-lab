import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_meetings_page.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/meeting_detail_page.dart';
import 'package:shared_core/services/meeting_service.dart';

void main() {
  testWidgets('loading, error and retry to empty are distinct', (tester) async {
    final pending = Completer<dynamic>();
    var calls = 0;
    final service = MeetingService(
      token: () => 'session',
      rpc: (_, _) {
        calls++;
        return calls == 1 ? pending.future : Future.value([]);
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DirectorMeetingsPage(service: service)),
      ),
    );
    expect(find.text('กำลังโหลดข้อมูลประชุม'), findsOneWidget);
    expect(find.text('ยังไม่มีข้อมูลประชุม'), findsNothing);
    pending.completeError(StateError('private backend diagnostic'));
    await tester.pumpAndSettle();
    expect(find.text('ไม่สามารถโหลดข้อมูลประชุมได้'), findsOneWidget);
    expect(find.textContaining('private backend diagnostic'), findsNothing);
    await tester.tap(find.text('ลองอีกครั้ง'));
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่มีข้อมูลประชุม'), findsOneWidget);
  });
  testWidgets(
    'register uses canonical numbering, minutes rules and real filters',
    (tester) async {
      final service = MeetingService(
        token: () => 'session',
        rpc: (_, _) async => [
          meetingRow(),
          {
            ...meetingRow(),
            'meeting_id': 'm2',
            'title': 'เรียกพบจริง',
            'meeting_type': 'one_on_one',
            'minutes_expected': false,
            'meeting_no': null,
          },
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DirectorMeetingsPage(service: service)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ครั้งที่ 3/2570 · นัดหมายแล้ว'), findsOneWidget);
      expect(find.text('ไม่ต้องมีบันทึก'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'เรียกพบรายบุคคล'));
      await tester.pumpAndSettle();
      expect(find.text('ประชุมจริง'), findsNothing);
      expect(find.text('เรียกพบจริง'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'ไม่พบ');
      await tester.pumpAndSettle();
      expect(find.text('ไม่พบประชุมที่ตรงกับตัวกรอง'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'minutes save stays pending and displays unconfirmed error inside modal',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final write = Completer<dynamic>();
      var writes = 0;
      final service = MeetingService(
        token: () => 'session',
        rpc: (name, p) async {
          if (name == 'save_meeting_minutes_draft') {
            writes++;
            return write.future;
          }
          return detailRow();
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MeetingDetailPage(service: service, meetingId: 'm1'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('บันทึกฉบับร่าง'));
      await tester.tap(find.text('บันทึกฉบับร่าง'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'รายงานที่ต้องยืนยัน');
      await tester.tap(find.widgetWithText(FilledButton, 'บันทึก'));
      await tester.pump();
      expect(writes, 1);
      expect(find.text('กำลังบันทึกและตรวจสอบ'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'กำลังบันทึกและตรวจสอบ'),
            )
            .onPressed,
        isNull,
      );
      write.complete(null);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(
            'ยังยืนยันผลบันทึกไม่ได้ กรุณาโหลดข้อมูลใหม่และตรวจสอบก่อนทำซ้ำ',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('บันทึกและตรวจสอบข้อมูลแล้ว'), findsNothing);
    },
  );
  testWidgets(
    'final minutes remain readable and editable only through addenda',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final row = detailRow();
      row['meeting'] = {...meetingRow(), 'minutes_status': 'final'};
      row['minutes'] = {
        'body': 'รายงานที่ปิดแล้ว',
        'status': 'final',
        'can_add_addendum': true,
      };
      final service = MeetingService(
        token: () => 'session',
        rpc: (_, _) async => row,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MeetingDetailPage(service: service, meetingId: 'm1'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('รายงานที่ปิดแล้ว'), findsOneWidget);
      expect(find.text('บันทึกฉบับร่าง'), findsNothing);
      expect(find.text('ปิดบันทึก'), findsNothing);
      expect(find.text('เพิ่มคำชี้แจง / บันทึกเพิ่มเติม'), findsOneWidget);
    },
  );
  testWidgets('signed out page never displays fabricated meetings', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DirectorMeetingsPage())),
    );
    await tester.pumpAndSettle();
    expect(find.text('ประชุมฝ่ายบริหารประจำสัปดาห์'), findsNothing);
    expect(find.text('กรุณาเข้าสู่ระบบ'), findsOneWidget);
  });
}

Map<String, dynamic> meetingRow() => {
  'meeting_id': 'm1',
  'title': 'ประชุมจริง',
  'meeting_type': 'group',
  'status': 'scheduled',
  'start_at': '2027-03-10T00:00:00Z',
  'minutes_expected': true,
  'attendee_count': 2,
  'accepted_count': 1,
  'pending_count': 1,
  'can_manage': true,
  'meeting_no': 3,
  'meeting_year': 2570,
};
Map<String, dynamic> detailRow() => {
  'meeting': meetingRow(),
  'attendees': [
    {
      'user_id': 'p1',
      'full_name': 'ผู้จัด',
      'attended': null,
      'is_organizer': true,
    },
    {'user_id': 'p2', 'full_name': 'ผู้ร่วม', 'attended': null},
  ],
  'external_attendees': [],
  'agenda': [],
  'minutes': null,
  'addenda': [],
  'resolutions': [],
  'attachments': [],
  'can_upload': true,
  'my_user_id': 'p1',
};
