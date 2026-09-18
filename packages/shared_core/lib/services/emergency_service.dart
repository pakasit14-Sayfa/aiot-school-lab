import '../models/emergency_event_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

class EmergencyService {
  /// A refresh tick every 15 s. Pages listen and re-run their RPC load.
  ///
  /// This used to be `supabase.from('emergency_events').stream(...)`. RLS is
  /// deny-all with zero policies, and Supabase Realtime honours RLS, so
  /// that stream never emitted a row on any environment — every "live"
  /// subscriber (student safety, teacher inbox, director emergency page)
  /// silently never refreshed. Found 2026-09-18. The payload is empty on
  /// purpose: no caller ever read it, they all call their own loader.
  static Stream<List<Map<String, dynamic>>> streamEmergencyEvents() {
    return Stream<List<Map<String, dynamic>>>.periodic(
      const Duration(seconds: 15),
      (_) => const <Map<String, dynamic>>[],
    );
  }

  static Future<List<EmergencyEventItem>> listEmergencyEvents({
    String? status,
  }) async {
    final rows =
        await supabase.rpc(
              'list_emergency_events',
              params: {
                'p_token': AuthService.sessionToken,
                if (status != null && status.isNotEmpty) 'p_status': status,
              },
            )
            as List;

    return rows
        .map((row) => EmergencyEventItem.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> acknowledgeEmergencyEvent(String eventId) async {
    await supabase.rpc(
      'acknowledge_emergency_event',
      params: {'p_token': AuthService.sessionToken, 'p_event_id': eventId},
    );
  }

  static Future<void> closeEmergencyEvent({
    required String eventId,
    required String reviewNote,
  }) async {
    await supabase.rpc(
      'close_emergency_event',
      params: {
        'p_token': AuthService.sessionToken,
        'p_event_id': eventId,
        'p_review_note': reviewNote.trim(),
      },
    );
  }
}
