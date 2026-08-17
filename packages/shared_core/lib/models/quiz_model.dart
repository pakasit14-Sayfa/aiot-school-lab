class QuizSummary {
  const QuizSummary({
    required this.id,
    required this.type,
    required this.title,
    required this.timeLimitMin,
    required this.status,
    required this.lessonId,
  });

  final String id;
  final String type;
  final String title;
  final int? timeLimitMin;
  final String status;
  final String? lessonId;

  bool get isPublished => status == 'published';
  bool get isPreTest => type == 'pre_test';
  bool get isPostTest => type == 'post_test';

  factory QuizSummary.fromRow(Map<String, dynamic> row) => QuizSummary(
    id: row['quiz_id'] as String,
    type: row['type'] as String,
    title: row['title'] as String,
    timeLimitMin: row['time_limit_min'] as int?,
    status: row['status'] as String,
    lessonId: row['lesson_id'] as String?,
  );
}

class QuizAttemptResult {
  const QuizAttemptResult({
    required this.attemptId,
    required this.startedAt,
    required this.submittedAt,
    required this.autoScore,
  });

  final String attemptId;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final num? autoScore;

  bool get isSubmitted => submittedAt != null;

  factory QuizAttemptResult.fromRow(Map<String, dynamic> row) =>
      QuizAttemptResult(
        attemptId: row['attempt_id'] as String,
        startedAt: DateTime.parse(row['started_at'] as String).toUtc(),
        submittedAt: row['submitted_at'] == null
            ? null
            : DateTime.parse(row['submitted_at'] as String).toUtc(),
        autoScore: row['auto_score'] as num?,
      );
}

class QuizChoice {
  const QuizChoice({required this.id, required this.text});

  final String id;
  final String text;

  factory QuizChoice.fromMap(Map<String, dynamic> map) =>
      QuizChoice(id: map['id'] as String, text: map['text'] as String);
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.type,
    required this.question,
    required this.points,
    required this.sortOrder,
    required this.choices,
  });

  final String id;
  final String type;
  final String question;
  final num points;
  final int sortOrder;
  final List<QuizChoice> choices;
}

class QuizForStudent {
  const QuizForStudent({
    required this.quizId,
    required this.title,
    required this.type,
    required this.timeLimitMin,
    required this.questions,
  });

  final String quizId;
  final String title;
  final String type;
  final int? timeLimitMin;
  final List<QuizQuestion> questions;

  static QuizForStudent fromRows(List<Map<String, dynamic>> rows) {
    final questions = rows
        .map(
          (row) => QuizQuestion(
            id: row['question_id'] as String,
            type: row['question_type'] as String,
            question: row['question'] as String,
            points: row['points'] as num,
            sortOrder: row['sort_order'] as int? ?? 0,
            choices: (row['choices'] as List? ?? [])
                .cast<Map<String, dynamic>>()
                .map(QuizChoice.fromMap)
                .toList(),
          ),
        )
        .toList();

    final first = rows.first;
    return QuizForStudent(
      quizId: first['quiz_id'] as String,
      title: first['title'] as String,
      type: first['type'] as String,
      timeLimitMin: first['time_limit_min'] as int?,
      questions: questions,
    );
  }
}
