class MeetingRecord {
  MeetingRecord.fromRow(Map<String, dynamic> row)
    : id = row['meeting_id'] as String,
      title = row['title'] as String,
      type = row['meeting_type'] as String,
      status = row['status'] as String,
      startAt = DateTime.parse(row['start_at'] as String).toLocal(),
      endAt = DateTime.tryParse(row['end_at']?.toString() ?? '')?.toLocal(),
      location = row['location'] as String?,
      description = row['description'] as String?,
      organizer = row['organizer_name'] as String?,
      minutesExpected = row['minutes_expected'] as bool,
      minutesStatus = row['minutes_status'] as String?,
      number = (row['meeting_no'] as num?)?.toInt(),
      year = (row['meeting_year'] as num?)?.toInt(),
      attendanceTakenAt = DateTime.tryParse(
        row['attendance_taken_at']?.toString() ?? '',
      ),
      attendeeCount = (row['attendee_count'] as num).toInt(),
      acceptedCount = (row['accepted_count'] as num).toInt(),
      pendingCount = (row['pending_count'] as num).toInt(),
      canManage = row['can_manage'] == true,
      myResponse = row['my_response'] as String?,
      visibility = row['visibility'] as String?;
  final String id, title, type, status;
  final DateTime startAt;
  final DateTime? endAt, attendanceTakenAt;
  final String? location,
      description,
      organizer,
      minutesStatus,
      myResponse,
      visibility;
  final bool minutesExpected, canManage;
  final int? number, year;
  final int attendeeCount, acceptedCount, pendingCount;
  bool get isPrivate => type == 'one_on_one';
  String get numberLabel => isPrivate
      ? 'เรียกพบรายบุคคล'
      : number == null
      ? 'ยังไม่มีเลขที่'
      : 'ครั้งที่ $number/$year';
  String get minutesLabel => !minutesExpected
      ? 'ไม่ต้องมีบันทึก'
      : switch (minutesStatus) {
          'final' => 'ปิดบันทึกแล้ว',
          'draft' => 'บันทึกฉบับร่าง',
          _ => 'ยังไม่ได้บันทึก',
        };
}

/// A write may have committed even when the following canonical read fails.
class MeetingUnconfirmed implements Exception {
  const MeetingUnconfirmed();
}

class MeetingNotSignedIn implements Exception {
  const MeetingNotSignedIn();
}

List<Map<String, dynamic>> meetingRows(dynamic value) => (value as List)
    .map((row) => Map<String, dynamic>.from(row as Map))
    .toList();

class MeetingPerson {
  MeetingPerson.fromRow(Map<String, dynamic> r, {this.external = false})
    : id = (r[external ? 'external_id' : 'user_id']) as String,
      name = r['full_name'] as String,
      organization = r['organization'] as String?,
      response = r['response'] as String?,
      note = (r['response_note'] ?? r['note']) as String?,
      attended = r['attended'] as bool?,
      organizer = r['is_organizer'] == true;
  final String id, name;
  final String? organization, response, note;
  final bool? attended;
  final bool external, organizer;
}

class MeetingAgenda {
  MeetingAgenda.fromRow(Map<String, dynamic> r)
    : id = r['item_id'] as String,
      title = r['title'] as String,
      detail = r['detail'] as String?,
      presenterId = r['presenter_user_id'] as String?,
      presenter = r['presenter_name'] as String?,
      order = (r['sort_order'] as num).toInt();
  final String id, title;
  final String? detail, presenterId, presenter;
  final int order;
}

class MeetingMinutes {
  MeetingMinutes.fromRow(Map<String, dynamic> r)
    : body = r['body'] as String,
      status = r['status'] as String,
      recorder = r['recorder_name'] as String?,
      canAppend = r['can_add_addendum'] == true,
      cancelledAt = DateTime.tryParse(r['cancelled_at']?.toString() ?? ''),
      cancelReason = r['cancel_reason'] as String?,
      finalizedAt = DateTime.tryParse(r['finalized_at']?.toString() ?? '');
  final String body, status;
  final String? recorder, cancelReason;
  final DateTime? finalizedAt, cancelledAt;
  final bool canAppend;
}

class MeetingAddendum {
  MeetingAddendum.fromRow(Map<String, dynamic> r)
    : id = r['addendum_id'] as String,
      body = r['body'] as String,
      author = r['author_name'] as String?,
      kind = r['author_kind'] as String,
      createdAt = DateTime.parse(r['created_at'] as String);
  final String id, body, kind;
  final String? author;
  final DateTime createdAt;
}

class MeetingResolution {
  MeetingResolution.fromRow(Map<String, dynamic> r)
    : id = r['resolution_id'] as String,
      body = r['body'] as String,
      status = r['status'] as String,
      assigneeId = r['assignee_user_id'] as String?,
      assignee = r['assignee_name'] as String?,
      dueDate = DateTime.tryParse(r['due_date']?.toString() ?? '');
  final String id, body, status;
  final String? assigneeId, assignee;
  final DateTime? dueDate;
}

class MeetingAttachment {
  MeetingAttachment.fromRow(Map<String, dynamic> r)
    : id = r['attachment_id'] as String,
      name = r['file_name'] as String,
      type = r['file_type'] as String,
      size = (r['size_bytes'] as num).toInt();
  final String id, name, type;
  final int size;
}

class MeetingDetail {
  MeetingDetail.fromRow(Map<String, dynamic> r)
    : meeting = MeetingRecord.fromRow(
        Map<String, dynamic>.from(r['meeting'] as Map),
      ),
      people = meetingRows(
        r['attendees'],
      ).map((r) => MeetingPerson.fromRow(r)).toList(),
      guests = meetingRows(
        r['external_attendees'],
      ).map((r) => MeetingPerson.fromRow(r, external: true)).toList(),
      agenda = meetingRows(r['agenda']).map(MeetingAgenda.fromRow).toList(),
      minutes = r['minutes'] == null
          ? null
          : MeetingMinutes.fromRow(
              Map<String, dynamic>.from(r['minutes'] as Map),
            ),
      addenda = meetingRows(r['addenda']).map(MeetingAddendum.fromRow).toList(),
      resolutions = meetingRows(
        r['resolutions'],
      ).map(MeetingResolution.fromRow).toList(),
      attachments = meetingRows(
        r['attachments'],
      ).map(MeetingAttachment.fromRow).toList(),
      canUpload = r['can_upload'] == true,
      myUserId = r['my_user_id'] as String;
  final MeetingRecord meeting;
  final List<MeetingPerson> people, guests;
  final List<MeetingAgenda> agenda;
  final MeetingMinutes? minutes;
  final List<MeetingAddendum> addenda;
  final List<MeetingResolution> resolutions;
  final List<MeetingAttachment> attachments;
  final bool canUpload;
  final String myUserId;
}

class MeetingDraft {
  const MeetingDraft({
    required this.title,
    required this.type,
    required this.startAt,
    this.endAt,
    this.location,
    this.description,
    this.visibility = 'attendees',
    this.minutesExpected = true,
    this.userIds = const [],
    this.departmentIds = const [],
  });
  final String title, type, visibility;
  final DateTime startAt;
  final DateTime? endAt;
  final String? location, description;
  final bool minutesExpected;
  final List<String> userIds, departmentIds;
  String get effectiveVisibility => switch (type) {
    'one_on_one' => 'attendees',
    'school_wide' => 'school',
    _ => visibility,
  };
  Map<String, dynamic> toParameters() => {
    'p_title': title.trim(),
    'p_meeting_type': type,
    'p_start_at': startAt.toUtc().toIso8601String(),
    'p_end_at': endAt?.toUtc().toIso8601String(),
    'p_location': location?.trim(),
    'p_description': description?.trim(),
    'p_visibility': effectiveVisibility,
    'p_minutes_expected': minutesExpected,
    'p_user_ids': userIds,
    'p_department_ids': departmentIds,
  };
}

class MeetingCalendarEntry {
  MeetingCalendarEntry.fromRow(Map<String, dynamic> r)
    : id = r['entry_id'] as String,
      title = r['title'] as String,
      kind = r['kind'] as String,
      status = r['status'] as String,
      startAt = DateTime.parse(r['start_at'] as String).toLocal();
  final String id, title, kind, status;
  final DateTime startAt;
}
