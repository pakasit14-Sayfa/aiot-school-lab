import 'package:flutter/material.dart';

/// Data Contract and State Models for Student Redesign Dashboard (Variant A).
/// Defines backend schema mapping for Supabase / REST APIs and mock defaults.

/// 1. Student Profile & Score Summary Contract
class StudentProfileState {
  const StudentProfileState({
    required this.name,
    required this.gradeLevel,
    required this.schoolName,
    required this.gscoreValue,
    required this.gscoreMax,
    required this.gradeLabel,
    required this.gpa,
    required this.gpaLabel,
    required this.submittedTasks,
    required this.totalTasks,
    required this.badgesCount,
    required this.badgeTitle,
  });

  final String name;
  final String gradeLevel;
  final String schoolName;
  final int gscoreValue;
  final int gscoreMax;
  final String gradeLabel;
  final double gpa;
  final String gpaLabel;
  final int submittedTasks;
  final int totalTasks;
  final int badgesCount;
  final String badgeTitle;

  double get gscorePercent => (gscoreValue / gscoreMax).clamp(0.0, 1.0);
  double get taskCompletionPercent =>
      (submittedTasks / totalTasks).clamp(0.0, 1.0);

  /// Default Mock Data matching UI Prototype
  static const mock = StudentProfileState(
    name: 'สายฟ้า',
    gradeLevel: 'ม.2/1',
    schoolName: 'โรงเรียนสาธิต AIoT',
    gscoreValue: 92,
    gscoreMax: 100,
    gradeLabel: 'GRADE A+ 🌟',
    gpa: 3.85,
    gpaLabel: 'เกียรตินิยม',
    submittedTasks: 18,
    totalTasks: 20,
    badgesCount: 15,
    badgeTitle: 'ผู้เชี่ยวชาญ AIoT',
  );
}

/// 2. AIoT Weather Telemetry Data Contract
class AiotSensorState {
  const AiotSensorState({
    required this.pm25Value,
    required this.pm25Unit,
    required this.pm25Status,
    required this.pm25Subtitle,
    required this.tempValue,
    required this.tempUnit,
    required this.tempStatus,
    required this.tempSubtitle,
    required this.humidityValue,
    required this.humidityUnit,
    required this.humidityStatus,
    required this.humiditySubtitle,
    required this.uvValue,
    required this.uvStatus,
    required this.uvSubtitle,
    required this.isLive,
    required this.lastUpdated,
  });

  final String pm25Value;
  final String pm25Unit;
  final String pm25Status;
  final String pm25Subtitle;
  final String tempValue;
  final String tempUnit;
  final String tempStatus;
  final String tempSubtitle;
  final String humidityValue;
  final String humidityUnit;
  final String humidityStatus;
  final String humiditySubtitle;
  final String uvValue;
  final String uvStatus;
  final String uvSubtitle;
  final bool isLive;
  final DateTime lastUpdated;

  /// Default Mock Data
  static final mock = AiotSensorState(
    pm25Value: '18',
    pm25Unit: 'µg/m³',
    pm25Status: 'ดีมาก',
    pm25Subtitle: 'ห้องเรียนปลอดภัย · คุณภาพอากาศ 98%',
    tempValue: '28.5',
    tempUnit: '°C',
    tempStatus: 'เหมาะสม',
    tempSubtitle: 'อบอุ่นกำลังดี',
    humidityValue: '62',
    humidityUnit: '%RH',
    humidityStatus: 'ปกติ',
    humiditySubtitle: 'สภาพแวดล้อมเหมาะสม',
    uvValue: 'UV 2',
    uvStatus: 'ปลอดภัย',
    uvSubtitle: 'ระดับปลอดภัย',
    isLive: true,
    lastUpdated: DateTime.now(),
  );
}

/// 3. Continue Learning Task Model
class ContinueLearningState {
  const ContinueLearningState({
    required this.courseId,
    required this.courseTitle,
    required this.chapterTitle,
    required this.progressPercent,
    required this.completedLessons,
    required this.totalLessons,
    required this.thumbnailUrl,
  });

  final String courseId;
  final String courseTitle;
  final String chapterTitle;
  final double progressPercent;
  final int completedLessons;
  final int totalLessons;
  final String? thumbnailUrl;

  static const mock = ContinueLearningState(
    courseId: 'aiot-bio-101',
    courseTitle: 'วิชา AIoT ชีววิทยาและสิ่งแวดล้อม',
    chapterTitle: 'บทเรียนที่ 4: การวิเคราะห์ข้อมูล PM2.5 จากเซนเซอร์จริง',
    progressPercent: 0.65,
    completedLessons: 13,
    totalLessons: 20,
    thumbnailUrl: null,
  );
}

/// 4. Task Item Contract
class TaskItemState {
  const TaskItemState({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueTimeText,
    required this.priorityLabel,
    required this.priorityColor,
    required this.avatarEmoji,
  });

  final String id;
  final String title;
  final String subject;
  final String dueTimeText;
  final String priorityLabel;
  final Color priorityColor;
  final String avatarEmoji;

  static const mockList = [
    TaskItemState(
      id: 'task-1',
      title: 'ส่งใบงานการทดลองเซนเซอร์ PM2.5',
      subject: 'วิชา AIoT ชีววิทยา',
      dueTimeText: 'ส่งวันนี้ 16:30 น. (เหลือ 3 ชม.)',
      priorityLabel: 'ด่วนที่สุด 🔥',
      priorityColor: Color(0xFFDC2626),
      avatarEmoji: '🧪',
    ),
    TaskItemState(
      id: 'task-2',
      title: 'แบบฝึกหัดคำนวณค่าเฉลี่ยสถิติฝุ่น',
      subject: 'วิชาคณิตศาสตร์เพิ่มเติม',
      dueTimeText: 'ส่งพรุ่งนี้ 08:30 น.',
      priorityLabel: 'ปานกลาง ⏳',
      priorityColor: Color(0xFFD97706),
      avatarEmoji: '📐',
    ),
    TaskItemState(
      id: 'task-3',
      title: 'รายงานการประหยัดพลังงานในห้องเรียน',
      subject: 'วิชาฟิสิกส์ประยุกต์',
      dueTimeText: 'ส่ง 3 ส.ค. 2569',
      priorityLabel: 'ปกติ 🟢',
      priorityColor: Color(0xFF059669),
      avatarEmoji: '⚡',
    ),
  ];
}
