import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/models/staff_request_model.dart';
import 'package:shared_core/services/staff_request_service.dart';

Map<String, dynamic> requestRow(String status) => {
  'request_id': 'r1',
  'requester_id': 'teacher',
  'requester_name': 'ครู',
  'request_type': 'meet_request',
  'subject': 'ขอเข้าพบ',
  'start_date': '2027-03-10',
  'status': status,
};
void main() {
  test(
    'head approval confirms only the transition to executive review',
    () async {
      final service = StaffRequestService(
        token: () => 'session',
        rpc: (name, p) async {
          if (name == 'review_staff_request') return null;
          return [
            {
              ...requestRow('pending_executive'),
              'head_decision': 'approved',
              'head_note': 'ผ่าน',
            },
          ];
        },
      );
      final result = await service.review(
        StaffRequest.fromRow(requestRow('pending_head')),
        true,
        'ผ่าน',
      );
      expect(result.status, 'pending_executive');
    },
  );
  test('stale pending request is not a confirmed executive approval', () async {
    final service = StaffRequestService(
      token: () => 'session',
      rpc: (name, p) async {
        if (name == 'review_staff_request') return null;
        return [requestRow('pending_executive')];
      },
    );
    await expectLater(
      service.review(
        StaffRequest.fromRow(requestRow('pending_executive')),
        true,
        '',
      ),
      throwsA(isA<StaffRequestUnconfirmed>()),
    );
  });
}
