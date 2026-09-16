import '../models/teacher_workload_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// Substitute-teacher coverage (`record_class_substitution`,
/// `list_periods_needing_substitute`) and self-logged prep blocks
/// (`log_staff_prep_block`). RPCs from
/// `20260910160000_teacher_workload_categories.sql`.
class ClassSubstitutionService {
  static Future<List<PeriodNeedingSubstitute>> listPeriodsNeedingSubstitute(
    DateTime date,
  ) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc(
              'list_periods_needing_substitute',
              params: {
                'p_token': token,
                'p_date': date.toIso8601String().split('T').first,
              },
            )
            as List;
    return rows
        .map(
          (row) => PeriodNeedingSubstitute.fromRow(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  static Future<String> recordSubstitution({
    required String classScheduleId,
    required DateTime date,
    required String originalTeacherId,
    required String substituteTeacherId,
    String? note,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final rows =
        await supabase.rpc(
              'record_class_substitution',
              params: {
                'p_token': token,
                'p_class_schedule_id': classScheduleId,
                'p_class_date': date.toIso8601String().split('T').first,
                'p_original_teacher_id': originalTeacherId,
                'p_substitute_teacher_id': substituteTeacherId,
                'p_note': note,
              },
            )
            as List;
    return (rows.first as Map<String, dynamic>)['substitution_id'] as String;
  }

  static Future<String> logPrepBlock({
    required DateTime date,
    required String startTime,
    required String endTime,
    String? label,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final rows =
        await supabase.rpc(
              'log_staff_prep_block',
              params: {
                'p_token': token,
                'p_class_date': date.toIso8601String().split('T').first,
                'p_start_time': startTime,
                'p_end_time': endTime,
                'p_label': label,
              },
            )
            as List;
    return (rows.first as Map<String, dynamic>)['block_id'] as String;
  }
}
