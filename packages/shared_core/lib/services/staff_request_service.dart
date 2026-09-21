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

  /// teacher/school_admin: file a request (`create_staff_request`). Until
  /// 2026-09-17 nothing in the app called it — executives had a review
  /// queue that could only ever be empty. `type` ∈ meet_request ·
  /// official_duty. Returns the row as the backend stored it.
  Future<StaffRequest> create({
    required String type,
    required String subject,
    required DateTime startDate,
    DateTime? endDate,
    String? detail,
    String? location,
  }) async {
    String d(DateTime x) =>
        '${x.year.toString().padLeft(4, '0')}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
    final id =
        await _call('create_staff_request', {
              'p_request_type': type,
              'p_subject': subject.trim(),
              'p_start_date': d(startDate),
              'p_end_date': endDate == null ? null : d(endDate),
              'p_detail': detail?.trim().isEmpty ?? true ? null : detail!.trim(),
              'p_location':
                  location?.trim().isEmpty ?? true ? null : location!.trim(),
            })
            as String;
    final records = await list();
    return records.firstWhere(
      (r) => r.id == id,
      orElse: () => throw const StaffRequestUnconfirmed(),
    );
  }

  /// Requester withdraws a request that is still pending
  /// (`cancel_staff_request`); confirmed by reading it back as `cancelled`.
  Future<void> cancel(String requestId) async {
    await _call('cancel_staff_request', {'p_request_id': requestId});
    final records = await list();
    final fresh = records.firstWhere(
      (r) => r.id == requestId,
      orElse: () => throw const StaffRequestUnconfirmed(),
    );
    if (fresh.status != 'cancelled') throw const StaffRequestUnconfirmed();
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
