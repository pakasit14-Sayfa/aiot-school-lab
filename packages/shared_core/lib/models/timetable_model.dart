class SchoolPeriod {
  final int periodNo;
  final String startTime; // 'HH:mm' or 'HH:mm:ss' as the DB returns it
  final String endTime;
  final String? label;

  const SchoolPeriod({
    required this.periodNo,
    required this.startTime,
    required this.endTime,
    this.label,
  });

  factory SchoolPeriod.fromJson(Map<String, dynamic> json) {
    return SchoolPeriod(
      periodNo: json['period_no'] as int,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      label: json['label'] as String?,
    );
  }

  /// Shape `set_school_periods(p_periods jsonb)` expects.
  Map<String, dynamic> toJson() => {
    'period_no': periodNo,
    'start_time': startTime,
    'end_time': endTime,
    if (label != null) 'label': label,
  };

  String get startHm =>
      startTime.length >= 5 ? startTime.substring(0, 5) : startTime;
  String get endHm => endTime.length >= 5 ? endTime.substring(0, 5) : endTime;
}

class TeacherSubject {
  final String teacherId;
  final String subjectName;
  final String fullName;

  const TeacherSubject({
    required this.teacherId,
    required this.subjectName,
    required this.fullName,
  });

  factory TeacherSubject.fromJson(Map<String, dynamic> json) {
    return TeacherSubject(
      teacherId: json['teacher_id'] as String,
      subjectName: json['subject_name'] as String,
      fullName: (json['teacher_name'] ?? json['full_name'] ?? '') as String,
    );
  }
}

class ClassSchedule {
  final String? scheduleId;
  final String courseId;
  final int dayOfWeek;
  final int periodNo;
  final String startTime;
  final String endTime;
  final String subjectName;
  final String? teacherId;
  final String? teacherName;

  const ClassSchedule({
    this.scheduleId,
    required this.courseId,
    required this.dayOfWeek,
    required this.periodNo,
    required this.startTime,
    required this.endTime,
    required this.subjectName,
    this.teacherId,
    this.teacherName,
  });

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      scheduleId: json['schedule_id'] as String?,
      courseId: json['course_id'] as String,
      dayOfWeek: json['day_of_week'] as int,
      periodNo: json['period_no'] as int,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      subjectName: json['subject_name'] as String,
      teacherId: json['teacher_id'] as String?,
      teacherName: json['teacher_name'] as String?,
    );
  }
}

class Term {
  final String termId;
  final String termName;
  final String academicYearName;
  final DateTime? startDate;
  final DateTime? endDate;

  const Term({
    required this.termId,
    required this.termName,
    required this.academicYearName,
    this.startDate,
    this.endDate,
  });

  factory Term.fromJson(Map<String, dynamic> json) {
    return Term(
      termId: json['term_id'] as String,
      termName: json['term_name'] as String,
      academicYearName: json['academic_year_name'] as String,
      startDate: DateTime.tryParse('${json['start_date'] ?? ''}'),
      endDate: DateTime.tryParse('${json['end_date'] ?? ''}'),
    );
  }

  bool containsDate(DateTime d) =>
      startDate != null &&
      endDate != null &&
      !d.isBefore(startDate!) &&
      !d.isAfter(endDate!);
}

class SchoolRoom {
  final String gradeLevel;
  final String room;

  const SchoolRoom({required this.gradeLevel, required this.room});

  factory SchoolRoom.fromJson(Map<String, dynamic> json) {
    return SchoolRoom(
      gradeLevel: json['grade_level'] as String,
      room: json['room'] as String,
    );
  }

  /// Mirrors `_class_room_key` in the DB: rooms arrive as either '1' (prod
  /// student_profiles) or 'ม.1/1' (local seed / courses), and both must read
  /// as 'ม.1/1' — never 'ม.1/ม.1/1'.
  String get displayName =>
      room.startsWith('$gradeLevel/') ? room : '$gradeLevel/$room';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolRoom &&
          runtimeType == other.runtimeType &&
          gradeLevel == other.gradeLevel &&
          room == other.room;

  @override
  int get hashCode => gradeLevel.hashCode ^ room.hashCode;
}
