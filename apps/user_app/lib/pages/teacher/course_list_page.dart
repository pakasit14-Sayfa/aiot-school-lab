import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'course_form_page.dart';
import 'course_detail_page.dart';

/// รายวิชาของครู (CLS-1..4) — สร้างวิชาใหม่และเข้าไปจัดการรายวิชาที่มี
class TeacherCourseListPage extends StatefulWidget {
  const TeacherCourseListPage({super.key});

  @override
  State<TeacherCourseListPage> createState() => _TeacherCourseListPageState();
}

class _TeacherCourseListPageState extends State<TeacherCourseListPage> {
  List<CourseSummary> courses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCourses();
  }

  Future<void> loadCourses() async {
    setState(() => isLoading = true);
    try {
      final result = await CourseService.listMyCourses();
      if (mounted) setState(() => courses = result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('โหลดรายวิชาไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> openCreateForm() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CourseFormPage()),
    );
    if (created == true) await loadCourses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการห้องเรียน'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadCourses),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openCreateForm,
        icon: const Icon(Icons.add),
        label: const Text('สร้างรายวิชา'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : courses.isEmpty
          ? const Center(
              child: Text(
                'ยังไม่มีรายวิชา — กดปุ่มด้านล่างเพื่อสร้างรายวิชาแรก',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.school),
                    title: Text(course.subjectName),
                    subtitle: Text(
                      [
                        if (course.gradeLevel != null) course.gradeLevel!,
                        if (course.room != null) 'ห้อง ${course.room}',
                      ].join(' • '),
                    ),
                    trailing: course.isActive
                        ? null
                        : const Chip(label: Text('ปิดแล้ว')),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TeacherCourseDetailPage(courseId: course.id),
                        ),
                      );
                      await loadCourses();
                    },
                  ),
                );
              },
            ),
    );
  }
}
