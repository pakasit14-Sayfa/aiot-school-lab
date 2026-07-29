import '../models/post_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// Course discussion board — RPCs from 20260731010000_course_posts.sql.
class PostService {
  static Future<String> createPost({
    required String courseId,
    required String body,
  }) async {
    final rows =
        await supabase.rpc(
              'create_post',
              params: {
                'p_token': AuthService.sessionToken,
                'p_course_id': courseId,
                'p_body': body.trim(),
              },
            )
            as List;

    return (rows.first as Map<String, dynamic>)['post_id'] as String;
  }

  static Future<List<CoursePost>> listPosts(String courseId) async {
    final rows =
        await supabase.rpc(
              'list_posts',
              params: {
                'p_token': AuthService.sessionToken,
                'p_course_id': courseId,
              },
            )
            as List;

    return rows
        .map((row) => CoursePost.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<String> createReply({
    required String postId,
    required String body,
  }) async {
    final rows =
        await supabase.rpc(
              'create_reply',
              params: {
                'p_token': AuthService.sessionToken,
                'p_post_id': postId,
                'p_body': body.trim(),
              },
            )
            as List;

    return (rows.first as Map<String, dynamic>)['reply_id'] as String;
  }
}
