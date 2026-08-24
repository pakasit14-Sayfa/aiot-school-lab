import '../models/executive_overview_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

class ExecutiveService {
  static Future<ClassroomsOverviewItem?> getClassroomsOverview() async {
    final token = AuthService.sessionToken;
    if (token == null) return null;

    final rows =
        await supabase.rpc(
              'get_classrooms_overview',
              params: {'p_token': token},
            )
            as List;

    if (rows.isEmpty) return null;
    return ClassroomsOverviewItem.fromRow(rows.first as Map<String, dynamic>);
  }

  static Future<List<SchoolScheduleItem>> listAllSchoolSchedules() async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];

    final rows =
        await supabase.rpc(
              'list_all_school_schedules',
              params: {'p_token': token},
            )
            as List;

    return rows
        .map((row) => SchoolScheduleItem.fromRow(row as Map<String, dynamic>))
        .toList();
  }
}
