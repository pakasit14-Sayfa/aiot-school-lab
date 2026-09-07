import 'dart:typed_data';

import '../models/school_report_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// ทะเบียนรายงาน — metadata through RPCs, bytes through the private
/// `school-reports` bucket mediated by the school-report-upload /
/// school-report-download Edge Functions (signed URLs), per hard rule 3.
///
/// Backed by `20260907020000_school_report_register.sql`.
class SchoolReportService {
  static Future<List<SchoolReport>> listReports({
    String? status,
    String? reportType,
    String? fileType,
    String? departmentId,
    DateTime? from,
    DateTime? to,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc(
              'list_school_reports',
              params: {
                'p_token': token,
                'p_status': status,
                'p_report_type': reportType,
                'p_file_type': fileType,
                'p_department_id': departmentId,
                'p_from': from == null ? null : _date(from),
                'p_to': to == null ? null : _date(to),
              },
            )
            as List;
    return rows
        .map(
          (row) => SchoolReport.fromRow(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  /// Null when there is no session. Never a zeroed summary — the caller must
  /// be able to tell "nothing filed" from "could not read".
  static Future<SchoolReportSummary?> getSummary() async {
    final token = AuthService.sessionToken;
    if (token == null) return null;
    final rows =
        await supabase.rpc(
              'get_school_report_summary',
              params: {'p_token': token},
            )
            as List;
    if (rows.isEmpty) return null;
    return SchoolReportSummary.fromRow(
      Map<String, dynamic>.from(rows.first as Map),
    );
  }

  static Future<List<ReportRequirement>> listRequirements({
    bool onlyOpen = false,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc(
              'list_report_requirements',
              params: {'p_token': token, 'p_only_open': onlyOpen},
            )
            as List;
    return rows
        .map(
          (row) =>
              ReportRequirement.fromRow(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  /// Uploads the bytes, then records the metadata, then re-reads the register
  /// to confirm the row is really there before reporting success. Returns the
  /// new report's id.
  ///
  /// The storage path is chosen by the Edge Function from the session's
  /// school, not by this client.
  static Future<String> submitReport({
    required String title,
    required String reportType,
    required String fileName,
    required Uint8List bytes,
    String? departmentId,
    String? requirementId,
    String? description,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');

    final uploadResponse = await supabase.functions.invoke(
      'school-report-upload',
      body: {
        'token': token,
        'department_id': departmentId,
        'file_name': fileName,
      },
    );
    final uploadData = uploadResponse.data as Map<String, dynamic>?;
    final storagePath = uploadData?['storage_path'] as String?;
    final signedToken = uploadData?['token'] as String?;
    if (storagePath == null || signedToken == null) {
      throw StateError('upload_url_unavailable');
    }

    await supabase.storage
        .from('school-reports')
        .uploadBinaryToSignedUrl(storagePath, signedToken, bytes);

    final res = await supabase.rpc(
      'register_school_report',
      params: {
        'p_token': token,
        'p_title': title.trim(),
        'p_report_type': reportType,
        'p_storage_path': storagePath,
        'p_file_name': fileName,
        'p_size_bytes': bytes.length,
        'p_department_id': departmentId,
        'p_requirement_id': requirementId,
        'p_description': description?.trim(),
        'p_period_start': periodStart == null ? null : _date(periodStart),
        'p_period_end': periodEnd == null ? null : _date(periodEnd),
      },
    );
    final id = res?.toString() ?? '';
    if (id.isEmpty || id.toLowerCase() == 'null') {
      throw StateError('backend_report_id_missing');
    }

    // Read the canonical list back: a signed upload that succeeded and a row
    // that exists are two different facts, and only the second one means the
    // report was filed.
    final confirmed = await listReports();
    if (!confirmed.any((r) => r.reportId == id)) {
      throw StateError('backend_report_not_confirmed');
    }
    return id;
  }

  /// A short-lived signed URL. Access is re-checked on every call, so a URL
  /// handed out earlier does not keep working for someone who lost access.
  static Future<String> getDownloadUrl(String reportId) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final response = await supabase.functions.invoke(
      'school-report-download',
      body: {'token': token, 'report_id': reportId},
    );
    final data = response.data as Map<String, dynamic>?;
    final signedUrl = data?['signed_url'] as String?;
    if (signedUrl == null) {
      throw StateError('download_url_unavailable');
    }
    return signedUrl;
  }

  /// [status] is `under_review`, `approved` or `needs_revision`. A
  /// `needs_revision` without a note is refused by the backend.
  static Future<void> reviewReport({
    required String reportId,
    required String status,
    String? note,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'review_school_report',
      params: {
        'p_token': token,
        'p_report_id': reportId,
        'p_status': status,
        'p_note': note?.trim(),
      },
    );
  }

  /// Removes the row, then the object it pointed at. If the object delete
  /// fails the row is still gone — an orphaned file is better than a row
  /// pointing at bytes that are not there.
  static Future<void> deleteReport(String reportId) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final storagePath = await supabase.rpc(
      'delete_school_report',
      params: {'p_token': token, 'p_report_id': reportId},
    );
    final path = storagePath?.toString();
    if (path != null && path.isNotEmpty && path.toLowerCase() != 'null') {
      await supabase.storage.from('school-reports').remove([path]);
    }
  }

  static Future<String> createRequirement({
    required String title,
    required String reportType,
    required List<String> departmentIds,
    DateTime? dueDate,
    String? description,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final res = await supabase.rpc(
      'create_report_requirement',
      params: {
        'p_token': token,
        'p_title': title.trim(),
        'p_report_type': reportType,
        'p_department_ids': departmentIds,
        'p_due_date': dueDate == null ? null : _date(dueDate),
        'p_description': description?.trim(),
        'p_period_start': periodStart == null ? null : _date(periodStart),
        'p_period_end': periodEnd == null ? null : _date(periodEnd),
      },
    );
    final id = res?.toString() ?? '';
    if (id.isEmpty || id.toLowerCase() == 'null') {
      throw StateError('backend_requirement_id_missing');
    }
    return id;
  }

  static Future<void> closeRequirement(String requirementId) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'close_report_requirement',
      params: {'p_token': token, 'p_requirement_id': requirementId},
    );
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
