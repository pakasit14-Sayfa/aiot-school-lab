import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

/// ให้คะแนนนักเรียนในรายวิชา (Slice 3 — manual grade entry)
///
/// ครูให้คะแนนแบบร่างก่อน แล้วค่อยกด "ยืนยัน" ให้เป็นคะแนนจริงที่นักเรียน/
/// ผู้ปกครองเห็นได้ — ถ้าครูมีความสัมพันธ์เป็นผู้ปกครองของนักเรียนคนนั้น
/// (parent_links อนุมัติแล้ว) ระบบจะติดธง CoI ให้อัตโนมัติ ยืนยันได้ตามปกติ
/// แต่ School Admin จะเห็นรายการนี้ในคิวตรวจสอบ
class GradeEntryPage extends StatefulWidget {
  const GradeEntryPage({super.key, required this.courseId});

  final String courseId;

  @override
  State<GradeEntryPage> createState() => _GradeEntryPageState();
}

class _GradeEntryPageState extends State<GradeEntryPage> {
  List<CourseStudent> students = [];
  List<GradeRecord> grades = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final results = await Future.wait([
        CourseService.listCourseStudents(widget.courseId),
        GradeService.listCourseGrades(widget.courseId),
      ]);
      if (!mounted) return;
      setState(() {
        students = results[0] as List<CourseStudent>;
        grades = results[1] as List<GradeRecord>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = 'โหลดคะแนนไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  GradeRecord? _gradeFor(String studentId) {
    for (final g in grades) {
      if (g.studentId == studentId) return g;
    }
    return null;
  }

  Future<void> _enterGrade(CourseStudent student, GradeRecord? existing) async {
    final scoreController = TextEditingController(
      text: existing?.score.toString() ?? '',
    );
    final maxScoreController = TextEditingController(
      text: existing?.maxScore.toString() ?? '100',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('ให้คะแนน ${student.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: scoreController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'คะแนนที่ได้'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: maxScoreController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'คะแนนเต็ม'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final score = num.tryParse(scoreController.text.trim());
    final maxScore = num.tryParse(maxScoreController.text.trim());
    if (score == null || maxScore == null || maxScore <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกคะแนนให้ถูกต้อง')),
      );
      return;
    }

    try {
      if (existing == null) {
        await GradeService.createGrade(
          studentId: student.studentId,
          courseId: widget.courseId,
          score: score,
          maxScore: maxScore,
        );
      } else {
        await GradeService.updateGrade(
          gradeId: existing.id,
          score: score,
          maxScore: maxScore,
        );
      }
      await load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('บันทึกคะแนนไม่สำเร็จ: $e')));
    }
  }

  Future<void> _confirm(GradeRecord grade) async {
    try {
      await GradeService.confirmGrade(grade.id);
      await load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ยืนยันคะแนนแล้ว'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ยืนยันคะแนนไม่สำเร็จ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ให้คะแนนนักเรียน'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: load),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: load, child: const Text('ลองใหม่')),
                  ],
                ),
              ),
            )
          : students.isEmpty
          ? const Center(
              child: Text(
                'ยังไม่มีนักเรียนในรายวิชานี้',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final grade = _gradeFor(student.studentId);

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(student.fullName),
                    subtitle: grade == null
                        ? const Text('ยังไม่มีคะแนน')
                        : Row(
                            children: [
                              Text('${grade.score} / ${grade.maxScore}'),
                              if (grade.coiFlag) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.flag,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                                const Text(
                                  ' CoI',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              const SizedBox(width: 8),
                              Text(
                                grade.isConfirmed ? '(ยืนยันแล้ว)' : '(ฉบับร่าง)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: grade.isConfirmed
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (grade == null || !grade.isConfirmed)
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _enterGrade(student, grade),
                          ),
                        if (grade != null && !grade.isConfirmed)
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            onPressed: () => _confirm(grade),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
