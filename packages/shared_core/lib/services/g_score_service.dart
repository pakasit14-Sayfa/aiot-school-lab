import '../models/g_score_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// G-Score (Gamification) — LRN-11/LRN-12. Points accumulate as 'pending'
/// automatically (hooked into mark_lesson_complete/submit_assignment
/// server-side, not called from here) and only become visible to the
/// student once a teacher confirms them. See
/// supabase/migrations/20260823030000_g_score.sql.
class GScoreService {
  static Future<List<PendingGScoreEntry>> listPendingGScore() async {
    final rows =
        await supabase.rpc(
              'list_pending_g_score',
              params: {'p_token': AuthService.sessionToken},
            )
            as List;

    return rows
        .map((row) => PendingGScoreEntry.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> confirmGScore(String entryId) async {
    await supabase.rpc(
      'confirm_g_score',
      params: {'p_token': AuthService.sessionToken, 'p_entry_id': entryId},
    );
  }

  static Future<List<MyGScoreEntry>> listMyGScore() async {
    final rows =
        await supabase.rpc(
              'list_my_g_score',
              params: {'p_token': AuthService.sessionToken},
            )
            as List;

    return rows
        .map((row) => MyGScoreEntry.fromRow(row as Map<String, dynamic>))
        .toList();
  }
}
