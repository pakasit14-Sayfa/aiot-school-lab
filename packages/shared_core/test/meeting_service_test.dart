import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/models/meeting_model.dart';
import 'package:shared_core/services/meeting_service.dart';

void main() {
  test('declining a group without a note confirms SQL null as empty', () async {
    final row = detailRow();
    (row['attendees'] as List)[0]['response'] = 'declined';
    final service = MeetingService(
      token: () => 'session',
      rpc: (name, p) async {
        if (name == 'respond_to_meeting') return null;
        return row;
      },
    );
    expect(
      (await service.respond(
        'm1',
        'declined',
        note: ' ',
      )).people.first.response,
      'declined',
    );
  });
  test(
    'creation sends and verifies visibility required by meeting type',
    () async {
      var returnedVisibility = 'school';
      final service = MeetingService(
        token: () => 'session',
        rpc: (name, p) async {
          if (name == 'create_meeting') {
            expect(p['p_visibility'], 'school');
            return 'm1';
          }
          final row = detailRow();
          (row['meeting'] as Map)['meeting_type'] = 'school_wide';
          (row['meeting'] as Map)['visibility'] = returnedVisibility;
          return row;
        },
      );
      final draft = MeetingDraft(
        title: 'ประชุมจริง',
        type: 'school_wide',
        startAt: DateTime.utc(2027, 3, 10),
      );
      expect((await service.detail('m1')).meeting.visibility, 'school');
      expect((await service.create(draft)).meeting.visibility, 'school');
      returnedVisibility = 'attendees';
      await expectLater(
        service.create(draft),
        throwsA(isA<MeetingUnconfirmed>()),
      );
      expect(
        MeetingDraft(
          title: 'เรียกพบ',
          type: 'one_on_one',
          startAt: DateTime(2027),
          visibility: 'school',
        ).toParameters()['p_visibility'],
        'attendees',
      );
    },
  );
  test(
    'confirmed attendance includes selected, absent and attendance timestamp',
    () async {
      final row = detailRow();
      (row['meeting'] as Map)['attendance_taken_at'] = '2027-03-10T02:00:00Z';
      (row['attendees'] as List)[1]['attended'] = false;
      final service = MeetingService(
        token: () => 'session',
        rpc: (name, p) async {
          if (name == 'set_meeting_attendance') {
            expect(p['p_present_user_ids'], ['p1']);
            expect(p['p_present_external_ids'], isEmpty);
            return null;
          }
          return row;
        },
      );
      final fresh = await service.takeAttendance('m1', ['p1'], []);
      expect(fresh.people.last.attended, isFalse);
    },
  );
  test(
    'saved draft is confirmed by exact body and finalization by immutable body',
    () async {
      var finalised = false;
      final service = MeetingService(
        token: () => 'session',
        rpc: (name, p) async {
          if (name == 'save_meeting_minutes_draft') {
            expect(p['p_body'], 'canonical minutes');
            return null;
          }
          if (name == 'finalize_meeting_minutes') {
            finalised = true;
            return null;
          }
          return {
            ...detailRow(),
            'minutes': {
              'body': 'canonical minutes',
              'status': finalised ? 'final' : 'draft',
              'can_add_addendum': finalised,
            },
          };
        },
      );
      expect(
        (await service.saveMinutes(
          'm1',
          ' canonical minutes ',
        )).minutes!.status,
        'draft',
      );
      expect(
        (await service.finalizeMinutes(
          'm1',
          'canonical minutes',
        )).minutes!.status,
        'final',
      );
    },
  );
  test(
    'write followed by unavailable read is unconfirmed, never success',
    () async {
      final service = MeetingService(
        token: () => 'session',
        rpc: (name, p) async {
          if (name == 'save_meeting_minutes_draft') return null;
          throw StateError('network read unavailable');
        },
      );
      await expectLater(
        service.saveMinutes('m1', 'saved text'),
        throwsA(isA<MeetingUnconfirmed>()),
      );
    },
  );
  test(
    'resolution confirms assignee and calendar date without converting to a timestamp',
    () async {
      final service = MeetingService(
        token: () => 'session',
        rpc: (name, p) async {
          if (name == 'create_meeting_resolution') return 'r1';
          return {
            ...detailRow(),
            'resolutions': [
              {
                'resolution_id': 'r1',
                'body': 'action',
                'status': 'open',
                'assignee_user_id': 'p2',
                'due_date': '2027-03-12',
              },
            ],
          };
        },
      );
      final result = await service.addResolution(
        'm1',
        'action',
        assigneeId: 'p2',
        dueDate: '2027-03-12',
      );
      expect(result.resolutions.single.assigneeId, 'p2');
    },
  );
  test(
    'attendance cannot report success if absent people are still unchecked',
    () async {
      final service = MeetingService(
        token: () => 'session',
        rpc: (name, p) async {
          if (name == 'set_meeting_attendance') return null;
          return detailRow();
        },
      );
      await expectLater(
        service.takeAttendance('m1', ['p1'], []),
        throwsA(isA<MeetingUnconfirmed>()),
      );
    },
  );
  test(
    'creation remains unconfirmed when canonical record is absent',
    () async {
      final service = MeetingService(
        token: () => 'session',
        rpc: (name, p) async {
          expect(p['p_token'], 'session');
          if (name == 'create_meeting') return 'new-id';
          return <dynamic>[];
        },
      );
      await expectLater(
        service.create(
          MeetingDraft(
            title: 'ประชุมจริง',
            type: 'group',
            startAt: DateTime(2027, 3, 10),
            userIds: ['teacher'],
          ),
        ),
        throwsA(isA<MeetingUnconfirmed>()),
      );
    },
  );
}

Map<String, dynamic> detailRow() => {
  'meeting': <String, dynamic>{
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
  },
  'attendees': [
    <String, dynamic>{
      'user_id': 'p1',
      'full_name': 'ผู้จัด',
      'attended': true,
      'is_organizer': true,
    },
    <String, dynamic>{
      'user_id': 'p2',
      'full_name': 'ผู้ร่วม',
      'attended': null,
    },
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
