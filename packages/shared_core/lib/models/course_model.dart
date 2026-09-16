class StudentLookup {
  final String studentId;
  final String firstName;
  final String lastName;
  final String email;

  const StudentLookup({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory StudentLookup.fromRow(Map<String, dynamic> row) => StudentLookup(
    studentId: row['student_id'] as String,
    firstName: row['first_name'] as String,
    lastName: row['last_name'] as String,
    email: row['email'] as String,
  );

  String get fullName => '$firstName $lastName'.trim();
}

/// ปีการศึกษาของโรงเรียน (list_academic_years) — ใช้ในหน้าตั้งค่าของแอดมิน
class AcademicYearOption {
  final String id;
  final String name;
  final DateTime? startDate;
  final DateTime? endDate;
  final int termsCount;

  const AcademicYearOption({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.termsCount,
  });

  factory AcademicYearOption.fromRow(Map<String, dynamic> row) =>
      AcademicYearOption(
        id: row['id'] as String,
        name: row['name'] as String,
        startDate: row['start_date'] == null
            ? null
            : DateTime.parse(row['start_date'] as String),
        endDate: row['end_date'] == null
            ? null
            : DateTime.parse(row['end_date'] as String),
        termsCount: (row['terms_count'] as num?)?.toInt() ?? 0,
      );
}

class TermOption {
  final String id;
  final String name;
  final String academicYearName;

  const TermOption({
    required this.id,
    required this.name,
    required this.academicYearName,
  });

  factory TermOption.fromRow(Map<String, dynamic> row) => TermOption(
    id: row['term_id'] as String,
    name: row['term_name'] as String,
    academicYearName: row['academic_year_name'] as String,
  );
}

class CourseSummary {
  final String id;
  final String subjectName;
  final String? gradeLevel;
  final String? room;
  final String status;
  final String termId;

  const CourseSummary({
    required this.id,
    required this.subjectName,
    required this.gradeLevel,
    required this.room,
    required this.status,
    required this.termId,
  });

  factory CourseSummary.fromRow(Map<String, dynamic> row) => CourseSummary(
    id: row['course_id'] as String,
    subjectName: row['subject_name'] as String,
    gradeLevel: row['grade_level'] as String?,
    room: row['room'] as String?,
    status: row['status'] as String,
    termId: row['term_id'] as String,
  );

  bool get isActive => status == 'active';
}

class CourseDetail {
  final String id;
  final String subjectName;
  final String? gradeLevel;
  final String? room;
  final String? description;
  final String status;
  final String termId;
  final String? teacherNames;

  const CourseDetail({
    required this.id,
    required this.subjectName,
    required this.gradeLevel,
    required this.room,
    required this.description,
    required this.status,
    required this.termId,
    required this.teacherNames,
  });

  factory CourseDetail.fromRow(Map<String, dynamic> row) => CourseDetail(
    id: row['course_id'] as String,
    subjectName: row['subject_name'] as String,
    gradeLevel: row['grade_level'] as String?,
    room: row['room'] as String?,
    description: row['description'] as String?,
    status: row['status'] as String,
    termId: row['term_id'] as String,
    teacherNames: row['teacher_names'] as String?,
  );
}

class CourseStudent {
  final String studentId;
  final String firstName;
  final String lastName;
  final String email;
  final DateTime enrolledAt;

  const CourseStudent({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.enrolledAt,
  });

  factory CourseStudent.fromRow(Map<String, dynamic> row) => CourseStudent(
    studentId: row['student_id'] as String,
    firstName: row['first_name'] as String,
    lastName: row['last_name'] as String,
    email: row['email'] as String,
    enrolledAt: DateTime.parse(row['enrolled_at'] as String).toUtc(),
  );

  String get fullName => '$firstName $lastName'.trim();
}
