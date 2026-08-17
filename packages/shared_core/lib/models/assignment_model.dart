class AssignmentSensorDataset {
  final String id;
  final String deviceId;
  final String metric;
  final DateTime? timeStart;
  final DateTime? timeEnd;
  final String? label;

  const AssignmentSensorDataset({
    required this.id,
    required this.deviceId,
    required this.metric,
    required this.timeStart,
    required this.timeEnd,
    required this.label,
  });

  factory AssignmentSensorDataset.fromJson(Map<String, dynamic> json) =>
      AssignmentSensorDataset(
        id: json['id'] as String,
        deviceId: json['device_id'] as String,
        metric: json['metric'] as String,
        timeStart: json['time_start'] == null
            ? null
            : DateTime.parse(json['time_start'] as String).toUtc(),
        timeEnd: json['time_end'] == null
            ? null
            : DateTime.parse(json['time_end'] as String).toUtc(),
        label: json['label'] as String?,
      );
}

class AssignmentSummary {
  final String id;
  final String type;
  final String title;
  final DateTime? dueAt;
  final String status;

  const AssignmentSummary({
    required this.id,
    required this.type,
    required this.title,
    required this.dueAt,
    required this.status,
  });

  factory AssignmentSummary.fromRow(Map<String, dynamic> row) =>
      AssignmentSummary(
        id: row['assignment_id'] as String,
        type: row['type'] as String,
        title: row['title'] as String,
        dueAt: row['due_at'] == null
            ? null
            : DateTime.parse(row['due_at'] as String).toUtc(),
        status: row['status'] as String,
      );

  bool get isPublished => status == 'published';
}

class AssignmentDetail {
  final String id;
  final String courseId;
  final String type;
  final String title;
  final String? instructions;
  final DateTime? dueAt;
  final String status;
  final List<AssignmentSensorDataset> sensorDatasets;

  const AssignmentDetail({
    required this.id,
    required this.courseId,
    required this.type,
    required this.title,
    required this.instructions,
    required this.dueAt,
    required this.status,
    required this.sensorDatasets,
  });

  factory AssignmentDetail.fromRow(Map<String, dynamic> row) {
    final datasets = (row['sensor_datasets'] as List? ?? [])
        .map(
          (item) =>
              AssignmentSensorDataset.fromJson(item as Map<String, dynamic>),
        )
        .toList();

    return AssignmentDetail(
      id: row['assignment_id'] as String,
      courseId: row['course_id'] as String,
      type: row['type'] as String,
      title: row['title'] as String,
      instructions: row['instructions'] as String?,
      dueAt: row['due_at'] == null
          ? null
          : DateTime.parse(row['due_at'] as String).toUtc(),
      status: row['status'] as String,
      sensorDatasets: datasets,
    );
  }

  bool get isPublished => status == 'published';
}

class SubmissionVersion {
  final int version;
  final String? content;
  final DateTime submittedAt;

  const SubmissionVersion({
    required this.version,
    required this.content,
    required this.submittedAt,
  });

  factory SubmissionVersion.fromRow(Map<String, dynamic> row) =>
      SubmissionVersion(
        version: row['version'] as int,
        content: row['content'] as String?,
        submittedAt: DateTime.parse(row['submitted_at'] as String).toUtc(),
      );
}

class SubmissionRoster {
  final String submissionId;
  final String studentId;
  final String studentFirstName;
  final String studentLastName;
  final String status;
  final int currentVersion;
  final String? latestContent;
  final DateTime? submittedAt;

  const SubmissionRoster({
    required this.submissionId,
    required this.studentId,
    required this.studentFirstName,
    required this.studentLastName,
    required this.status,
    required this.currentVersion,
    required this.latestContent,
    required this.submittedAt,
  });

  factory SubmissionRoster.fromRow(Map<String, dynamic> row) =>
      SubmissionRoster(
        submissionId: row['submission_id'] as String,
        studentId: row['student_id'] as String,
        studentFirstName: row['student_first_name'] as String,
        studentLastName: row['student_last_name'] as String,
        status: row['status'] as String,
        currentVersion: row['current_version'] as int,
        latestContent: row['latest_content'] as String?,
        submittedAt: row['submitted_at'] == null
            ? null
            : DateTime.parse(row['submitted_at'] as String).toUtc(),
      );

  String get studentFullName => '$studentFirstName $studentLastName';
}

class AssignmentFeedback {
  final String id;
  final String authorFirstName;
  final String authorLastName;
  final String body;
  final DateTime createdAt;

  const AssignmentFeedback({
    required this.id,
    required this.authorFirstName,
    required this.authorLastName,
    required this.body,
    required this.createdAt,
  });

  factory AssignmentFeedback.fromRow(Map<String, dynamic> row) =>
      AssignmentFeedback(
        id: row['feedback_id'] as String,
        authorFirstName: row['author_first_name'] as String,
        authorLastName: row['author_last_name'] as String,
        body: row['body'] as String,
        createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
      );

  String get authorFullName => '$authorFirstName $authorLastName';
}
