import 'package:flutter/material.dart';

class TeacherData {
  final int id;
  final String name;
  final String subjectGroup;
  final String position;
  final String email;

  const TeacherData({
    required this.id,
    required this.name,
    required this.subjectGroup,
    required this.position,
    required this.email,
  });
}

class LearningLevelData {
  final String grade;
  final int students;
  final int rooms;
  final int attendance;
  final Color color;

  const LearningLevelData({
    required this.grade,
    required this.students,
    required this.rooms,
    required this.attendance,
    required this.color,
  });
}

class ProgramData {
  final String title;
  final int students;
  final int rooms;
  final int attendance;
  final IconData icon;
  final Color background;

  const ProgramData({
    required this.title,
    required this.students,
    required this.rooms,
    required this.attendance,
    required this.icon,
    required this.background,
  });
}

class ListItemData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String status;

  const ListItemData({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.status,
  });
}

class MeetingData {
  final String time;
  final String title;
  final String location;

  const MeetingData({
    required this.time,
    required this.title,
    required this.location,
  });
}
