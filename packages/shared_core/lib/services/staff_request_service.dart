import '../models/staff_request_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

typedef StaffRequestRpc =
    Future<dynamic> Function(String, Map<String, dynamic>);

class StaffRequestService {
  StaffRequestService({StaffRequestRpc? rpc, String? Function()? token})
    : _rpc = rpc ?? ((name, p) async => await supabase.rpc(name, params: p)),
      _token = token ?? (() => AuthService.sessionToken);
  final StaffRequestRpc _rpc;
  final String? Function() _token;
  Future<dynamic> _call(String name, Map<String, dynamic> parameters) {
    final token = _token();
    if (token == null) throw StateError('invalid_session');
    return _rpc(name, {'p_token': token, ...parameters});
  }

  Future<List<StaffRequest>> list({bool pendingForMe = false}) async {
    final rows =
        await _call('list_staff_requests', {'p_pending_for_me': pendingForMe})
            as List;
    return rows
        .map((r) => StaffRequest.fromRow(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<StaffRequest> review(
    StaffRequest request,
    bool approve,
    String note,
  ) async {
    await _call('review_staff_request', {
      'p_request_id': request.id,
      'p_approve': approve,
      'p_note': note.trim(),
    });
    try {
      final expected = approve
          ? (request.status == 'pending_head'
                ? 'pending_executive'
                : 'approved')
          : 'rejected';
      final records = await list();
      final fresh = records.firstWhere((r) => r.id == request.id);
      final decision = request.status == 'pending_head'
          ? fresh.headDecision
          : fresh.execDecision;
      final savedNote = request.status == 'pending_head'
          ? fresh.headNote
          : fresh.execNote;
      if (fresh.status != expected ||
          decision != (approve ? 'approved' : 'rejected') ||
          (savedNote ?? '') != note.trim()) {
        throw const StaffRequestUnconfirmed();
      }
      return fresh;
    } catch (_) {
      throw const StaffRequestUnconfirmed();
    }
  }
}
