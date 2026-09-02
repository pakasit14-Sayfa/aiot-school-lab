import '../models/emergency_event_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

class EmergencyService {
  static Stream<List<Map<String, dynamic>>> streamEmergencyEvents() {
    return supabase
        .from('emergency_events')
        .stream(primaryKey: ['id'])
        .order('triggered_at', ascending: false);
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
