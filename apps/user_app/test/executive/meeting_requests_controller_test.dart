import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/controllers/meeting_requests_controller.dart';
import 'package:shared_core/models/staff_request_model.dart';
import 'package:shared_core/services/staff_request_service.dart';

Map<String, dynamic> request(String status) => {
  'request_id': 'r1',
  'requester_id': 'teacher',
  'requester_name': 'ครู',
  'request_type': 'meet_request',
  'subject': 'ขอเข้าพบ',
  'start_date': '2027-03-10',
  'status': status,
  if (status == 'approved') 'exec_decision': 'approved',
};
void main() {
  test('an older load cannot replace a confirmed approval', () async {
    var calls = 0;
    final oldLoad = Completer<dynamic>();
    final service = StaffRequestService(
      token: () => 'session',
      rpc: (name, p) async {
        if (name == 'review_staff_request') return null;
        calls++;
        if (calls <= 2) return [request('pending_executive')];
        if (calls <= 4) return oldLoad.future;
        return [request('approved')];
      },
    );
    final controller = MeetingRequestsController(service: service);
    addTearDown(controller.dispose);
    await controller.load();
    final refresh = controller.load();
    await controller.review(
      StaffRequest.fromRow(request('pending_executive')),
      true,
      '',
    );
    oldLoad.complete([request('pending_executive')]);
    await refresh;
    expect(controller.records.single.status, 'approved');
    expect(controller.actionable, isEmpty);
  });
}
