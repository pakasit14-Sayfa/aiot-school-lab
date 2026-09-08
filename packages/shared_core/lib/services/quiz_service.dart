import 'dart:typed_data';

import '../models/quiz_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// Pretest/posttest (ASM-1/2/3/4). RPCs from
/// 20260818000000_quiz_rpcs.sql. Teacher-side RPCs exist for completeness
/// but there's no quiz-builder UI yet — only the student-facing take-quiz
/// flow is wired in the app.
class QuizService {
  static Future<List<QuizSummary>> listCourseQuizzes(String courseId) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc(
              'list_course_quizzes',
              params: {'p_token': token, 'p_course_id': courseId},
            )
            as List;
    return rows
        .map((row) => QuizSummary.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<List<QuizQuestionSummary>> listQuizQuestions(
    String quizId,
  ) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc(
              'list_quiz_questions',
              params: {'p_token': token, 'p_quiz_id': quizId},
            )
            as List;
    return rows
        .map(
          (row) => QuizQuestionSummary.fromRow(row as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<QuizForStudent> getQuizForStudent(String quizId) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final rows =
        await supabase.rpc(
              'get_quiz_for_student',
              params: {'p_token': token, 'p_quiz_id': quizId},
            )
            as List;
    return QuizForStudent.fromRows(rows.cast<Map<String, dynamic>>());
  }

  static Future<({String attemptId, DateTime startedAt})> startQuizAttempt(
    String quizId,
  ) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final rows =
        await supabase.rpc(
              'start_quiz_attempt',
              params: {'p_token': token, 'p_quiz_id': quizId},
            )
            as List;
    final row = rows.first as Map<String, dynamic>;
    return (
      attemptId: row['attempt_id'] as String,
      startedAt: DateTime.parse(row['started_at'] as String).toUtc(),
    );
  }

  static Future<QuizAttemptResult?> getMyLatestQuizAttempt(
    String quizId,
  ) async {
    final token = AuthService.sessionToken;
    if (token == null) return null;
    final rows =
        await supabase.rpc(
              'get_my_latest_quiz_attempt',
              params: {'p_token': token, 'p_quiz_id': quizId},
            )
            as List;
    if (rows.isEmpty) return null;
    return QuizAttemptResult.fromRow(rows.first as Map<String, dynamic>);
  }

  static Future<void> saveQuizAnswer({
    required String attemptId,
    required String questionId,
    required Map<String, dynamic> answer,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'save_quiz_answer',
      params: {
        'p_token': token,
        'p_attempt_id': attemptId,
        'p_question_id': questionId,
        'p_answer': answer,
      },
    );
  }

  static Future<num> submitQuizAttempt(String attemptId) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final rows =
        await supabase.rpc(
              'submit_quiz_attempt',
              params: {'p_token': token, 'p_attempt_id': attemptId},
            )
            as List;
    return (rows.first as Map<String, dynamic>)['auto_score'] as num;
  }

  static Future<String> createQuiz({
    required String courseId,
    required String type, // 'pretest' or 'posttest'
    required String title,
    String? lessonId,
    int? timeLimitMin,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final rows =
        await supabase.rpc(
              'create_quiz',
              params: {
                'p_token': token,
                'p_course_id': courseId,
                'p_type': type,
                'p_title': title,
                'p_lesson_id': lessonId,
                'p_time_limit_min': timeLimitMin,
              },
            )
            as List;
    return (rows.first as Map<String, dynamic>)['quiz_id'] as String;
  }

  static Future<String> addQuizQuestion({
    required String quizId,
    required String type, // 'multiple_choice', 'true_false', 'short_answer'
    required String question,
    num points = 1,
    List<Map<String, dynamic>>? choices,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final rows =
        await supabase.rpc(
              'add_quiz_question',
              params: {
                'p_token': token,
                'p_quiz_id': quizId,
                'p_type': type,
                'p_question': question,
                'p_points': points,
                'p_choices': choices,
              },
            )
            as List;
    return (rows.first as Map<String, dynamic>)['question_id'] as String;
  }

  /// Uploads real bytes to the private `quiz-attachments` Storage bucket
  /// via a signed-upload URL minted by the quiz-attachment-upload Edge
  /// Function, then registers it against the question. [type] must be
  /// 'image' or 'video'.
  static Future<String> uploadQuestionAttachment({
    required String questionId,
    required String fileName,
    required Uint8List bytes,
    required String type,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');

    final uploadUrlResponse = await supabase.functions.invoke(
      'quiz-attachment-upload',
      body: {
        'token': token,
        'question_id': questionId,
        'file_name': fileName,
      },
    );
    final uploadData = uploadUrlResponse.data as Map<String, dynamic>?;
    final storagePath = uploadData?['storage_path'] as String?;
    final signedToken = uploadData?['token'] as String?;
    if (storagePath == null || signedToken == null) {
      throw Exception('upload_url_unavailable');
    }

    await supabase.storage
        .from('quiz-attachments')
        .uploadBinaryToSignedUrl(storagePath, signedToken, bytes);

    final rows =
        await supabase.rpc(
              'add_quiz_question_attachment',
              params: {
                'p_token': token,
                'p_question_id': questionId,
                'p_type': type,
                'p_storage_path': storagePath,
                'p_file_name': fileName,
              },
            )
            as List;
    return (rows.first as Map<String, dynamic>)['attachment_id'] as String;
  }

  /// Resolves a question attachment to a short-lived signed download URL.
  static Future<String> getQuestionAttachmentDownloadUrl(
    String attachmentId,
  ) async {
    final response = await supabase.functions.invoke(
      'quiz-attachment-download',
      body: {'token': AuthService.sessionToken, 'attachment_id': attachmentId},
    );
    final data = response.data as Map<String, dynamic>?;
    final signedUrl = data?['signed_url'] as String?;
    if (signedUrl == null) {
      throw Exception('download_url_unavailable');
    }
    return signedUrl;
  }

  static Future<void> publishQuiz(String quizId) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'publish_quiz',
      params: {'p_token': token, 'p_quiz_id': quizId},
    );
  }
}
