import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'course_form_page.dart';
import 'lesson_form_page.dart';
import 'grade_entry_page.dart';
import 'assignment_form_page.dart';

/// รายละเอียดรายวิชาฝั่งครู — จัดการรายชื่อนักเรียน (CLS-4) และบทเรียน (LRN)
class TeacherCourseDetailPage extends StatefulWidget {
  const TeacherCourseDetailPage({super.key, required this.courseId});

  final String courseId;

  @override
  State<TeacherCourseDetailPage> createState() =>
      _TeacherCourseDetailPageState();
}

class _TeacherCourseDetailPageState extends State<TeacherCourseDetailPage> {
  CourseDetail? course;
  List<CourseStudent> students = [];
  List<LessonSummary> lessons = [];
  List<AssignmentSummary> assignments = [];
  List<CourseFile> files = [];
  bool isLoading = true;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        CourseService.getCourse(widget.courseId),
        CourseService.listCourseStudents(widget.courseId),
        LessonService.listLessons(widget.courseId),
        AssignmentService.listAssignments(widget.courseId),
        CourseFileService.listFiles(widget.courseId),
      ]);
      if (!mounted) return;
      setState(() {
        course = results[0] as CourseDetail;
        students = results[1] as List<CourseStudent>;
        lessons = results[2] as List<LessonSummary>;
        assignments = results[3] as List<AssignmentSummary>;
        files = results[4] as List<CourseFile>;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('โหลดข้อมูลไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> enrollStudent() async {
    final emailController = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('เพิ่มนักเรียนเข้ารายวิชา'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'อีเมลนักเรียน'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, emailController.text.trim()),
            child: const Text('ค้นหา'),
          ),
        ],
      ),
    );
    emailController.dispose();
    if (email == null || email.isEmpty || !mounted) return;

    try {
      final student = await CourseService.findStudentByEmail(email);
      if (!mounted) return;
      if (student == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่พบนักเรียนที่ใช้อีเมลนี้ในโรงเรียน'),
          ),
        );
        return;
      }
      await CourseService.enrollStudent(
        courseId: widget.courseId,
        studentId: student.studentId,
      );
      await load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เพิ่ม ${student.fullName} เข้ารายวิชาแล้ว')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เพิ่มนักเรียนไม่สำเร็จ: $e')));
    }
  }

  Future<void> removeStudent(CourseStudent student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('นำออกจากรายวิชา'),
        content: Text('ต้องการนำ ${student.fullName} ออกจากรายวิชานี้หรือไม่'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('นำออก'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await CourseService.removeStudent(
        courseId: widget.courseId,
        studentId: student.studentId,
      );
      await load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('นำออกไม่สำเร็จ: $e')));
    }
  }

  Future<void> uploadFile() async {
    final result = await FilePicker.pickFiles(withData: true);
    final picked = result?.files.single;
    if (picked == null || picked.bytes == null) return;

    setState(() => isUploading = true);
    try {
      await CourseFileService.uploadFile(
        courseId: widget.courseId,
        fileName: picked.name,
        bytes: picked.bytes!,
      );
      await load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อัปโหลดไฟล์แล้ว'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('อัปโหลดไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(course?.subjectName ?? 'รายวิชา'),
        actions: [
          IconButton(
            icon: const Icon(Icons.grade_outlined),
            tooltip: 'ให้คะแนนนักเรียน',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GradeEntryPage(courseId: widget.courseId),
                ),
              );
            },
          ),
          if (course != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final saved = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseFormPage(course: course),
                  ),
                );
                if (saved == true) await load();
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (course?.description != null &&
                    course!.description!.isNotEmpty) ...[
                  Text(course!.description!),
                  const SizedBox(height: 20),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'นักเรียนในรายวิชา',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: enrollStudent,
                      icon: const Icon(Icons.person_add),
                      label: const Text('เพิ่ม'),
                    ),
                  ],
                ),
                if (students.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'ยังไม่มีนักเรียนในรายวิชานี้',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...students.map(
                    (student) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(student.fullName),
                        subtitle: Text(student.email),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => removeStudent(student),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'บทเรียน',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                LessonFormPage(courseId: widget.courseId),
                          ),
                        );
                        await load();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('สร้างบทเรียน'),
                    ),
                  ],
                ),
                if (lessons.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'ยังไม่มีบทเรียนในรายวิชานี้',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...lessons.map(
                    (lesson) => Card(
                      child: ListTile(
                        leading: Icon(
                          lesson.isPublished
                              ? Icons.menu_book
                              : Icons.edit_note,
                          color: lesson.isPublished ? null : Colors.grey,
                        ),
                        title: Text(lesson.title),
                        subtitle: Text(
                          lesson.isPublished ? 'เผยแพร่แล้ว' : 'ฉบับร่าง',
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LessonFormPage(lessonId: lesson.id),
                            ),
                          );
                          await load();
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'งาน (PBL)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AssignmentFormPage(courseId: widget.courseId),
                          ),
                        );
                        await load();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('สร้างงาน'),
                    ),
                  ],
                ),
                if (assignments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'ยังไม่มีงานในรายวิชานี้',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...assignments.map(
                    (assignment) => Card(
                      child: ListTile(
                        leading: Icon(
                          assignment.isPublished
                              ? Icons.assignment
                              : Icons.edit_note,
                          color: assignment.isPublished ? null : Colors.grey,
                        ),
                        title: Text(assignment.title),
                        subtitle: Text(
                          assignment.isPublished ? 'เผยแพร่แล้ว' : 'ฉบับร่าง',
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AssignmentFormPage(
                                assignmentId: assignment.id,
                              ),
                            ),
                          );
                          await load();
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ไฟล์เอกสาร',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: isUploading ? null : uploadFile,
                      icon: isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file),
                      label: const Text('อัปโหลดไฟล์'),
                    ),
                  ],
                ),
                if (files.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'ยังไม่มีไฟล์เอกสารในรายวิชานี้',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...files.map(
                    (file) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.insert_drive_file),
                        title: Text(file.fileName),
                        subtitle: Text(
                          '${file.formattedSize} • อัปโหลดโดย ${file.uploaderFullName}',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
