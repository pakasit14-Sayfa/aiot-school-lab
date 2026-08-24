import 'package:flutter/material.dart';

import '../models/director_models.dart';
import '../theme/app_palette.dart';

class DirectorMockData {
  static const List<TeacherData> teachers = [
    TeacherData(id: 1, name: 'ครูสมชาย ใจดี', subjectGroup: 'คณิตศาสตร์', position: 'ครูผู้สอน', email: 'somchai@school.ac.th'),
    TeacherData(id: 2, name: 'ครูสุพัตรา แสงทอง', subjectGroup: 'วิทยาศาสตร์', position: 'หัวหน้ากลุ่มสาระ', email: 'supattra@school.ac.th'),
    TeacherData(id: 3, name: 'ครูอนันต์ พัฒนกิจ', subjectGroup: 'วิทยาศาสตร์', position: 'ครูผู้สอน', email: 'anan@school.ac.th'),
    TeacherData(id: 4, name: 'ครูพิมพ์ชนก รุ่งเรือง', subjectGroup: 'ภาษาไทย', position: 'ครูผู้สอน', email: 'pimchanok@school.ac.th'),
    TeacherData(id: 5, name: 'ครูณัฐวุฒิ ศรีสุข', subjectGroup: 'สังคมศึกษา', position: 'ครูผู้สอน', email: 'nattawut@school.ac.th'),
    TeacherData(id: 6, name: 'ครูอรทัย บุญมี', subjectGroup: 'ภาษาต่างประเทศ', position: 'หัวหน้ากลุ่มสาระ', email: 'orathai@school.ac.th'),
    TeacherData(id: 7, name: 'ครูธนกร แข็งแรง', subjectGroup: 'สุขศึกษา', position: 'ครูผู้สอน', email: 'thanakorn@school.ac.th'),
    TeacherData(id: 8, name: 'ครูวรัญญา สุนทร', subjectGroup: 'ศิลปะ', position: 'ครูผู้สอน', email: 'waranya@school.ac.th'),
    TeacherData(id: 9, name: 'ครูกิตติพงษ์ ชำนาญ', subjectGroup: 'การงานอาชีพ', position: 'ครูผู้สอน', email: 'kittipong@school.ac.th'),
  ];

  static const List<String> subjectGroups = [
    'All', 'ภาษาไทย', 'คณิตศาสตร์', 'วิทยาศาสตร์', 'สังคมศึกษา',
    'ภาษาต่างประเทศ', 'สุขศึกษา', 'ศิลปะ', 'การงานอาชีพ',
  ];

  static const List<LearningLevelData> learningLevels = [
    LearningLevelData(grade: 'ม.1', students: 198, rooms: 6, attendance: 95, color: AppPalette.chartPink),
    LearningLevelData(grade: 'ม.2', students: 204, rooms: 6, attendance: 94, color: AppPalette.chartPink2),
    LearningLevelData(grade: 'ม.3', students: 206, rooms: 6, attendance: 96, color: AppPalette.chartCream),
    LearningLevelData(grade: 'ม.4', students: 224, rooms: 6, attendance: 93, color: AppPalette.chartPink3),
    LearningLevelData(grade: 'ม.5', students: 238, rooms: 6, attendance: 92, color: AppPalette.chartPink),
    LearningLevelData(grade: 'ม.6', students: 250, rooms: 6, attendance: 97, color: AppPalette.chartPink2),
  ];

  static const List<ProgramData> programs = [
    ProgramData(title: 'วิทย์ - คณิต', students: 154, rooms: 6, attendance: 95, icon: Icons.science_rounded, background: AppPalette.softPink),
    ProgramData(title: 'สายภาษา', students: 102, rooms: 4, attendance: 94, icon: Icons.translate_rounded, background: AppPalette.softCream),
    ProgramData(title: 'สายทั่วไป', students: 96, rooms: 4, attendance: 92, icon: Icons.menu_book_rounded, background: AppPalette.softBlue),
  ];

  static const List<MeetingData> todayMeetings = [
    MeetingData(time: '09:00', title: 'ประชุมฝ่ายบริหาร', location: 'ห้องประชุม 1'),
    MeetingData(time: '11:00', title: 'พบหัวหน้ากลุ่มสาระวิทยาศาสตร์', location: 'ห้องผู้อำนวยการ'),
    MeetingData(time: '15:00', title: 'ประชุมครูระดับชั้น ม.6', location: 'ห้องประชุมใหญ่'),
  ];
}
