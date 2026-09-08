import 'dart:typed_data';
import '../models/meeting_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

typedef MeetingRpc =
    Future<dynamic> Function(String name, Map<String, dynamic> parameters);

class MeetingService {
  MeetingService({MeetingRpc? rpc, String? Function()? token})
    : _rpc =
          rpc ??
          ((name, parameters) async =>
              await supabase.rpc(name, params: parameters)),
      _token = token ?? (() => AuthService.sessionToken);
  final MeetingRpc _rpc;
  final String? Function() _token;

  Future<dynamic> _call(
    String name, [
    Map<String, dynamic> parameters = const {},
  ]) async {
    final token = _token();
    if (token == null) throw const MeetingNotSignedIn();
    return _rpc(name, {'p_token': token, ...parameters});
  }

  Future<List<MeetingRecord>> list() async {
    final rows = await _call('list_meeting_records') as List;
    return rows
        .map(
          (row) => MeetingRecord.fromRow(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<MeetingDetail> detail(String id) async => MeetingDetail.fromRow(
    Map<String, dynamic>.from(
      await _call('get_meeting_detail', {'p_meeting_id': id}) as Map,
    ),
  );

  Future<MeetingDetail> _write(
    String name,
    Map<String, dynamic> parameters,
    String meetingId,
    bool Function(MeetingDetail, dynamic) confirmed,
  ) async {
    final result = await _call(name, parameters);
    try {
      final fresh = await detail(meetingId);
      if (fresh.meeting.id != meetingId || !confirmed(fresh, result)) {
        throw const MeetingUnconfirmed();
      }
      return fresh;
    } catch (_) {
      throw const MeetingUnconfirmed();
    }
  }

  Future<MeetingDetail> takeAttendance(
    String id,
    List<String> presentUsers,
    List<String> presentGuests,
  ) => _write(
    'set_meeting_attendance',
    {
      'p_meeting_id': id,
      'p_present_user_ids': presentUsers,
      'p_present_external_ids': presentGuests,
    },
    id,
    (d, _) =>
        d.meeting.attendanceTakenAt != null &&
        d.people.every((p) => p.attended == presentUsers.contains(p.id)) &&
        d.guests.every((p) => p.attended == presentGuests.contains(p.id)) &&
        presentUsers.every((id) => d.people.any((p) => p.id == id)) &&
        presentGuests.every((id) => d.guests.any((p) => p.id == id)),
  );

  Future<MeetingDetail> respond(String id, String response, {String? note}) =>
      _write(
        'respond_to_meeting',
        {'p_meeting_id': id, 'p_response': response, 'p_note': note?.trim()},
        id,
        (d, _) => d.people.any(
          (p) =>
              p.id == d.myUserId &&
              p.response == response &&
              (p.note ?? '') == (note?.trim() ?? ''),
        ),
      );

  Future<MeetingDetail> cancel(String id, String reason) => _write(
    'cancel_meeting',
    {'p_meeting_id': id, 'p_reason': reason.trim()},
    id,
    (d, _) => d.meeting.status == 'cancelled',
  );

  Future<MeetingDetail> complete(String id) => _write(
    'complete_meeting',
    {'p_meeting_id': id},
    id,
    (d, _) => d.meeting.status == 'completed',
  );

  Future<MeetingDetail> saveAgenda(
    String id,
    String title, {
    String? itemId,
    String? detail,
    String? presenterId,
    int order = 0,
  }) => _write(
    'set_meeting_agenda_item',
    {
      'p_meeting_id': id,
      'p_item_id': itemId,
      'p_title': title.trim(),
      'p_detail': detail?.trim(),
      'p_presenter_user_id': presenterId,
      'p_sort_order': order,
    },
    id,
    (d, result) => d.agenda.any(
      (a) =>
          a.id == result &&
          a.title == title.trim() &&
          a.order == order &&
          a.presenterId == presenterId &&
          (a.detail ?? '') == (detail?.trim() ?? ''),
    ),
  );

  Future<MeetingDetail> deleteAgenda(String id, String itemId) => _write(
    'delete_meeting_agenda_item',
    {'p_item_id': itemId},
    id,
    (d, _) => !d.agenda.any((a) => a.id == itemId),
  );

  Future<MeetingDetail> saveMinutes(String id, String body) => _write(
    'save_meeting_minutes_draft',
    {'p_meeting_id': id, 'p_body': body.trim()},
    id,
    (d, _) => d.minutes?.status == 'draft' && d.minutes?.body == body.trim(),
  );

  Future<MeetingDetail> finalizeMinutes(String id, String expectedBody) =>
      _write(
        'finalize_meeting_minutes',
        {'p_meeting_id': id},
        id,
        (d, _) =>
            d.minutes?.status == 'final' && d.minutes?.body == expectedBody,
      );

  Future<MeetingDetail> addAddendum(String id, String body) => _write(
    'add_meeting_minute_addendum',
    {'p_meeting_id': id, 'p_body': body.trim()},
    id,
    (d, result) =>
        d.addenda.any((a) => a.id == result && a.body == body.trim()),
  );

  Future<MeetingDetail> addResolution(
    String id,
    String body, {
    String? assigneeId,
    String? dueDate,
  }) => _write(
    'create_meeting_resolution',
    {
      'p_meeting_id': id,
      'p_body': body.trim(),
      'p_assignee_user_id': assigneeId,
      'p_due_date': dueDate,
    },
    id,
    (d, result) => d.resolutions.any(
      (r) =>
          r.id == result &&
          r.body == body.trim() &&
          r.assigneeId == assigneeId &&
          r.dueDate?.toIso8601String().substring(0, 10) == dueDate &&
          r.status == 'open',
    ),
  );

  Future<MeetingDetail> setResolutionStatus(
    String id,
    String resolutionId,
    String status,
  ) => _write(
    'set_meeting_resolution_status',
    {'p_resolution_id': resolutionId, 'p_status': status},
    id,
    (d, _) =>
        d.resolutions.any((r) => r.id == resolutionId && r.status == status),
  );

  Future<MeetingDetail> addGuest(
    String id,
    String name, {
    String? organization,
  }) => _write(
    'add_meeting_external_attendee',
    {
      'p_meeting_id': id,
      'p_full_name': name.trim(),
      'p_organization': organization?.trim(),
    },
    id,
    (d, result) => d.guests.any(
      (g) =>
          g.id == result &&
          g.name == name.trim() &&
          (g.organization ?? '') == (organization?.trim() ?? ''),
    ),
  );

  Future<MeetingDetail> removeGuest(String id, String guestId) => _write(
    'remove_meeting_external_attendee',
    {'p_external_id': guestId},
    id,
    (d, _) => !d.guests.any((g) => g.id == guestId),
  );

  Future<MeetingDetail> attach(
    String id,
    String fileName,
    Uint8List bytes,
  ) async {
    final token = _token();
    if (token == null) throw const MeetingNotSignedIn();
    final response = await supabase.functions.invoke(
      'meeting-file-upload',
      body: {'token': token, 'meeting_id': id, 'file_name': fileName},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final path = data['storage_path'] as String;
    await supabase.storage
        .from('meeting-files')
        .uploadBinaryToSignedUrl(path, data['token'] as String, bytes);
    return _write(
      'register_meeting_attachment',
      {
        'p_meeting_id': id,
        'p_storage_path': path,
        'p_file_name': fileName,
        'p_size_bytes': bytes.length,
      },
      id,
      (d, result) => d.attachments.any(
        (a) => a.id == result && a.name == fileName && a.size == bytes.length,
      ),
    );
  }

  Future<Uri> download(String attachmentId) async {
    final token = _token();
    if (token == null) throw const MeetingNotSignedIn();
    final response = await supabase.functions.invoke(
      'meeting-file-download',
      body: {'token': token, 'attachment_id': attachmentId},
    );
    return Uri.parse((response.data as Map)['signed_url'] as String);
  }

  Future<List<MeetingCalendarEntry>> calendar() async => meetingRows(
    await _call('list_staff_calendar'),
  ).map(MeetingCalendarEntry.fromRow).toList();

  Future<MeetingDetail> create(MeetingDraft draft) async {
    final id = await _call('create_meeting', draft.toParameters());
    try {
      final result = await detail(id as String);
      final m = result.meeting;
      if (m.id != id ||
          m.title != draft.title.trim() ||
          m.type != draft.type ||
          m.visibility != draft.effectiveVisibility ||
          !m.startAt.isAtSameMomentAs(draft.startAt) ||
          m.minutesExpected != draft.minutesExpected ||
          !draft.userIds.every((id) => result.people.any((p) => p.id == id))) {
        throw const MeetingUnconfirmed();
      }
      return result;
    } catch (_) {
      throw const MeetingUnconfirmed();
    }
  }
}
