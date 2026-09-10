import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/widgets/meeting_document.dart';
import 'package:shared_core/models/meeting_model.dart';

void main() {
  test(
    'printable document escapes authored text and retains minutes and addenda separately',
    () {
      final detail = MeetingDetail.fromRow({
        'meeting': {
          'meeting_id': 'm1',
          'title': '<script>alert(1)</script>',
          'meeting_type': 'one_on_one',
          'status': 'scheduled',
          'start_at': '2026-09-10T02:00:00Z',
          'minutes_expected': true,
          'minutes_status': 'final',
          'attendee_count': 0,
          'accepted_count': 0,
          'pending_count': 0,
        },
        'attendees': [],
        'external_attendees': [],
        'agenda': [],
        'resolutions': [],
        'attachments': [],
        'minutes': {
          'body': 'original <img src=x onerror=alert(2)>',
          'status': 'final',
        },
        'addenda': [
          {
            'addendum_id': 'a1',
            'body': 'appended & separate',
            'author_kind': 'attendee',
            'author_name': 'reader',
            'created_at': '2026-09-08T05:00:00Z',
          },
        ],
        'can_upload': false,
        'my_user_id': 'reader',
      });
      final html = meetingDocument(detail);
      expect(html, contains('เอกสารลับ'));
      expect(html, contains('ปิดบันทึกแล้ว'));
      expect(html, contains('&lt;script&gt;'));
      expect(html, isNot(contains('<script>')));
      expect(html, contains('original &lt;img'));
      expect(html, isNot(contains('<img ')));
      expect(html, contains('appended &amp; separate'));
    },
  );
}
