import '../models/rubric_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

class RubricService {
  static Future<List<RubricModel>> listMyRubrics() async {
    final token = AuthService.sessionToken;
    if (token == null) return [];
    final rows =
        await supabase.rpc('list_my_rubrics', params: {'p_token': token})
            as List;
    return rows
        .map((row) => RubricModel.fromListRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<RubricModel> getRubric(String rubricId) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final rows =
        await supabase.rpc(
              'get_rubric',
              params: {'p_token': token, 'p_rubric_id': rubricId},
            )
            as List;
    if (rows.isEmpty) throw Exception('rubric_not_found');
    return RubricModel.fromDetailRow(rows.first as Map<String, dynamic>);
  }

  static Future<String> createRubric({
    required String title,
    String? description,
    List<Map<String, dynamic>>? criteria,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final rows =
        await supabase.rpc(
              'create_rubric',
              params: {
                'p_token': token,
                'p_title': title,
                'p_description': description,
                'p_criteria': criteria ?? [],
              },
            )
            as List;
    final row = rows.first as Map<String, dynamic>;
    return row['rubric_id'] as String;
  }

  static Future<String> addRubricCriterion({
    required String rubricId,
    required String name,
    String? description,
    num maxScore = 10,
    List<dynamic>? levels,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final rows =
        await supabase.rpc(
              'add_rubric_criterion',
              params: {
                'p_token': token,
                'p_rubric_id': rubricId,
                'p_name': name,
                'p_description': description,
                'p_max_score': maxScore,
                'p_levels': levels,
              },
            )
            as List;
    final row = rows.first as Map<String, dynamic>;
    return row['criterion_id'] as String;
  }
}
