import '../models/executive_overview_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

class LearningTrackService {
  static Future<List<LearningTrack>> listTracks() async {
    final rows =
        await supabase.rpc(
              'list_learning_tracks',
              params: {'p_token': AuthService.sessionToken},
            )
            as List;
    return rows
        .map((row) => LearningTrack.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<String> createTrack({
    required String name,
    String color = '#7C3AED',
  }) async {
    final id = await supabase.rpc(
      'create_learning_track',
      params: {
        'p_token': AuthService.sessionToken,
        'p_name': name,
        'p_color': color,
      },
    );
    return id as String;
  }

  static Future<void> updateTrack({
    required String trackId,
    required String name,
    required String color,
    required int sortOrder,
  }) async {
    await supabase.rpc(
      'update_learning_track',
      params: {
        'p_token': AuthService.sessionToken,
        'p_track_id': trackId,
        'p_name': name,
        'p_color': color,
        'p_sort_order': sortOrder,
      },
    );
  }

  static Future<void> deleteTrack(String trackId) async {
    await supabase.rpc(
      'delete_learning_track',
      params: {
        'p_token': AuthService.sessionToken,
        'p_track_id': trackId,
      },
    );
  }

  static Future<List<LearningTrackRoom>> listTrackRooms() async {
    final rows =
        await supabase.rpc(
              'list_learning_track_rooms',
              params: {'p_token': AuthService.sessionToken},
            )
            as List;
    return rows
        .map((row) => LearningTrackRoom.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> setTrackRoom({
    required String gradeLevel,
    required String room,
    String? trackId,
  }) async {
    await supabase.rpc(
      'set_learning_track_room',
      params: {
        'p_token': AuthService.sessionToken,
        'p_grade_level': gradeLevel,
        'p_room': room,
        'p_track_id': trackId,
      },
    );
  }

  static Future<List<LearningTrackOverview>> getOverview() async {
    final rows =
        await supabase.rpc(
              'get_learning_track_overview',
              params: {'p_token': AuthService.sessionToken},
            )
            as List;
    return rows
        .map(
          (row) => LearningTrackOverview.fromRow(row as Map<String, dynamic>),
        )
        .toList();
  }
}
